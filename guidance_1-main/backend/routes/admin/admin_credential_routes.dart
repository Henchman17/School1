import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'admin_route_helpers.dart';

class AdminCredentialRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminCredentialRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= CREDENTIAL CHANGE REQUESTS ENDPOINTS =================

  Future<Response> getCredentialChangeRequests(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final result = await _database.query('''
        SELECT
          ccr.id,
          ccr.user_id,
          ccr.request_type,
          ccr.current_value,
          ccr.new_value,
          ccr.reason,
          ccr.status,
          ccr.admin_notes,
          ccr.created_at,
          ccr.reviewed_at,
          ccr.reviewed_by,
          u.username,
          u.email,
          u.first_name,
          u.last_name,
          ru.username as reviewed_by_name
        FROM credential_change_requests ccr
        JOIN users u ON ccr.user_id = u.id
        LEFT JOIN users ru ON ccr.reviewed_by = ru.id
        ORDER BY ccr.created_at DESC
      ''');

      final requests = result.map((row) => {
        'id': row[0],
        'user_id': row[1],
        'request_type': row[2],
        'current_value': row[3],
        'new_value': row[4],
        'reason': row[5],
        'status': row[6],
        'admin_notes': row[7],
        'created_at': row[8]?.toIso8601String(),
        'reviewed_at': row[9]?.toIso8601String(),
        'reviewed_by': row[10],
        'username': row[11],
        'email': row[12],
        'first_name': row[13],
        'last_name': row[14],
        'reviewed_by_name': row[15],
      }).toList();

      return Response.ok(jsonEncode({'requests': requests}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch credential change requests: $e'}),
      );
    }
  }

  Future<Response> updateCredentialChangeRequest(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = _helpers.parseJsonBody(body);
      if (data == null) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }

      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['status'] != null) {
        updateFields.add('status = @status');
        params['status'] = data['status'];
      }
      if (data['admin_notes'] != null) {
        updateFields.add('admin_notes = @admin_notes');
        params['admin_notes'] = data['admin_notes'];
      }

      if (updateFields.isNotEmpty) {
        if (data['status'] == 'approved' || data['status'] == 'rejected') {
          updateFields.add('reviewed_at = NOW()');
          updateFields.add('reviewed_by = @reviewed_by');
          params['reviewed_by'] = adminId;
        }

        final updateQuery = 'UPDATE credential_change_requests SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Credential change request updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update credential change request: $e'}),
      );
    }
  }

  Future<Response> approveCredentialChangeRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get the request details
      final requestResult = await _database.query(
        'SELECT user_id, request_type, new_value FROM credential_change_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (requestResult.isEmpty) {
        return Response(404, body: jsonEncode({'error': 'Request not found'}));
      }

      final row = requestResult.first;
      final userId = row[0];
      final requestType = row[1];
      final newValue = row[2];

      // Update the user's credential based on request type
      String updateQuery;
      Map<String, dynamic> updateParams;

      switch (requestType) {
        case 'email':
          // Check if email is already used by another user
          final emailCheck = await _database.query(
            'SELECT id FROM users WHERE email = @new_value AND id != @user_id',
            {'new_value': newValue, 'user_id': userId},
          );
          if (emailCheck.isNotEmpty) {
            return Response(400, body: jsonEncode({'error': 'Email already in use by another user'}));
          }
          updateQuery = 'UPDATE users SET email = @new_value WHERE id = @user_id';
          updateParams = {'new_value': newValue, 'user_id': userId};
          break;
        case 'username':
          // Check if username is already used by another user
          final usernameCheck = await _database.query(
            'SELECT id FROM users WHERE username = @new_value AND id != @user_id',
            {'new_value': newValue, 'user_id': userId},
          );
          if (usernameCheck.isNotEmpty) {
            return Response(400, body: jsonEncode({'error': 'Username already in use by another user'}));
          }
          updateQuery = 'UPDATE users SET username = @new_value WHERE id = @user_id';
          updateParams = {'new_value': newValue, 'user_id': userId};
          break;
        case 'password':
          updateQuery = 'UPDATE users SET password = @new_value WHERE id = @user_id';
          updateParams = {'new_value': newValue, 'user_id': userId};
          break;
        case 'student_id':
          // Check if student_id is already used by another user
          final studentIdCheck = await _database.query(
            'SELECT id FROM users WHERE student_id = @new_value AND id != @user_id',
            {'new_value': newValue, 'user_id': userId},
          );
          if (studentIdCheck.isNotEmpty) {
            return Response(400, body: jsonEncode({'error': 'Student ID already in use by another user'}));
          }
          updateQuery = 'UPDATE users SET student_id = @new_value WHERE id = @user_id';
          updateParams = {'new_value': newValue, 'user_id': userId};
          break;
        default:
          return Response(400, body: jsonEncode({'error': 'Invalid request type'}));
      }

      await _database.execute(updateQuery, updateParams);

      // Update the request status
      await _database.execute(
        'UPDATE credential_change_requests SET status = @status, reviewed_at = NOW(), reviewed_by = @reviewed_by WHERE id = @id',
        {'status': 'approved', 'reviewed_by': adminId, 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'Request successful'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve credential change request: $e'}),
      );
    }
  }
}
