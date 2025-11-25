import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'admin_route_helpers.dart';

class AdminActivityRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminActivityRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= RECENT ACTIVITIES ENDPOINTS =================

  Future<Response> getRecentActivities(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get recent user registrations
      final userActivities = await _database.query('''
        SELECT
          'user_registration' as activity_type,
          CONCAT(u.first_name, ' ', u.last_name) as title,
          CONCAT('New ', u.role, ' registered: ', u.first_name, ' ', u.last_name) as subtitle,
          u.created_at as activity_time,
          'person_add' as icon,
          'green' as color,
          u.id as related_id
        FROM users u
        WHERE u.created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY u.created_at DESC
        LIMIT 10
      ''');

      // Get recent appointments
      final appointmentActivities = await _database.query('''
        SELECT
          'appointment' as activity_type,
          CONCAT('Appointment scheduled') as title,
          CONCAT(s.first_name, ' ', s.last_name, ' booked counseling') as subtitle,
          a.created_at as activity_time,
          'calendar_today' as icon,
          'blue' as color,
          a.id as related_id
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        WHERE a.created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY a.created_at DESC
        LIMIT 10
      ''');

      // Get recent discipline cases
      final disciplineActivities = await _database.query('''
        SELECT
          'discipline_case' as activity_type,
          CONCAT('Discipline case created') as title,
          CONCAT('Case for ', dc.student_name, ' - ', dc.severity) as subtitle,
          dc.created_at as activity_time,
          'gavel' as icon,
          'red' as color,
          dc.id as related_id
        FROM discipline_cases dc
        WHERE dc.created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY dc.created_at DESC
        LIMIT 10
      ''');

      // Get recent re-admission cases
      final reAdmissionActivities = await _database.query('''
        SELECT
          're_admission_case' as activity_type,
          CONCAT('Re-admission case created') as title,
          CONCAT('Case for ', rac.student_name) as subtitle,
          rac.created_at as activity_time,
          'assignment_return' as icon,
          'orange' as color,
          rac.id as related_id
        FROM re_admission_cases rac
        WHERE rac.created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY rac.created_at DESC
        LIMIT 10
      ''');

      // Get recent exit interviews
      final exitInterviewActivities = await _database.query('''
        SELECT
          'exit_interview' as activity_type,
          CONCAT('Exit interview completed') as title,
          CONCAT('Interview with ', ei.student_name) as subtitle,
          ei.completed_at as activity_time,
          'exit_to_app' as icon,
          'purple' as color,
          ei.id as related_id
        FROM exit_interviews ei
        WHERE ei.completed_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY ei.completed_at DESC
        LIMIT 10
      ''');

      // Get recent credential change requests
      final credentialActivities = await _database.query('''
        SELECT
          'credential_change' as activity_type,
          CONCAT('Credential change request') as title,
          CONCAT(u.first_name, ' ', u.last_name, ' requested ', ccr.request_type, ' change') as subtitle,
          ccr.created_at as activity_time,
          'security' as icon,
          'teal' as color,
          ccr.id as related_id
        FROM credential_change_requests ccr
        JOIN users u ON ccr.user_id = u.id
        WHERE ccr.created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY ccr.created_at DESC
        LIMIT 10
      ''');

      // Combine all activities and sort by time
      final allActivities = [];

      // Add user activities
      for (final row in userActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Add appointment activities
      for (final row in appointmentActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Add discipline activities
      for (final row in disciplineActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Add re-admission activities
      for (final row in reAdmissionActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Add exit interview activities
      for (final row in exitInterviewActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Add credential activities
      for (final row in credentialActivities) {
        allActivities.add({
          'activity_type': row[0],
          'title': row[1],
          'subtitle': row[2],
          'activity_time': row[3]?.toIso8601String(),
          'icon': row[4],
          'color': row[5],
          'related_id': row[6],
        });
      }

      // Sort by activity_time descending and take top 20
      allActivities.sort((a, b) {
        final aTime = a['activity_time'] != null ? DateTime.parse(a['activity_time']) : DateTime.now();
        final bTime = b['activity_time'] != null ? DateTime.parse(b['activity_time']) : DateTime.now();
        return bTime.compareTo(aTime);
      });

      final recentActivities = allActivities.take(20).toList();

      return Response.ok(jsonEncode({'activities': recentActivities}));
    } catch (e) {
      print('Error in getRecentActivities: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch recent activities: $e'}),
      );
    }
  }

  // ================= CASE SUMMARY ENDPOINTS =================

  Future<Response> getCaseSummary(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get re-admission cases summary directly
      final reAdmissionSummary = await _database.query('''
        SELECT
          're_admission' as case_type,
          COUNT(*) as total_cases,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_cases,
          COUNT(CASE WHEN status = 'approved' THEN 1 END) as approved_cases,
          COUNT(CASE WHEN status = 'rejected' THEN 1 END) as rejected_cases,
          COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
        FROM re_admission_cases
      ''');

      // Get discipline cases summary directly
      final disciplineSummary = await _database.query('''
        SELECT
          'discipline' as case_type,
          COUNT(*) as total_cases,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_cases,
          COUNT(CASE WHEN status = 'resolved' THEN 1 END) as approved_cases,
          COUNT(CASE WHEN status = 'closed' THEN 1 END) as rejected_cases,
          COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
        FROM discipline_cases
      ''');

      // Get exit interviews summary directly
      final exitInterviewSummary = await _database.query('''
        SELECT
          'exit_interview' as case_type,
          COUNT(*) as total_cases,
          COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending_cases,
          COUNT(CASE WHEN status = 'completed' THEN 1 END) as approved_cases,
          COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as rejected_cases,
          COUNT(CASE WHEN created_at >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as recent_cases
        FROM exit_interviews
      ''');

      final summary = [];

      if (reAdmissionSummary.isNotEmpty) {
        summary.add({
          'case_type': reAdmissionSummary.first[0],
          'total_cases': reAdmissionSummary.first[1],
          'pending_cases': reAdmissionSummary.first[2],
          'approved_cases': reAdmissionSummary.first[3],
          'rejected_cases': reAdmissionSummary.first[4],
          'recent_cases': reAdmissionSummary.first[5],
        });
      }

      if (disciplineSummary.isNotEmpty) {
        summary.add({
          'case_type': disciplineSummary.first[0],
          'total_cases': disciplineSummary.first[1],
          'pending_cases': disciplineSummary.first[2],
          'approved_cases': disciplineSummary.first[3],
          'rejected_cases': disciplineSummary.first[4],
          'recent_cases': disciplineSummary.first[5],
        });
      }

      if (exitInterviewSummary.isNotEmpty) {
        summary.add({
          'case_type': exitInterviewSummary.first[0],
          'total_cases': exitInterviewSummary.first[1],
          'pending_cases': exitInterviewSummary.first[2],
          'approved_cases': exitInterviewSummary.first[3],
          'rejected_cases': exitInterviewSummary.first[4],
          'recent_cases': exitInterviewSummary.first[5],
        });
      }

      return Response.ok(jsonEncode({'case_summary': summary}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch case summary: $e'}),
      );
    }
  }
}
