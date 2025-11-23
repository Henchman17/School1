import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../lib/document_generator.dart';

class HeadRoutes {
  final dynamic _database;

  HeadRoutes(this._database);

  // Helper method for role-based authorization
  Future<bool> _checkUserRole(int userId, String requiredRole) async {
    final result = await _database.query(
      'SELECT role FROM users WHERE id = @id',
      {'id': userId},
    );

    if (result.isEmpty) return false;
    final userRole = result.first[0];

    // Head has access to head functions
    if (userRole == 'head') return true;

    return userRole == requiredRole;
  }

  // ================= HEAD GOOD MORAL REQUEST ENDPOINTS =================

  // Head dashboard summary
  Future<Response> getDashboard(Request request) async {
    try {
      final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
      if (!await _checkUserRole(headId, 'head')) {
        return Response.forbidden(jsonEncode({'error': 'Head access required'}));
      }

      final totalRes = await _database.query('SELECT COUNT(*) FROM good_moral_requests');
      final pendingRes = await _database.query("SELECT COUNT(*) FROM good_moral_requests WHERE status = 'pending'");
      final approvedRes = await _database.query("SELECT COUNT(*) FROM good_moral_requests WHERE status = 'approved'");

      final total = (totalRes.isNotEmpty ? totalRes.first[0] : 0) ?? 0;
      final pending = (pendingRes.isNotEmpty ? pendingRes.first[0] : 0) ?? 0;
      final approved = (approvedRes.isNotEmpty ? approvedRes.first[0] : 0) ?? 0;

      return Response.ok(jsonEncode({
        'total_requests': total,
        'pending_requests': pending,
        'approved_requests': approved,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch head dashboard: $e'}),
      );
    }
  }

  Future<Response> getGoodMoralRequests(Request request) async {
    try {
      final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
      if (!await _checkUserRole(headId, 'head')) {
        return Response.forbidden(jsonEncode({'error': 'Head access required'}));
      }

      final result = await _database.query('''
        SELECT
          gmr.id,
          gmr.student_id,
          gmr.student_name,
          gmr.student_number,
          gmr.course,
          gmr.year_level,
          gmr.purpose,
          gmr.ocr_data,
          gmr.status,
          gmr.created_at,
          gmr.updated_at,
          u.first_name,
          u.last_name,
          u.email,
          u.student_id as user_student_id
        FROM good_moral_requests gmr
        JOIN users u ON gmr.student_id = u.id
        ORDER BY gmr.created_at DESC
      ''');

      final requests = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'student_number': row[3],
        'course': row[4],
        'year_level': row[5],
        'purpose': row[6],
        'ocr_data': row[7],
        'status': row[8],
        'created_at': row[9]?.toIso8601String(),
        'updated_at': row[10]?.toIso8601String(),
        'first_name': row[11],
        'last_name': row[12],
        'email': row[13],
        'user_student_id': row[14],
      }).toList();

      return Response.ok(jsonEncode({'requests': requests}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch good moral requests: $e'}),
      );
    }
  }

  Future<Response> approveGoodMoralRequest(Request request, String id) async {
    try {
      final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
      if (!await _checkUserRole(headId, 'head')) {
        return Response.forbidden(jsonEncode({'error': 'Head access required'}));
      }

      // Check if request exists and get request details
      final existingRequest = await _database.query(
        'SELECT id, student_name, course, purpose, address, school_year, ocr_data FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final requestData = existingRequest.first;
      final studentName = requestData[1] as String;
      final course = requestData[2] as String;
      final purpose = requestData[3] as String;
      final address = requestData[4] as String;
      final schoolYear = requestData[5] as String;
      Map<String, dynamic> ocrData = {};
      if (requestData[6] != null) {
        try {
          ocrData = (jsonDecode(requestData[6] as String) as Map).cast<String, dynamic>();
        } catch (e) {
          // Use empty map if invalid JSON
        }
      }

      // Update status to approved with review info
      await _database.execute(
        'UPDATE good_moral_requests SET status = @status, reviewed_at = NOW(), reviewed_by = @reviewed_by, updated_at = NOW() WHERE id = @id',
        {'status': 'approved', 'reviewed_by': headId, 'id': int.parse(id)},
      );

      // Generate PDF certificate
      final certificatePath = await BackendDocumentGenerator.generateGoodMoralCertificate(
        int.parse(id),
        ocrData,
        studentName,
        '', // student_number no longer exists
        course,
        schoolYear,
        purpose,
      );

      if (certificatePath == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Request approved but failed to generate certificate'}),
        );
      }

      // Update document path
      await _database.execute(
        'UPDATE good_moral_requests SET document_path = @document_path WHERE id = @id',
        {'document_path': certificatePath, 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({
        'message': 'Good moral request approved successfully',
        'certificate_path': certificatePath
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve good moral request: $e'}),
      );
    }
  }

  Future<Response> rejectGoodMoralRequest(Request request, String id) async {
    try {
      final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
      if (!await _checkUserRole(headId, 'head')) {
        return Response.forbidden(jsonEncode({'error': 'Head access required'}));
      }

      // Check if request exists
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      // Update status to rejected with review info
      await _database.execute(
        'UPDATE good_moral_requests SET status = @status, reviewed_at = NOW(), reviewed_by = @reviewed_by, updated_at = NOW() WHERE id = @id',
        {'status': 'rejected', 'reviewed_by': headId, 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'Good moral request rejected successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject good moral request: $e'}),
      );
    }
  }
}
