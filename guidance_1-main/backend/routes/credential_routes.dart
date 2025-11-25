import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../connection.dart';

class CredentialRoutes {
  final DatabaseConnection _database;

  CredentialRoutes(this._database);

  // ================= CREDENTIAL CHANGE REQUEST ENDPOINTS =================

  Future<Response> createCredentialChangeRequest(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Validate required fields
      if (data['user_id'] == null || data['request_type'] == null || data['new_value'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: user_id, request_type, new_value'}),
        );
      }

      // Check if user exists
      final userResult = await _database.query(
        'SELECT id, role FROM users WHERE id = @user_id',
        {'user_id': data['user_id']},
      );

      if (userResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User not found'}),
        );
      }

      // Check if there's already a pending request for the same credential type
      final existingRequest = await _database.query(
        'SELECT id FROM credential_change_requests WHERE user_id = @user_id AND request_type = @request_type AND status = @status',
        {
          'user_id': data['user_id'],
          'request_type': data['request_type'],
          'status': 'pending',
        },
      );

      if (existingRequest.isNotEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'You already have a pending request for this credential type'}),
        );
      }

      // Insert the credential change request
      final result = await _database.execute('''
        INSERT INTO credential_change_requests (
          user_id, request_type, current_value, new_value, reason, status
        ) VALUES (
          @user_id, @request_type, @current_value, @new_value, @reason, @status
        )
        RETURNING id
      ''', {
        'user_id': data['user_id'],
        'request_type': data['request_type'],
        'current_value': data['current_value'] ?? '',
        'new_value': data['new_value'],
        'reason': data['reason'] ?? '',
        'status': 'pending'
      });

      return Response.ok(jsonEncode({
        'message': 'Credential change request submitted successfully',
        'request_id': result,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create credential change request: $e'}),
      );
    }
  }

  Future<Response> getUserCredentialChangeRequests(Request request, String userId) async {
    try {
      // Check if user exists
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
        );
      }

      // Fetch user's credential change requests
      final result = await _database.query('''
        SELECT
          id,
          user_id,
          request_type,
          current_value,
          new_value,
          reason,
          status,
          created_at,
          updated_at,
          reviewed_at,
          reviewed_by,
          admin_notes
        FROM credential_change_requests
        WHERE user_id = @user_id
        ORDER BY created_at DESC
      ''', {'user_id': int.parse(userId)});

      final requests = result.map((row) => {
        'id': row[0],
        'user_id': row[1],
        'request_type': row[2],
        'current_value': row[3],
        'new_value': row[4],
        'reason': row[5],
        'status': row[6],
        'created_at': row[7] is DateTime ? (row[7] as DateTime).toIso8601String() : row[7]?.toString(),
        'updated_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'reviewed_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'reviewed_by': row[10],
        'admin_notes': row[11]
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': requests.length,
        'requests': requests,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch credential change requests: $e'}),
      );
    }
  }
}
