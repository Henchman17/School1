import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../connection.dart';

class StudentRoutes {
  final DatabaseConnection _database;
  late final Router router;

  StudentRoutes(this._database) {
    _setupRoutes();
  }

  void _setupRoutes() {
    router = Router();

    // Example student endpoint - adjust as needed
    router.get('/forms/<studentId>', _getStudentForms);

    // Good Moral Request endpoint
    router.post('/good-moral-requests', _createGoodMoralRequest);
  }

  Future<Response> _getStudentForms(Request request, String studentId) async {
    try {
      // Get Exit Interview forms
      final exitInterviewResult = await _database.query('''
        SELECT id, 'exit_interview' as form_type, student_id as user_id, 'completed' as status, created_at, updated_at
        FROM exit_interviews
        WHERE student_id = @studentId
      ''', {'studentId': studentId});

      // You can add more form queries here as needed

      final forms = [
        ...exitInterviewResult.map((row) => {
          'id': row[0],
          'form_type': row[1],
          'user_id': row[2],
          'status': row[3],
          'created_at': row[4] is DateTime ? (row[4] as DateTime).toIso8601String() : row[4]?.toString(),
          'updated_at': row[5] is DateTime ? (row[5] as DateTime).toIso8601String() : row[5]?.toString(),
        }),
      ];

      return Response.ok(jsonEncode({'forms': forms}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch student forms: $e'}),
      );
    }
  }

  Future<Response> _createGoodMoralRequest(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Validate required fields
      if (data['student_id'] == null || data['ocr_data'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: student_id, ocr_data'}),
        );
      }

      // Check if user exists and is a student
      final userResult = await _database.query(
        'SELECT role, first_name, last_name FROM users WHERE id = @user_id',
        {'user_id': data['student_id']},
      );

      if (userResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Only students can submit good moral requests'}));
      }

      final userRow = userResult.first;
      final studentName = '${userRow[1]} ${userRow[2]}';

      // Check if student already has a pending request
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE student_id = @student_id AND approval_status = @approval_status',
        {
          'student_id': data['student_id'],
          'approval_status': 'pending',
        },
      );

      if (existingRequest.isNotEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'You already have a pending good moral request'}),
        );
      }

      // Insert the request
      final result = await _database.execute('''
        INSERT INTO good_moral_requests (
          student_id, student_name, course, purpose, address, school_year, ocr_data, approval_status
        ) VALUES (
          @student_id, @student_name, @course, @purpose, @address, @school_year, @ocr_data, @approval_status
        )
        RETURNING id
      ''', {
        'student_id': data['student_id'],
        'student_name': studentName,
        'course': data['course'] ?? '',
        'purpose': data['purpose'] ?? '',
        'address': data['address'] ?? '',
        'school_year': data['school_year'] ?? '',
        'ocr_data': jsonEncode(data['ocr_data']),
        'approval_status': 'pending'
      });

      return Response.ok(jsonEncode({
        'message': 'Good moral request submitted successfully',
        'request_id': result,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create good moral request: $e'}),
      );
    }
  }

  Future<Response> _getGoodMoralApprovalStatus(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];

      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Check if user exists and is a student
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Only students can view their good moral request status'}));
      }

      // Get the most recent good moral request for this student
      final result = await _database.query('''
        SELECT
          id,
          student_id,
          student_name,
          course,
          purpose,
          address,
          school_year,
          approval_status,
          current_approval_step,
          approvals_received,
          created_at,
          updated_at
        FROM good_moral_requests
        WHERE student_id = @student_id
        ORDER BY created_at DESC
        LIMIT 1
      ''', {'student_id': int.parse(userId)});

      if (result.isEmpty) {
        return Response.ok(jsonEncode({'request': null}));
      }

      final row = result.first;
      final requestData = {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'course': row[3],
        'purpose': row[4],
        'address': row[5],
        'school_year': row[6],
        'approval_status': row[7],
        'current_approval_step': row[8],
        'approvals_received': row[9],
        'created_at': row[10] is DateTime ? (row[10] as DateTime).toIso8601String() : row[10]?.toString(),
        'updated_at': row[11] is DateTime ? (row[11] as DateTime).toIso8601String() : row[11]?.toString(),
      };

      return Response.ok(jsonEncode({'request': requestData}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch good moral request status: $e'}),
      );
    }
  }
}
