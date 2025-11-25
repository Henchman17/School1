import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'admin_route_helpers.dart';

class AdminAppointmentRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminAppointmentRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= APPOINTMENT MANAGEMENT ENDPOINTS =================

  Future<Response> getAdminAppointments(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Pagination parameters
      final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      final offset = (page - 1) * limit;

      // Get total count
      final totalResult = await _database.query('SELECT COUNT(*) FROM appointments');
      final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

      // Get paginated results
      final result = await _database.query('''
        SELECT
          a.id,
          a.student_id,
          a.counselor_id,
          a.appointment_date,
          a.purpose,
          a.course,
          a.apt_status,
          a.notes,
          a.created_at,
          CONCAT(s.first_name, ' ', s.last_name) as student_name,
          u.username as counselor_name,
          s.student_id as student_number,
          s.first_name as student_first_name,
          s.last_name as student_last_name,
          s.status,
          s.program,
          u.email as counselor_email
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        JOIN users u ON a.counselor_id = u.id
        ORDER BY a.created_at ASC
        LIMIT @limit OFFSET @offset
      ''', {'limit': limit, 'offset': offset});

      final appointments = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'appointment_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3]?.toString(),
        'purpose': row[4]?.toString() ?? '',
        'course': row[5]?.toString() ?? '',
        'apt_status': row[6]?.toString() ?? 'scheduled',
        'notes': row[7]?.toString() ?? '',
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'student_name': row[9]?.toString() ?? 'Unknown Student',
        'counselor_name': row[10]?.toString() ?? 'Unknown Counselor',
        'student_number': row[11]?.toString(),
        'student_first_name': row[12]?.toString(),
        'student_last_name': row[13]?.toString(),
        'status': row[14]?.toString(),
        'program': row[15]?.toString(),
        'counselor_email': row[16]?.toString(),
      }).map((appointment) {
        // Calculate overdue status
        if (appointment['apt_status'] == 'scheduled') {
          final appointmentDate = DateTime.tryParse(appointment['appointment_date']?.toString() ?? '');
          if (appointmentDate != null && appointmentDate.isBefore(DateTime.now())) {
            appointment['apt_status'] = 'overdue';
          }
        }
        return appointment;
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': appointments.length,
        'appointments': appointments,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': (total / limit).ceil(),
        }
      }));
    } catch (e, stackTrace) {
      print('Error in getAdminAppointments: $e');
      print('Stack trace: $stackTrace');
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to fetch appointments: $e',
          'details': stackTrace.toString()
        }),
      );
    }
  }

  Future<Response> approveAppointment(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if appointment exists
      final existingAppointment = await _database.query(
        'SELECT id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingAppointment.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Appointment not found'}));
      }

      final currentStatus = existingAppointment.first[1]?.toString() ?? '';

      // Only allow approval for scheduled or pending appointments
      if (!['scheduled', 'pending'].contains(currentStatus.toLowerCase())) {
        return Response(400, body: jsonEncode({'error': 'Appointment cannot be approved in its current status'}));
      }

      // Update appointment status to approved
      await _database.execute(
        'UPDATE appointments SET apt_status = @status WHERE id = @id',
        {'status': 'approved', 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'Appointment approved successfully'}));
    } catch (e) {
      print('Error in approveAppointment: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve appointment: $e'}),
      );
    }
  }

  Future<Response> rejectAppointment(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if appointment exists
      final existingAppointment = await _database.query(
        'SELECT id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingAppointment.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Appointment not found'}));
      }

      final currentStatus = existingAppointment.first[1]?.toString() ?? '';

      // Only allow rejection for scheduled or pending appointments
      if (!['scheduled', 'pending'].contains(currentStatus.toLowerCase())) {
        return Response(400, body: jsonEncode({'error': 'Appointment cannot be rejected in its current status'}));
      }

      // Update appointment status to cancelled
      await _database.execute(
        'UPDATE appointments SET apt_status = @status WHERE id = @id',
        {'status': 'cancelled', 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'Appointment rejected successfully'}));
    } catch (e) {
      print('Error in rejectAppointment: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject appointment: $e'}),
      );
    }
  }

  Future<Response> getAdminAnalytics(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get daily appointment summary directly
      final dailySummary = await _database.query('''
        SELECT
          DATE(appointment_date) as appointment_day,
          COUNT(*) as total_appointments,
          COUNT(CASE WHEN apt_status = 'scheduled' THEN 1 END) as scheduled,
          COUNT(CASE WHEN apt_status = 'completed' THEN 1 END) as completed,
          COUNT(CASE WHEN apt_status = 'cancelled' THEN 1 END) as cancelled
        FROM appointments
        WHERE appointment_date >= CURRENT_DATE - INTERVAL '30 days'
        GROUP BY DATE(appointment_date)
        ORDER BY appointment_day DESC
      ''');

      // Get monthly user registrations directly
      final monthlyRegistrations = await _database.query('''
        SELECT
          DATE_TRUNC('month', created_at) as registration_month,
          COUNT(*) as total_registrations,
          COUNT(CASE WHEN role = 'student' THEN 1 END) as student_registrations,
          COUNT(CASE WHEN role = 'counselor' THEN 1 END) as counselor_registrations,
          COUNT(CASE WHEN role = 'admin' THEN 1 END) as admin_registrations
        FROM users
        WHERE created_at >= CURRENT_DATE - INTERVAL '12 months'
        GROUP BY DATE_TRUNC('month', created_at)
        ORDER BY registration_month DESC
      ''');

      // Get appointment purpose distribution directly
      final purposeDistribution = await _database.query('''
        SELECT
          COALESCE(NULLIF(purpose, ''), 'No Purpose Specified') as purpose_category,
          COUNT(*) as appointment_count,
          ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
        FROM appointments
        GROUP BY COALESCE(NULLIF(purpose, ''), 'No Purpose Specified')
        ORDER BY appointment_count DESC
      ''');

      return Response.ok(jsonEncode({
        'daily_appointment_summary': dailySummary.map((row) => {
          'appointment_day': row[0]?.toString(),
          'total_appointments': row[1],
          'scheduled': row[2],
          'completed': row[3],
          'cancelled': row[4],
        }).toList(),
        'monthly_user_registrations': monthlyRegistrations.map((row) => {
          'registration_month': row[0]?.toString(),
          'total_registrations': row[1],
          'student_registrations': row[2],
          'counselor_registrations': row[3],
          'admin_registrations': row[4],
        }).toList(),
        'appointment_purpose_distribution': purposeDistribution.map((row) => {
          'purpose_category': row[0],
          'appointment_count': row[1],
          'percentage': row[2],
        }).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch analytics: $e'}),
      );
    }
  }
}
