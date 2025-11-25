import 'dart:convert';
import 'dart:io';
import 'package:docx_template/docx_template.dart';
import 'package:shelf/shelf.dart';
import '../../docx_template.dart';
import 'admin_route_helpers.dart';

class AdminGoodMoralRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminGoodMoralRoutes(this._database) : _helpers = AdminRouteHelpers(_database);



  // ================= GOOD MORAL REQUEST ENDPOINTS =================

  Future<Response> getGoodMoralRequests(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      print('Request received: ${request.method} ${request.requestedUri.path}');

      final result = await _database.query('''
        SELECT
          gmr.id,
          gmr.student_id,
          gmr.student_name,
          gmr.course,
          gmr.school_year,
          gmr.purpose,
          gmr.address,
          gmr.edst,
          gmr.gor,
          gmr.admin_notes,
          gmr.ocr_data,
          gmr.approval_status,
          gmr.current_approval_step,
          gmr.total_approvals_needed,
          gmr.approvals_received,
          gmr.certificate_path,
          gmr.certificate_generated_at,
          gmr.admin_approved,
          gmr.admin_approved_at,
          gmr.admin_approved_by,
          gmr.rejection_reason,
          gmr.rejected_at,
          gmr.rejected_by,
          gmr.created_at,
          gmr.updated_at,
          gmr.created_by,
          gmr.updated_by,
          u.first_name,
          u.last_name,
          u.email,
          u.student_id as user_student_id,
          admin_user.username as admin_approved_by_name,
          rejected_user.username as rejected_by_name
        FROM good_moral_requests gmr
        JOIN users u ON gmr.student_id = u.id
        LEFT JOIN users admin_user ON gmr.admin_approved_by = admin_user.id
        LEFT JOIN users rejected_user ON gmr.rejected_by = rejected_user.id
        ORDER BY gmr.created_at DESC
      ''');

      final requests = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'course': row[3],
        'school_year': row[4],
        'purpose': row[5],
        'address': row[6],
        'edst': row[7],
        'gor': row[8],
        'admin_notes': row[9],
        'ocr_data': row[10],
        'approval_status': row[11],
        'current_approval_step': row[12],
        'total_approvals_needed': row[13],
        'approvals_received': row[14],
        'certificate_path': row[15],
        'certificate_generated_at': row[16] is DateTime ? (row[16] as DateTime).toIso8601String() : row[16]?.toString(),
        'admin_approved': row[17],
        'admin_approved_at': row[18] is DateTime ? (row[18] as DateTime).toIso8601String() : row[18]?.toString(),
        'admin_approved_by': row[19],
        'rejection_reason': row[20],
        'rejected_at': row[21] is DateTime ? (row[21] as DateTime).toIso8601String() : row[21]?.toString(),
        'rejected_by': row[22],
        'created_at': row[23] is DateTime ? (row[23] as DateTime).toIso8601String() : row[23]?.toString(),
        'updated_at': row[24] is DateTime ? (row[24] as DateTime).toIso8601String() : row[24]?.toString(),
        'created_by': row[25],
        'updated_by': row[26],
        'first_name': row[27],
        'last_name': row[28],
        'email': row[29],
        'user_student_id': row[30],
        'admin_approved_by_name': row[31],
        'rejected_by_name': row[32],
      }).toList();

      return Response.ok(jsonEncode({'requests': requests}));
    } catch (e) {
      print('Error in getGoodMoralRequests: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch good moral requests: $e'}),
      );
    }
  }

  Future<Response> approveGoodMoralRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if request exists and get request details
      final existingRequest = await _database.query(
        '''SELECT id, student_name, course, school_year, purpose, ocr_data, address,
           approval_status, current_approval_step, approvals_received, gor, edst
           FROM good_moral_requests WHERE id = @id''',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final requestData = existingRequest.first;
      final currentStatus = requestData[7] as String?;

      // Don't allow approval if already approved or rejected
      if (currentStatus == 'approved') {
        return Response(400, body: jsonEncode({'error': 'Request is already approved'}));
      }
      if (currentStatus == 'rejected' || currentStatus == 'cancelled') {
        return Response(400, body: jsonEncode({'error': 'Cannot approve a rejected or cancelled request'}));
      }

      final studentName = requestData[1] as String;
      final course = requestData[2] as String?;
      final schoolYear = requestData[3] as String?;
      final purpose = requestData[4] as String?;
      final address = requestData[6] as String?;
      final gor = requestData[10] as String?;
      final edst = requestData[11] as String?;
      final currentStep = requestData[8] as int? ?? 1;
      final approvalsReceived = requestData[9] as int? ?? 0;

      Map<String, dynamic> ocrData = {};
      if (requestData[5] != null) {
        try {
          ocrData = (jsonDecode(requestData[5] as String) as Map).cast<String, dynamic>();
        } catch (e) {
          // Use empty map if invalid JSON
        }
      }

    // Prepare data for certificate generation
    final now = DateTime.now();
    final data = {
      "name": studentName,
      "course": course,
      "school_year": schoolYear,
      "day": now.day.toString(),
      "month_year": "${_getMonthName(now.month)} ${now.year}",
      "purpose": purpose,
      "gor": gor,
      "date_of_payment": "${now.month}/${now.day}/${now.year}",
    };

    final docxPath = await generateGoodMoralDocx(data);
    final pdfPath = await convertDocxToPdf(docxPath);

      // Update to approved status with all necessary fields
      await _database.execute(
        '''UPDATE good_moral_requests
           SET approval_status = @status,
               admin_approved = true,
               admin_approved_at = NOW(),
               admin_approved_by = @admin_id,
               certificate_path = @certificate_path,
               certificate_generated_at = NOW(),
               approvals_received = @approvals_received,
               current_approval_step = 4,
               updated_at = NOW(),
               updated_by = @admin_id
           WHERE id = @id''',
        {
          'status': 'approved',
          'id': int.parse(id),
          'admin_id': adminId,
          'certificate_path': pdfPath,
          'approvals_received': 4 // All approvals received
        },
      );

      return Response.ok(jsonEncode({
        'message': 'Good moral request approved successfully',
        'certificate_path': pdfPath,
      }));
    } catch (e) {
      print('Error in approveGoodMoralRequest: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve good moral request: $e'}),
      );
    }
  }

  // Helper function to get month name
  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Future<Response> rejectGoodMoralRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Parse request body for rejection reason
      final body = await request.readAsString();
      final data = body.isNotEmpty ? jsonDecode(body) : <String, dynamic>{};
      final rejectionReason = data['rejection_reason'] as String?;

      if (rejectionReason == null || rejectionReason.trim().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Rejection reason is required'}));
      }

      // Check if request exists
      final existingRequest = await _database.query(
        'SELECT id, approval_status FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final currentStatus = existingRequest.first[1] as String?;

      // Don't allow rejection if already approved or rejected
      if (currentStatus == 'approved') {
        return Response(400, body: jsonEncode({'error': 'Cannot reject an approved request'}));
      }
      if (currentStatus == 'rejected' || currentStatus == 'cancelled') {
        return Response(400, body: jsonEncode({'error': 'Request is already rejected or cancelled'}));
      }

      // Update status to rejected with all necessary fields
      await _database.execute(
        '''UPDATE good_moral_requests
           SET approval_status = @status,
               rejection_reason = @rejection_reason,
               rejected_at = NOW(),
               rejected_by = @admin_id,
               updated_at = NOW(),
               updated_by = @admin_id
           WHERE id = @id''',
        {
          'status': 'rejected',
          'id': int.parse(id),
          'admin_id': adminId,
          'rejection_reason': rejectionReason,
        },
      );

      return Response.ok(jsonEncode({'message': 'Good moral request rejected successfully'}));
    } catch (e) {
      print('Error in rejectGoodMoralRequest: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject good moral request: $e'}),
      );
    }
  }

  Future<Response> updateGoodMoralRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Parse request body
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Check if request exists
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      // Build update query
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['student_name'] != null) {
        updateFields.add('student_name = @student_name');
        params['student_name'] = data['student_name'];
      }
      if (data['student_number'] != null) {
        updateFields.add('student_number = @student_number');
        params['student_number'] = data['student_number'];
      }
      if (data['course'] != null) {
        updateFields.add('course = @course');
        params['course'] = data['course'];
      }
      if (data['school_year'] != null) {
        updateFields.add('school_year = @school_year');
        params['school_year'] = data['school_year'];
      }
      if (data['purpose'] != null) {
        updateFields.add('purpose = @purpose');
        params['purpose'] = data['purpose'];
      }
      if (data['address'] != null) {
        updateFields.add('address = @address');
        params['address'] = data['address'];
      }
      if (data['edst'] != null) {
        updateFields.add('edst = @edst');
        params['edst'] = data['edst'];
      }
      if (data['gor'] != null) {
        updateFields.add('gor = @gor');
        params['gor'] = data['gor'];
      }
      if (data['admin_notes'] != null) {
        updateFields.add('admin_notes = @admin_notes');
        params['admin_notes'] = data['admin_notes'];
      }
      if (data['current_approval_step'] != null) {
        final step = int.tryParse(data['current_approval_step'].toString());
        if (step != null && step >= 1 && step <= 4) {
          updateFields.add('current_approval_step = @current_approval_step');
          params['current_approval_step'] = step;
        }
      }
      if (data['approvals_received'] != null) {
        updateFields.add('approvals_received = @approvals_received');
        params['approvals_received'] = int.tryParse(data['approvals_received'].toString()) ?? 0;
      }

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');
        updateFields.add('updated_by = @updated_by');
        params['updated_by'] = adminId;

        final updateQuery = 'UPDATE good_moral_requests SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Good moral request updated successfully'}));
    } catch (e) {
      print('Error in updateGoodMoralRequest: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update good moral request: $e'}),
      );
    }
  }

  // Helper method to cancel a good moral request
  Future<Response> cancelGoodMoralRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if request exists
      final existingRequest = await _database.query(
        'SELECT id, approval_status FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final currentStatus = existingRequest.first[1] as String?;

      if (currentStatus == 'approved') {
        return Response(400, body: jsonEncode({'error': 'Cannot cancel an approved request'}));
      }

      // Update status to cancelled
      await _database.execute(
        '''UPDATE good_moral_requests
           SET approval_status = @status,
               updated_at = NOW(),
               updated_by = @admin_id
           WHERE id = @id''',
        {
          'status': 'cancelled',
          'id': int.parse(id),
          'admin_id': adminId,
        },
      );

      return Response.ok(jsonEncode({'message': 'Good moral request cancelled successfully'}));
    } catch (e) {
      print('Error in cancelGoodMoralRequest: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to cancel good moral request: $e'}),
      );
    }
  }

  Future<Response> downloadGoodMoralDocument(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if request exists and get request details
      final existingRequest = await _database.query(
        '''SELECT id, student_name, course, school_year, purpose, ocr_data, address,
           approval_status, current_approval_step, approvals_received, gor, edst,
           certificate_path, certificate_generated_at
           FROM good_moral_requests WHERE id = @id''',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final requestData = existingRequest.first;
      final approvalStatus = requestData[7] as String?;

      if (approvalStatus != 'approved') {
        return Response(400, body: jsonEncode({'error': 'Document can only be generated for approved requests'}));
      }

      final certificatePath = requestData[12] as String?;

      // If certificate already exists, serve it
      if (certificatePath != null && File(certificatePath).existsSync()) {
        final file = File(certificatePath);
        final bytes = await file.readAsBytes();
        return Response.ok(bytes, headers: {
          'Content-Type': 'application/pdf',
          'Content-Disposition': 'attachment; filename="good_moral_certificate_${id}.pdf"',
        });
      }

      // Generate new document if not exists
      final studentName = requestData[1] as String;
      final course = requestData[2] as String?;
      final schoolYear = requestData[3] as String?;
      final purpose = requestData[4] as String?;
      final address = requestData[6] as String?;
      final gor = requestData[10] as String?;
      final edst = requestData[11] as String?;

      Map<String, dynamic> ocrData = {};
      if (requestData[5] != null) {
        try {
          ocrData = (jsonDecode(requestData[5] as String) as Map).cast<String, dynamic>();
        } catch (e) {
          // Use empty map if invalid JSON
        }
      }

      // Prepare data for certificate generation
      final now = DateTime.now();
      final data = {
        "name": studentName,
        "course": course,
        "school_year": schoolYear,
        "day": now.day.toString(),
        "month_year": "${_getMonthName(now.month)} ${now.year}",
        "purpose": purpose,
        "gor": gor,
        "date_of_payment": "${now.month}/${now.day}/${now.year}",
      };

      final docxPath = await generateGoodMoralDocx(data);
      final pdfPath = await convertDocxToPdf(docxPath);

      // Update database with new certificate path
      await _database.execute(
        '''UPDATE good_moral_requests
           SET certificate_path = @certificate_path,
               certificate_generated_at = NOW(),
               updated_at = NOW(),
               updated_by = @admin_id
           WHERE id = @id''',
        {
          'certificate_path': pdfPath,
          'id': int.parse(id),
          'admin_id': adminId,
        },
      );

      // Serve the generated PDF
      final file = File(pdfPath);
      final bytes = await file.readAsBytes();
      return Response.ok(bytes, headers: {
        'Content-Type': 'application/pdf',
        'Content-Disposition': 'attachment; filename="good_moral_certificate_${id}.pdf"',
      });
    } catch (e) {
      print('Error in downloadGoodMoralDocument: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to generate/download good moral document: $e'}),
      );
    }
  }
}
