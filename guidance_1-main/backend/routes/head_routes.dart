import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../connection.dart';

class HeadRoutes {
  final dynamic _database;
  late final Router _router;

  HeadRoutes(this._database) {
    _router = Router();

    // Mount routes
    _router.get('/dashboard', getDashboard);
    _router.get('/good-moral-requests', getGoodMoralRequests);
    _router.put('/good-moral-requests/<id>/approve', approveGoodMoralRequest);
    _router.put('/good-moral-requests/<id>/reject', rejectGoodMoralRequest);
  }

  Router get router => _router;

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

    // Get the head's approval sequence
    final headSequenceResult = await _database.query('''
      SELECT hr.approval_sequence, hr.role_name, hr.role_description
      FROM head_assignments ha
      JOIN head_roles hr ON ha.head_role_id = hr.id
      WHERE ha.user_id = @head_id AND ha.is_active = TRUE AND hr.is_active = TRUE
    ''', {'head_id': headId});

    if (headSequenceResult.isEmpty) {
      return Response.forbidden(jsonEncode({'error': 'You are not assigned to any head role'}));
    }

    final headSequence = headSequenceResult.first[0] as int;
    final roleName = headSequenceResult.first[1] as String;
    final roleDescription = headSequenceResult.first[2] as String;

    // Get total requests
    final totalRes = await _database.query('SELECT COUNT(*) FROM good_moral_requests');
    final total = (totalRes.isNotEmpty ? totalRes.first[0] : 0) ?? 0;

    // Get pending requests for this head's approval step
    final pendingForHeadRes = await _database.query(
      "SELECT COUNT(*) FROM good_moral_requests WHERE approval_status = 'pending' AND current_approval_step = @step",
      {'step': headSequence}
    );
    final pendingForHead = (pendingForHeadRes.isNotEmpty ? pendingForHeadRes.first[0] : 0) ?? 0;

    // Get all pending requests
    final allPendingRes = await _database.query("SELECT COUNT(*) FROM good_moral_requests WHERE approval_status = 'pending'");
    final allPending = (allPendingRes.isNotEmpty ? allPendingRes.first[0] : 0) ?? 0;

    // Get approved requests
    final approvedRes = await _database.query("SELECT COUNT(*) FROM good_moral_requests WHERE approval_status = 'approved'");
    final approved = (approvedRes.isNotEmpty ? approvedRes.first[0] : 0) ?? 0;

    // Get rejected requests
    final rejectedRes = await _database.query("SELECT COUNT(*) FROM good_moral_requests WHERE approval_status = 'rejected'");
    final rejected = (rejectedRes.isNotEmpty ? rejectedRes.first[0] : 0) ?? 0;

    return Response.ok(jsonEncode({
      'total_requests': total,
      'pending_for_head': pendingForHead,
      'all_pending_requests': allPending,
      'approved_requests': approved,
      'rejected_requests': rejected,
      'head_role': {
        'sequence': headSequence,
        'name': roleName,
        'description': roleDescription,
      },
    }));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to fetch head dashboard: $e'}),
    );
  }
}

// Get all good moral requests (for head view) - only show requests they can approve
Future<Response> getGoodMoralRequests(Request request) async {
  try {
    final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
    if (!await _checkUserRole(headId, 'head')) {
      return Response.forbidden(jsonEncode({'error': 'Head access required'}));
    }

    // Get the head's approval sequence
    final headSequenceResult = await _database.query('''
      SELECT hr.approval_sequence
      FROM head_assignments ha
      JOIN head_roles hr ON ha.head_role_id = hr.id
      WHERE ha.user_id = @head_id AND ha.is_active = TRUE AND hr.is_active = TRUE
    ''', {'head_id': headId});

    if (headSequenceResult.isEmpty) {
      return Response.forbidden(jsonEncode({'error': 'You are not assigned to any head role'}));
    }

    final headSequence = headSequenceResult.first[0] as int;

    final result = await _database.query('''
      SELECT
        gmr.id,
        gmr.student_id,
        gmr.student_name,
        gmr.course,
        gmr.purpose,
        gmr.approval_status,
        gmr.school_year,
        gmr.current_approval_step,
        gmr.approvals_received,
        gmr.created_at,
        gmr.updated_at,
        u.first_name,
        u.last_name,
        u.email,
        u.student_id as user_student_id,
        hr.role_name,
        hr.role_description
      FROM good_moral_requests gmr
      JOIN users u ON gmr.student_id = u.id
      LEFT JOIN head_assignments ha ON ha.user_id = @head_id AND ha.is_active = TRUE
      LEFT JOIN head_roles hr ON ha.head_role_id = hr.id AND hr.is_active = TRUE
      WHERE gmr.approval_status = 'pending'
        AND gmr.current_approval_step = @head_sequence
      ORDER BY gmr.created_at DESC
    ''', {
      'head_id': headId,
      'head_sequence': headSequence
    });

    final requests = result.map((row) => {
      'id': row[0],
      'student_id': row[1],
      'student_name': row[2],
      'course': row[3],
      'purpose': row[4],
      'approval_status': row[5],
      'school_year': row[6],
      'current_approval_step': row[7],
      'approvals_received': row[8],
      'created_at': row[9]?.toIso8601String(),
      'updated_at': row[10]?.toIso8601String(),
      'first_name': row[11],
      'last_name': row[12],
      'email': row[13],
      'user_student_id': row[14],
      'head_role_name': row[15],
      'head_role_description': row[16],
    }).toList();

    return Response.ok(jsonEncode({'requests': requests}));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to fetch good moral requests: $e'}),
    );
  }
}

// Approve good moral request (Head approval)
Future<Response> approveGoodMoralRequest(Request request, String id) async {
  try {
    final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
    if (!await _checkUserRole(headId, 'head')) {
      return Response.forbidden(jsonEncode({'error': 'Head access required'}));
    }

    // Get approval notes from request body
    final body = await request.readAsString();
    final requestBody = jsonDecode(body);
    final approvalNotes = requestBody['notes'] as String? ?? '';

    // Check if this head is assigned to the current approval step
    final stepCheck = await _database.query('''
      SELECT gmr.current_approval_step, ha.head_role_id, hr.approval_sequence
      FROM good_moral_requests gmr
      JOIN head_assignments ha ON ha.user_id = @head_id AND ha.is_active = TRUE
      JOIN head_roles hr ON ha.head_role_id = hr.id AND hr.is_active = TRUE
      WHERE gmr.id = @request_id AND gmr.approval_status = 'pending'
    ''', {
      'head_id': headId,
      'request_id': int.parse(id)
    });

    if (stepCheck.isEmpty) {
      return Response.forbidden(jsonEncode({
        'error': 'You are not authorized to approve this request at this step, or the request is not pending'
      }));
    }

    final currentStep = stepCheck.first[0] as int;
    final headSequence = stepCheck.first[2] as int;

    if (headSequence != currentStep) {
      return Response.forbidden(jsonEncode({
        'error': 'This request must be approved by the head for step $currentStep first'
      }));
    }

    // Check if this is the final approval (step 4)
    final isFinalApproval = currentStep >= 4;

    await _database.execute(
      '''
      UPDATE good_moral_requests
      SET
        current_approval_step = CASE WHEN @is_final THEN current_approval_step ELSE current_approval_step + 1 END,
        approvals_received = approvals_received + 1,
        approval_status = CASE WHEN @is_final THEN 'approved' ELSE 'pending' END,
        updated_at = NOW(),
        updated_by = @head_id
      WHERE id = @request_id AND approval_status = 'pending'
      ''',
      {
        'request_id': int.parse(id),
        'head_id': headId,
        'is_final': isFinalApproval,
      }
    );

    return Response.ok(jsonEncode({
      'message': isFinalApproval
          ? 'Good moral request fully approved successfully'
          : 'Good moral request approved for step $currentStep, now pending step ${currentStep + 1} approval',
      'request_id': int.parse(id),
      'current_step': currentStep,
      'is_final_approval': isFinalApproval
    }));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to approve good moral request: $e'}),
    );
  }
}

// Reject good moral request (Head rejection)
Future<Response> rejectGoodMoralRequest(Request request, String id) async {
  try {
    final headId = int.parse(request.url.queryParameters['head_id'] ?? '0');
    if (!await _checkUserRole(headId, 'head')) {
      return Response.forbidden(jsonEncode({'error': 'Head access required'}));
    }

    // Get rejection notes from request body
    final body = await request.readAsString();
    final requestBody = jsonDecode(body);
    final rejectionNotes = requestBody['rejection_reason'] as String? ?? '';

    if (rejectionNotes.trim().isEmpty) {
      return Response(400, body: jsonEncode({'error': 'Rejection reason is required'}));
    }

    // Process head rejection using the database function
    final result = await _database.query(
      'SELECT process_head_approval(@request_id, @head_id, false, @notes)',
      {
        'request_id': int.parse(id),
        'head_id': headId,
        'notes': rejectionNotes,
      }
    );

    if (result.isEmpty || result.first[0] == null) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to process rejection'}),
      );
    }

    final rejectionResult = result.first[0] as String;

    if (rejectionResult.startsWith('ERROR:')) {
      return Response.badRequest(
        body: jsonEncode({'error': rejectionResult.substring(6).trim()}),
      );
    }

    return Response.ok(jsonEncode({
      'message': 'Good moral request rejected successfully',
      'request_id': int.parse(id)
    }));
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Failed to reject good moral request: $e'}),
    );
  }
}
}
