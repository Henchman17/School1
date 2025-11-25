import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../connection.dart';

class AppointmentRoutes {
  final DatabaseConnection _database;

  AppointmentRoutes(this._database);

  // ================= APPOINTMENT MANAGEMENT ENDPOINTS =================

  Future<Response> createAppointment(Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response.badRequest(body: jsonEncode({'error': 'Invalid JSON format'}));
      }

      print('Create Appointment Request: $data');

      // Validate required fields
      if (data['user_id'] == null || data['counselor_id'] == null || data['appointment_date'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: user_id, counselor_id, appointment_date'}),
        );
      }

      // Check if user exists and is a student
      final userResult = await _database.query(
        'SELECT role, first_name, last_name FROM users WHERE id = @user_id',
        {'user_id': data['user_id']},
      );

      if (userResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Only students can create appointments'}));
      }

      // Check if counselor exists
      final counselorResult = await _database.query(
        'SELECT id FROM users WHERE id = @counselor_id AND role = @role',
        {'counselor_id': data['counselor_id'], 'role': 'counselor'},
      );

      if (counselorResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Counselor not found'}),
        );
      }

      // Validate appointment date restrictions
      final appointmentDate = DateTime.parse(data['appointment_date']);
      final now = DateTime.now();

      // Check if date is in the past (ignore time, only check date)
      final today = DateTime(now.year, now.month, now.day);
      final appointmentDay = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day);

      if (appointmentDay.isBefore(today)) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Cannot schedule appointments in the past'}),
        );
      }

      // Check if date is Monday to Friday (1 = Monday, 5 = Friday)
      final weekday = appointmentDate.weekday;
      if (weekday < 1 || weekday > 5) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointments can only be scheduled Monday to Friday'}),
        );
      }

      // Validate time slot (must be one of the allowed hours)
      final allowedHours = [8, 9, 10, 11, 13, 14, 15, 16]; // 8am-5pm excluding lunch
      if (!allowedHours.contains(appointmentDate.hour)) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid appointment time. Appointments must be scheduled between 8:00 AM and 5:00 PM'}),
        );
      }

      // Since students table was merged into users, student_id is now the user_id
      final studentId = data['user_id'];

      final result = await _database.execute('''
        INSERT INTO appointments (student_id, counselor_id, appointment_date, purpose, course, apt_status, notes)
        VALUES (@student_id, @counselor_id, @appointment_date, @purpose, @course, @apt_status, @notes)
        RETURNING id
      ''', {
        'student_id': studentId,
        'counselor_id': data['counselor_id'],
        'appointment_date': DateTime.parse(data['appointment_date']),
        'purpose': data['purpose'] ?? '',
        'course': data['course'] ?? '',
        'apt_status': data['apt_status'] ?? 'pending',
        'notes': data['notes'] ?? '',
      });

      print('Appointment created with ID: $result');

      return Response.ok(jsonEncode({
        'message': 'Appointment created successfully',
        'appointment_id': result,
        'student_id': studentId,
        'counselor_id': data['counselor_id'],
      }));
    } catch (e) {
      print('Error in createAppointment: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create appointment: $e'}),
      );
    }
  }

  Future<Response> getAppointments(Request request) async {
    try {
      final studentId = request.url.queryParameters['student_id'];
      final counselorId = request.url.queryParameters['counselor_id'];
      final userId = request.url.queryParameters['user_id'];

      // Security check: Require at least one filtering parameter
      if (userId == null && studentId == null && counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required parameter: user_id, student_id, or counselor_id'}),
        );
      }

      // Build the base query with proper JOINs to users table
      String query = '''
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
      ''';

      Map<String, dynamic> params = {};

      // Add filtering conditions
      if (userId != null) {
        query += ' WHERE a.student_id = @user_id';
        params['user_id'] = int.parse(userId);
      } else if (studentId != null) {
        query += ' WHERE a.student_id = @student_id';
        params['student_id'] = int.parse(studentId);
      } else if (counselorId != null) {
        query += ' WHERE a.counselor_id = @counselor_id';
        params['counselor_id'] = int.parse(counselorId);
      }

      query += ' ORDER BY a.created_at ASC';

      final result = await _database.query(query, params);

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
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': appointments.length,
        'appointments': appointments
      }));
    } catch (e) {
      print('Error in getAppointments: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch appointments: $e'}),
      );
    }
  }

  Future<Response> getApprovedAppointments(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];

      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Query for approved appointments for the specific student
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
          s.student_id as student_number
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        JOIN users u ON a.counselor_id = u.id
        WHERE a.student_id = @user_id AND a.apt_status = 'approved'
        ORDER BY a.appointment_date DESC
      ''', {'user_id': int.parse(userId)});

      final appointments = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'appointment_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3]?.toString(),
        'purpose': row[4]?.toString() ?? '',
        'course': row[5]?.toString() ?? '',
        'apt_status': row[6]?.toString() ?? 'approved',
        'notes': row[7]?.toString() ?? '',
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'student_name': row[9]?.toString() ?? 'Unknown Student',
        'counselor_name': row[10]?.toString() ?? 'Unknown Counselor',
        'student_number': row[11]?.toString(),
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': appointments.length,
        'appointments': appointments
      }));
    } catch (e) {
      print('Error in getApprovedAppointments: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch approved appointments: $e'}),
      );
    }
  }

  Future<Response> getAppointmentNotifications(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];

      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Query for all appointment notifications (approved, cancelled, scheduled) for the specific student
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
          a.cancellation_reason,
          CONCAT(s.first_name, ' ', s.last_name) as student_name,
          u.username as counselor_name,
          s.student_id as student_number
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        JOIN users u ON a.counselor_id = u.id
        WHERE a.student_id = @user_id AND a.apt_status IN ('approved', 'cancelled', 'scheduled')
        ORDER BY a.created_at DESC
      ''', {'user_id': int.parse(userId)});

      final notifications = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'appointment_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3]?.toString(),
        'purpose': row[4]?.toString() ?? '',
        'course': row[5]?.toString() ?? '',
        'apt_status': row[6]?.toString() ?? '',
        'notes': row[7]?.toString() ?? '',
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'cancellation_reason': row[9]?.toString() ?? '',
        'student_name': row[10]?.toString() ?? 'Unknown Student',
        'counselor_name': row[11]?.toString() ?? 'Unknown Counselor',
        'student_number': row[12]?.toString(),
        'notification_type': _getNotificationType(row[6]?.toString() ?? ''),
        'message': _getNotificationMessage(row[6]?.toString() ?? '', row[9]?.toString() ?? ''),
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': notifications.length,
        'notifications': notifications
      }));
    } catch (e) {
      print('Error in getAppointmentNotifications: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch appointment notifications: $e'}),
      );
    }
  }

  String _getNotificationType(String status) {
    switch (status) {
      case 'approved':
        return 'approved';
      case 'cancelled':
        return 'cancelled';
      case 'scheduled':
        return 'scheduled';
      default:
        return 'general';
    }
  }

  String _getNotificationMessage(String status, String cancellationReason) {
    switch (status) {
      case 'approved':
        return 'Your appointment request has been approved.';
      case 'cancelled':
        return cancellationReason.isNotEmpty
            ? 'Your appointment has been cancelled. Reason: $cancellationReason'
            : 'Your appointment has been cancelled.';
      case 'scheduled':
        return 'A new appointment has been scheduled for you.';
      default:
        return 'You have a new appointment update.';
    }
  }

  Future<Response> updateAppointment(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      print('Update Appointment Request: $data for ID: $id');

      // Check if appointment exists and user has permission
      final existingAppointment = await _database.query(
        'SELECT student_id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingAppointment.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = existingAppointment.first;
      final studentId = appointment[0];
      final counselorId = appointment[1];
      final currentStatus = appointment[2];

      // Get user_id from request body for authorization check
      final userId = data['user_id'];
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id is required for authorization'}),
        );
      }

      // Check if user is the student who created the appointment or a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @user_id',
        {'user_id': userId},
      );

      if (userResult.isEmpty) {
        return Response.forbidden(
          jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      final isOwner = userId == studentId;
      final isCounselor = userRole == 'counselor' || userId == counselorId;

      if (!isOwner && !isCounselor) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only update your own appointments'}),
        );
      }

      // Prevent updating completed or cancelled appointments (unless counselor)
      if (!isCounselor && (currentStatus == 'completed' || currentStatus == 'cancelled')) {
        return Response.forbidden(
          jsonEncode({'error': 'Cannot update completed or cancelled appointments'}),
        );
      }

      // Build update query
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['appointment_date'] != null) {
        final newAppointmentDate = DateTime.parse(data['appointment_date']);

        // Validate appointment date restrictions for updates
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final appointmentDay = DateTime(newAppointmentDate.year, newAppointmentDate.month, newAppointmentDate.day);

        if (appointmentDay.isBefore(today)) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Cannot schedule appointments in the past'}),
          );
        }

        // Check if date is Monday to Friday (1 = Monday, 5 = Friday)
        final weekday = newAppointmentDate.weekday;
        if (weekday < 1 || weekday > 5) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Appointments can only be scheduled Monday to Friday'}),
          );
        }

        // Validate time slot (must be one of the allowed hours)
        final allowedHours = [8, 9, 10, 11, 13, 14, 15, 16]; // 8am-5pm excluding lunch
        if (!allowedHours.contains(newAppointmentDate.hour)) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Invalid appointment time. Appointments must be scheduled between 8:00 AM and 5:00 PM'}),
          );
        }

        updateFields.add('appointment_date = @appointment_date');
        params['appointment_date'] = newAppointmentDate;
      }

      if (data['purpose'] != null) {
        updateFields.add('purpose = @purpose');
        params['purpose'] = data['purpose'];
      }

      if (data['course'] != null) {
        updateFields.add('course = @course');
        params['course'] = data['course'];
      }

      if (data['status'] != null && isCounselor) {
        updateFields.add('apt_status = @apt_status');
        params['apt_status'] = data['status'];
      }

      if (data['notes'] != null) {
        updateFields.add('notes = @notes');
        params['notes'] = data['notes'];
      }

      if (updateFields.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No valid fields to update'}),
        );
      }

      final updateQuery = 'UPDATE appointments SET ${updateFields.join(', ')} WHERE id = @id';
      await _database.execute(updateQuery, params);

      return Response.ok(jsonEncode({
        'message': 'Appointment updated successfully',
        'appointment_id': id,
      }));
    } catch (e) {
      print('Error in updateAppointment: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update appointment: $e'}),
      );
    }
  }

  Future<Response> deleteAppointment(Request request, String id) async {
    try {
      print('Delete Appointment Request for ID: $id');

      // Check if appointment exists and user has permission
      final existingAppointment = await _database.query(
        'SELECT student_id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingAppointment.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = existingAppointment.first;
      final studentId = appointment[0];
      final counselorId = appointment[1];
      final currentStatus = appointment[2];

      // Get user_id from query parameters for authorization check
      final userId = request.url.queryParameters['user_id'];
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id is required for authorization'}),
        );
      }

      // Check if user is the student who created the appointment or a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userResult.isEmpty) {
        return Response.forbidden(
          jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      final isOwner = int.parse(userId) == studentId;
      final isCounselor = userRole == 'counselor' || int.parse(userId) == counselorId;

      if (!isOwner && !isCounselor) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only delete your own appointments'}),
        );
      }

      // Prevent deleting completed appointments (unless counselor)
      if (!isCounselor && currentStatus == 'completed') {
        return Response.forbidden(
          jsonEncode({'error': 'Cannot delete completed appointments'}),
        );
      }

      // Delete the appointment
      await _database.execute(
        'DELETE FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({
        'message': 'Appointment deleted successfully',
        'appointment_id': id,
      }));
    } catch (e) {
      print('Error in deleteAppointment: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete appointment: $e'}),
      );
    }
  }

  Future<Response> getCourses(Request request) async {
    try {
      final result = await _database.query('''
        SELECT id, course_code, course_name, college, grade_requirement, description
        FROM courses
        WHERE is_active = true
        ORDER BY college, course_name
      ''');

      final courses = result.map((row) => {
        'id': row[0],
        'course_code': row[1],
        'course_name': row[2],
        'college': row[3],
        'grade_requirement': row[4],
        'description': row[5],
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': courses.length,
        'courses': courses
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch courses: $e'}),
      );
    }
  }
}
