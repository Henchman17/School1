import 'dart:convert';
import 'dart:io';
import 'package:docx_template/docx_template.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../connection.dart';
import '../docx_template.dart';
//import '../lib/document_generator.dart';

class CounselorRoutes {
  final DatabaseConnection _database;

  CounselorRoutes(this._database);

  // Helper method for role-based authorization
  Future<bool> _checkUserRole(int userId, String requiredRole) async {
    final result = await _database.query(
      'SELECT role FROM users WHERE id = @id',
      {'id': userId},
    );

    if (result.isEmpty) return false;
    final userRole = result.first[0];

    // Admin has access to everything
    if (userRole == 'admin') return true;

    // Counselor has access to counselor and student functions
    if (requiredRole == 'counselor' && userRole == 'counselor') return true;
    if (requiredRole == 'student' && (userRole == 'counselor' || userRole == 'student')) return true;

    return userRole == requiredRole;
  }

  Future<Response> getCounselorDashboard(Request request) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Get counselor's statistics
      final stats = await _database.query('''
        SELECT
          COUNT(DISTINCT student_id) as total_students,
          COUNT(*) as total_appointments,
          COUNT(CASE WHEN apt_status = 'scheduled' THEN 1 END) as scheduled,
          COUNT(CASE WHEN apt_status = 'completed' THEN 1 END) as completed
        FROM appointments
        WHERE counselor_id = @counselor_id
      ''', {'counselor_id': counselorId});

      // Get recent students
      final recentStudents = await _database.query('''
        SELECT DISTINCT
          s.id,
          s.first_name,
          s.last_name,
          s.status,
          s.program,
          MAX(a.appointment_date) as last_appointment_date
        FROM users s
        JOIN appointments a ON s.id = a.student_id
        WHERE a.counselor_id = @counselor_id
        GROUP BY s.id, s.first_name, s.last_name, s.status, s.program
        ORDER BY MAX(a.appointment_date) DESC
        LIMIT 5
      ''', {'counselor_id': counselorId});

      // Get upcoming appointments
      final upcomingAppointments = await _database.query('''
        SELECT
          a.id,
          a.student_id,
          a.appointment_date,
          a.purpose,
          a.course,
          a.apt_status,
          a.notes,
          CONCAT(s.first_name, ' ', s.last_name) as student_name,
          s.student_id as student_number,
          s.status,
          s.program
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        WHERE a.counselor_id = @counselor_id AND a.appointment_date >= CURRENT_DATE
        ORDER BY a.appointment_date ASC
        LIMIT 10
      ''', {'counselor_id': counselorId});

      return Response.ok(jsonEncode({
        'statistics': stats.isNotEmpty ? {
          'total_students': stats.first[0],
          'counseling_sessions': stats.first[1],
          'pending_requests': stats.first[2],
          'completed_sessions': stats.first[3],
        } : null,
        'recent_students': recentStudents.map((row) => {
          'id': row[0],
          'first_name': row[1]?.toString() ?? '',
          'last_name': row[2]?.toString() ?? '',
          'status': row[3]?.toString() ?? '',
          'program': row[4]?.toString() ?? '',
          'last_appointment_date': row[5]?.toString(),
        }).toList(),
        'upcoming_appointments': upcomingAppointments.map((row) => {
          'id': row[0],
          'student_id': row[1],
          'appointment_date': row[2] is DateTime ? (row[2] as DateTime).toIso8601String() : row[2]?.toString(),
          'purpose': row[3]?.toString() ?? '',
          'course': row[4]?.toString() ?? '',
          'apt_status': row[5]?.toString() ?? 'scheduled',
          'notes': row[6]?.toString() ?? '',
          'student_name': row[7]?.toString() ?? 'Unknown Student',
          'student_number': row[8]?.toString(),
          'status': row[9]?.toString(),
          'program': row[10]?.toString(),
        }).map((appointment) {
          // Calculate overdue status for upcoming appointments
          if (appointment['apt_status'] == 'scheduled') {
            final appointmentDate = DateTime.tryParse(appointment['appointment_date']?.toString() ?? '');
            if (appointmentDate != null && appointmentDate.isBefore(DateTime.now())) {
              appointment['apt_status'] = 'overdue';
            }
          }
          return appointment;
        }).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch counselor dashboard: $e'}),
      );
    }
  }

  Future<Response> completeAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists and belongs to this counselor
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only complete appointments assigned to you'}),
        );
      }

      if (appointment[2] == 'completed') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointment is already completed'}),
        );
      }

      // Update the appointment status to completed
      await _database.execute('''
        UPDATE appointments
        SET apt_status = 'completed'
        WHERE id = @id
      ''', {
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment marked as completed successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to complete appointment: $e'}),
      );
    }
  }

  Future<Response> confirmAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists and belongs to this counselor
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only confirm appointments assigned to you'}),
        );
      }

      if (appointment[2] == 'confirmed') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointment is already confirmed'}),
        );
      }

      // Update the appointment status to confirmed
      await _database.execute('''
        UPDATE appointments
        SET apt_status = 'confirmed'
        WHERE id = @id
      ''', {
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment confirmed successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to confirm appointment: $e'}),
      );
    }
  }

  Future<Response> approveAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists and belongs to this counselor
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, approval_status, purpose FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only approve appointments assigned to you'}),
        );
      }

      // Check if the appointment purpose is Psychological Examination
      final purpose = appointment[3]?.toString() ?? '';
      if (purpose.toLowerCase() != 'psychological examination') {
        return Response.badRequest(
          body: jsonEncode({'error': 'You can only approve appointments for Psychological Examination'}),
        );
      }

      if (appointment[2] == 'approved') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointment is already approved'}),
        );
      }

      // Update the appointment approval status
      await _database.execute('''
        UPDATE appointments
        SET approval_status = 'approved',
            approved_by = @counselor_id,
            approved_at = NOW(),
            rejection_reason = NULL,
            apt_status = 'scheduled'
        WHERE id = @id
      ''', {
        'counselor_id': counselorId,
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment approved successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve appointment: $e'}),
      );
    }
  }

  Future<Response> rejectAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];
      final rejectionReason = data['rejection_reason'] ?? '';

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists and belongs to this counselor
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, approval_status FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only reject appointments assigned to you'}),
        );
      }

      if (appointment[2] == 'rejected') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointment is already rejected'}),
        );
      }

      // Update the appointment approval status
      await _database.execute('''
        UPDATE appointments
        SET approval_status = 'rejected',
            approved_by = @counselor_id,
            approved_at = NOW(),
            rejection_reason = @rejection_reason,
            apt_status = 'cancelled'
        WHERE id = @id
      ''', {
        'counselor_id': counselorId,
        'rejection_reason': rejectionReason,
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment rejected successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject appointment: $e'}),
      );
    }
  }

  Future<Response> cancelAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];
      final cancellationReason = data['cancellation_reason'] ?? '';

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      if (cancellationReason.trim().isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'cancellation_reason is required and cannot be empty'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists and belongs to this counselor
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only cancel appointments assigned to you'}),
        );
      }

      if (appointment[2] == 'cancelled') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Appointment is already cancelled'}),
        );
      }

      if (appointment[2] == 'completed') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Cannot cancel a completed appointment'}),
        );
      }

      // Update the appointment status to cancelled with reason
      await _database.execute('''
        UPDATE appointments
        SET apt_status = 'cancelled',
            cancellation_reason = @cancellation_reason,
            cancelled_by = @counselor_id,
            cancelled_at = NOW()
        WHERE id = @id
      ''', {
        'cancellation_reason': cancellationReason,
        'counselor_id': counselorId,
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment cancelled successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to cancel appointment: $e'}),
      );
    }
  }

  Future<Response> deleteAppointment(Request request, String appointmentId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the appointment exists, belongs to this counselor, and is cancelled
      final appointmentResult = await _database.query(
        'SELECT id, counselor_id, apt_status FROM appointments WHERE id = @id',
        {'id': int.parse(appointmentId)},
      );

      if (appointmentResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Appointment not found'}),
        );
      }

      final appointment = appointmentResult.first;
      if (appointment[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only delete appointments assigned to you'}),
        );
      }

      if (appointment[2] != 'cancelled') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Can only delete cancelled appointments'}),
        );
      }

      // Delete the appointment
      await _database.execute('''
        DELETE FROM appointments
        WHERE id = @id
      ''', {
        'id': int.parse(appointmentId),
      });

      return Response.ok(jsonEncode({
        'message': 'Appointment deleted successfully',
        'appointment_id': appointmentId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete appointment: $e'}),
      );
    }
  }

  Future<Response> getCounselorStudents(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _checkUserRole(userId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      final result = await _database.query('''
        SELECT id, username, email, role, created_at,
               student_id, first_name, last_name, status, program
        FROM users
        WHERE role = 'student'
        ORDER BY last_name, first_name
      ''');

      final students = result.map((row) => {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'role': row[3],
        'created_at': row[4] is DateTime ? (row[4] as DateTime).toIso8601String() : row[4]?.toString(),
        'student_id': row[5],
        'first_name': row[6],
        'last_name': row[7],
        'status': row[8],
        'program': row[9],
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': students.length,
        'students': students
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch students: $e'}),
      );
    }
  }

  Future<Response> getStudentProfile(Request request, String studentId) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['counselor_id'] ?? '0');
      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Get basic student information
      final studentResult = await _database.query('''
        SELECT id, username, email, role, created_at,
               student_id, first_name, last_name, status, program
        FROM users
        WHERE id = @student_id AND role = 'student'
      ''', {'student_id': int.parse(studentId)});

      if (studentResult.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Student not found'}));
      }

      final student = studentResult.first;
      final studentData = {
        'id': student[0],
        'username': student[1],
        'email': student[2],
        'role': student[3],
        'created_at': student[4] is DateTime ? (student[4] as DateTime).toIso8601String() : student[4]?.toString(),
        'student_id': student[5],
        'first_name': student[6],
        'last_name': student[7],
        'status': student[8],
        'program': student[9],
      };

      // Get SCRF record if exists
      Map<String, dynamic>? scrfData;
      try {
        final scrfResult = await _database.query('SELECT * FROM get_scrf_record(@user_id)', {
          'user_id': int.parse(studentId),
        });

        if (scrfResult.isNotEmpty) {
          final row = scrfResult.first;
          scrfData = {
            'id': row[0],
            'user_id': row[1],
            'student_id': row[2],
            'username': row[3],
            'student_number': row[4],
            'first_name': row[5],
            'last_name': row[6],
            'program_enrolled': row[7],
            'sex': row[8],
            'full_name': row[9],
            'address': row[10],
            'zipcode': row[11],
            'age': row[12],
            'civil_status': row[13],
            'date_of_birth': row[14] is DateTime ? (row[14] as DateTime).toIso8601String() : row[14]?.toString(),
            'place_of_birth': row[15],
            'lrn': row[16],
            'cellphone': row[17],
            'email_address': row[18],
            'father_name': row[19],
            'father_age': row[20],
            'father_occupation': row[21],
            'mother_name': row[22],
            'mother_age': row[23],
            'mother_occupation': row[24],
            'living_with_parents': row[25],
            'guardian_name': row[26],
            'guardian_relationship': row[27],
            'siblings': row[28],
            'educational_background': row[29],
            'awards_received': row[30],
            'transferee_college_name': row[31],
            'transferee_program': row[32],
            'physical_defect': row[33],
            'allergies_food': row[34],
            'allergies_medicine': row[35],
            'exam_taken': row[36],
            'exam_date': row[37] is DateTime ? (row[37] as DateTime).toIso8601String() : row[37]?.toString(),
            'raw_score': row[38],
            'percentile': row[39],
            'adjectival_rating': row[40],
            'created_at': row[41] is DateTime ? (row[41] as DateTime).toIso8601String() : row[41]?.toString(),
            'updated_at': row[42] is DateTime ? (row[42] as DateTime).toIso8601String() : row[42]?.toString(),
          };
        }
      } catch (e) {
        // SCRF record doesn't exist, continue without it
        scrfData = null;
      }

      // Get routine interview record if exists
      Map<String, dynamic>? routineInterviewData;
      try {
        final routineResult = await _database.query('''
          SELECT
            ri.id,
            ri.name,
            ri.date,
            ri.grade_course_year_section,
            ri.nickname,
            ri.ordinal_position,
            ri.student_description,
            ri.familial_description,
            ri.strengths,
            ri.weaknesses,
            ri.achievements,
            ri.best_work_person,
            ri.first_choice,
            ri.goals,
            ri.contribution,
            ri.talents_skills,
            ri.home_problems,
            ri.school_problems,
            ri.applicant_signature,
            ri.signature_date,
            ri.created_at,
            u.student_id,
            u.first_name,
            u.last_name,
            u.status,
            u.program
          FROM routine_interviews ri
          JOIN users u ON ri.student_id = u.id
          WHERE u.id = @user_id
          ORDER BY ri.created_at DESC
          LIMIT 1
        ''', {'user_id': int.parse(studentId)});

        if (routineResult.isNotEmpty) {
          final row = routineResult.first;
          routineInterviewData = {
            'id': row[0],
            'name': row[1],
            'date': row[2] is DateTime ? (row[2] as DateTime).toIso8601String() : row[2]?.toString(),
            'grade_course_year_section': row[3],
            'nickname': row[4],
            'ordinal_position': row[5],
            'student_description': row[6],
            'familial_description': row[7],
            'strengths': row[8],
            'weaknesses': row[9],
            'achievements': row[10],
            'best_work_person': row[11],
            'first_choice': row[12],
            'goals': row[13],
            'contribution': row[14],
            'talents_skills': row[15],
            'home_problems': row[16],
            'school_problems': row[17],
            'applicant_signature': row[18],
            'signature_date': row[19] is DateTime ? (row[19] as DateTime).toIso8601String() : row[19]?.toString(),
            'created_at': row[20] is DateTime ? (row[20] as DateTime).toIso8601String() : row[20]?.toString(),
            'student_id': row[21],
            'first_name': row[22],
            'last_name': row[23],
            'status': row[24],
            'program': row[25],
          };
        }
      } catch (e) {
        // Routine interview doesn't exist, continue without it
        routineInterviewData = null;
      }

      // Flatten the response to match frontend expectations
      final responseData = {
        ...studentData,
        'scrf_data': scrfData,
        'routine_interview': routineInterviewData,
      };

      return Response.ok(jsonEncode(responseData));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch student profile: $e'}),
      );
    }
  }

  Future<Response> getCounselorAppointments(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': int.parse(userId)},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

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
          s.student_id as student_number,
          s.first_name as student_first_name,
          s.last_name as student_last_name,
          s.status,
          s.program
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        WHERE a.counselor_id = @counselor_id
        ORDER BY a.appointment_date DESC
      ''', {'counselor_id': int.parse(userId)});

      final appointments = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'appointment_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3].toString(),
        'purpose': row[4]?.toString() ?? '',
        'course': row[5]?.toString() ?? '',
        'apt_status': row[6]?.toString() ?? 'scheduled',
        'notes': row[7]?.toString() ?? '',
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8].toString(),
        'student_name': row[9]?.toString() ?? 'Unknown Student',
        'student_number': row[10]?.toString(),
        'student_first_name': row[11]?.toString(),
        'student_last_name': row[12]?.toString(),
        'status': row[13]?.toString(),
        'program': row[14]?.toString(),
        'date': row[3] is DateTime ? (row[3] as DateTime).toString().split(' ')[0] : row[3].toString().split(' ')[0],
        'time': row[3] is DateTime ? (row[3] as DateTime).toString().split(' ')[1].substring(0, 5) : '00:00',
        'type': row[4]?.toString() ?? 'General Counseling',
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': appointments.length,
        'appointments': appointments
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch appointments: $e'}),
      );
    }
  }

  Future<Response> getCounselorSessions(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': int.parse(userId)},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // For now, we'll simulate sessions using completed appointments
      // In a real implementation, you'd have a separate sessions table
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
          s.student_id as student_number,
          s.first_name as student_first_name,
          s.last_name as student_last_name,
          s.status,
          s.program
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        WHERE a.counselor_id = @counselor_id AND a.apt_status IN ('completed', 'in_progress')
        ORDER BY a.appointment_date DESC
      ''', {'counselor_id': int.parse(userId)});

      final sessions = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'date': row[3] is DateTime ? (row[3] as DateTime).toString().split(' ')[0] : row[3].toString().split(' ')[0],
        'start_time': row[3] is DateTime ? (row[3] as DateTime).toString().split(' ')[1].substring(0, 5) : '09:00',
        'end_time': row[3] is DateTime ? (row[3] as DateTime).add(const Duration(hours: 1)).toString().split(' ')[1].substring(0, 5) : '10:00',
        'type': row[4]?.toString() ?? 'General Counseling',
        'apt_status': row[6]?.toString() == 'completed' ? 'completed' : 'in_progress',
        'notes': row[7]?.toString() ?? 'Session completed successfully',
        'student_name': row[9]?.toString() ?? 'Unknown Student',
        'student_number': row[10]?.toString(),
        'student_first_name': row[11]?.toString(),
        'student_last_name': row[12]?.toString(),
        'status': row[13]?.toString(),
        'program': row[14]?.toString(),
      }).map((session) {
        // Calculate overdue status for sessions
        if (session['apt_status'] == 'in_progress') {
          final sessionDate = DateTime.tryParse(session['date']?.toString() ?? '');
          if (sessionDate != null && sessionDate.isBefore(DateTime.now())) {
            session['apt_status'] = 'overdue';
          }
        }
        return session;
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': sessions.length,
        'sessions': sessions
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch sessions: $e'}),
      );
    }
  }

  Future<Response> getCounselorGuidanceSchedules(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];
      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': int.parse(userId)},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      final result = await _database.query('''
        SELECT
          a.id,
          a.student_id,
          a.counselor_id,
          a.appointment_date,
          a.purpose,
          a.course,
          a.apt_status,
          a.approval_status,
          a.approved_by,
          a.approved_at,
          a.rejection_reason,
          a.notes,
          a.created_at,
          CONCAT(s.first_name, ' ', s.last_name) as student_name,
          s.student_id as student_number,
          s.first_name as student_first_name,
          s.last_name as student_last_name,
          s.status,
          s.program
        FROM appointments a
        JOIN users s ON a.student_id = s.id
        WHERE a.counselor_id = @counselor_id
        ORDER BY a.created_at ASC
      ''', {'counselor_id': int.parse(userId)});

      final schedules = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'counselor_id': row[2],
        'appointment_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3].toString(),
        'purpose': row[4]?.toString() ?? '',
        'course': row[5]?.toString() ?? '',
        'apt_status': row[6]?.toString() ?? 'scheduled',
        'approval_status': row[7]?.toString() ?? 'pending',
        'approved_by': row[8],
        'approved_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'rejection_reason': row[10]?.toString() ?? '',
        'notes': row[11]?.toString() ?? '',
        'created_at': row[12] is DateTime ? (row[12] as DateTime).toIso8601String() : row[12].toString(),
        'student_name': row[13]?.toString() ?? 'Unknown Student',
        'student_number': row[14]?.toString(),
        'student_first_name': row[15]?.toString(),
        'student_last_name': row[16]?.toString(),
        'status': row[17]?.toString(),
        'program': row[18]?.toString(),
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': schedules.length,
        'schedules': schedules
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch guidance schedules: $e'}),
      );
    }
  }

  Future<Response> approveGuidanceSchedule(Request request, String scheduleId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the schedule exists and belongs to this counselor
      final scheduleResult = await _database.query(
        'SELECT id, counselor_id, approval_status FROM appointments WHERE id = @id',
        {'id': int.parse(scheduleId)},
      );

      if (scheduleResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Guidance schedule not found'}),
        );
      }

      final schedule = scheduleResult.first;
      if (schedule[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only approve schedules assigned to you'}),
        );
      }

      if (schedule[2] == 'approved') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Schedule is already approved'}),
        );
      }

      // Update the schedule with approval
      await _database.execute('''
        UPDATE appointments
        SET approval_status = 'approved',
            approved_by = @counselor_id,
            approved_at = NOW(),
            rejection_reason = NULL,
            apt_status = 'scheduled'
        WHERE id = @id
      ''', {
        'counselor_id': counselorId,
        'id': int.parse(scheduleId),
      });

      return Response.ok(jsonEncode({
        'message': 'Guidance schedule approved successfully',
        'schedule_id': scheduleId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve guidance schedule: $e'}),
      );
    }
  }

  Future<Response> rejectGuidanceSchedule(Request request, String scheduleId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      final counselorId = data['counselor_id'];
      final rejectionReason = data['rejection_reason'] ?? '';

      if (counselorId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'counselor_id is required'}),
        );
      }

      // Verify user is a counselor
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @id',
        {'id': counselorId},
      );

      if (userResult.isEmpty || userResult.first[0] != 'counselor') {
        return Response.forbidden(
          jsonEncode({'error': 'Access denied. Counselor role required.'}),
        );
      }

      // Check if the schedule exists and belongs to this counselor
      final scheduleResult = await _database.query(
        'SELECT id, counselor_id, approval_status FROM appointments WHERE id = @id',
        {'id': int.parse(scheduleId)},
      );

      if (scheduleResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Guidance schedule not found'}),
        );
      }

      final schedule = scheduleResult.first;
      if (schedule[1] != counselorId) {
        return Response.forbidden(
          jsonEncode({'error': 'You can only reject schedules assigned to you'}),
        );
      }

      if (schedule[2] == 'rejected') {
        return Response.badRequest(
          body: jsonEncode({'error': 'Schedule is already rejected'}),
        );
      }

      // Update the schedule with rejection
      await _database.execute('''
        UPDATE appointments
        SET approval_status = 'rejected',
            approved_by = @counselor_id,
            approved_at = NOW(),
            rejection_reason = @rejection_reason,
            apt_status = 'cancelled'
        WHERE id = @id
      ''', {
        'counselor_id': counselorId,
        'rejection_reason': rejectionReason,
        'id': int.parse(scheduleId),
      });

      return Response.ok(jsonEncode({
        'message': 'Guidance schedule rejected successfully',
        'schedule_id': scheduleId,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject guidance schedule: $e'}),
      );
    }
  }


// ================= GOOD MORAL CERTIFICATE GENERATION =================

Future<String> generateGoodMoralDocx(Map<String, dynamic> data) async {
  final file = File('templates/GoodMoral.docx');
  final bytes = await file.readAsBytes();
  final docx = await DocxTemplate.fromBytes(bytes);

  final content = Content();

  content
    ..add(TextContent("name", data["name"]))
    ..add(TextContent("course", data["course"]))
    ..add(TextContent("school_year", data["school_year"]))
    ..add(TextContent("day", data["day"]))
    ..add(TextContent("month_year", data["month_year"]))
    ..add(TextContent("purpose", data["purpose"]))
    ..add(TextContent("gor", data["gor"]))
    ..add(TextContent("date_of_payment", data["date_of_payment"]));

  final generated = await docx.generate(content);

  final outputFolder = Directory('generated');
  if (!outputFolder.existsSync()) outputFolder.createSync();

  final outputPath =
      "generated/good_moral_${DateTime.now().millisecondsSinceEpoch}.docx";

  final outFile = File(outputPath);
  await outFile.writeAsBytes(generated!);

  return outputPath;
}

// ================= GOOD MORAL REQUEST ENDPOINTS =================

Future<Response> getGoodMoralRequests(Request request) async {
  try {
    final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
    if (!await _checkUserRole(adminId, 'admin')) {
      return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
    }

    print('Request received: ${request.method} ${request.requestedUri.path}');

    // Pagination parameters
    final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
    final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
    final offset = (page - 1) * limit;

    // Get total count
    final totalResult = await _database.query('SELECT COUNT(*) FROM good_moral_requests');
    final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

    // Get paginated results
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
      LIMIT @limit OFFSET @offset
    ''', {'limit': limit, 'offset': offset});

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
      'ocr_data': row[9],
      'approval_status': row[10],
      'current_approval_step': row[11],
      'total_approvals_needed': row[12],
      'approvals_received': row[13],
      'certificate_path': row[14],
      'certificate_generated_at': row[15] is DateTime ? (row[15] as DateTime).toIso8601String() : row[15]?.toString(),
      'admin_approved': row[16],
      'admin_approved_at': row[17] is DateTime ? (row[17] as DateTime).toIso8601String() : row[17]?.toString(),
      'admin_approved_by': row[18],
      'rejection_reason': row[19],
      'rejected_at': row[20] is DateTime ? (row[20] as DateTime).toIso8601String() : row[20]?.toString(),
      'rejected_by': row[21],
      'created_at': row[22] is DateTime ? (row[22] as DateTime).toIso8601String() : row[22]?.toString(),
      'updated_at': row[23] is DateTime ? (row[23] as DateTime).toIso8601String() : row[23]?.toString(),
      'created_by': row[24],
      'updated_by': row[25],
      'first_name': row[26],
      'last_name': row[27],
      'email': row[28],
      'user_student_id': row[29],
      'admin_approved_by_name': row[30],
      'rejected_by_name': row[31],
    }).toList();

   final totalInt = int.tryParse(total.toString()) ?? 0;
    return Response.ok(jsonEncode({
      'success': true,
      'total': totalInt,
      'page': page,
      'limit': limit,
      'requests': requests
    }));
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
    if (!await _checkUserRole(adminId, 'admin')) {
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
    final certificateData = {
      'name': studentName,
      'course': course ?? 'N/A',
      'school_year': schoolYear ?? 'N/A',
      'day': now.day.toString(),
      'month_year': '${_getMonthName(now.month)} ${now.year}',
      'purpose': purpose ?? 'N/A',
      'gor': gor ?? 'N/A',
      'date_of_payment': edst ?? 'N/A',
    };

    // Generate certificate
    String certificatePath;
    try {
      certificatePath = await generateGoodMoralDocx(certificateData);
    } catch (e) {
      print('Error generating certificate: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to generate certificate: $e'}),
      );
    }
    
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
        'certificate_path': certificatePath,
        'approvals_received': 4 // All approvals received
      },
    );

    return Response.ok(jsonEncode({
      'message': 'Good moral request approved successfully',
      'certificate_path': certificatePath,
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
    if (!await _checkUserRole(adminId, 'admin')) {
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
    if (!await _checkUserRole(adminId, 'admin')) {
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
    if (!await _checkUserRole(adminId, 'admin')) {
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

  // ================= DISCIPLINE CASES ENDPOINTS =================

  Future<Response> getCounselorDisciplineCases(Request request) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['counselor_id'] ?? '0');
      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      final result = await _database.query('''
        SELECT
          dc.id,
          dc.student_name,
          dc.student_number,
          dc.incident_date,
          dc.incident_description,
          dc.incident_location,
          dc.witnesses,
          dc.action_taken,
          dc.severity,
          dc.status,
          dc.admin_notes,
          dc.counselor_id,
          dc.grade_level,
          dc.program,
          dc.section,
          dc.created_at,
          dc.updated_at,
          dc.resolved_at,
          dc.resolved_by,
          u.username as counselor_name,
          ru.username as resolved_by_name
        FROM discipline_cases dc
        LEFT JOIN users u ON dc.counselor_id = u.id
        LEFT JOIN users ru ON dc.resolved_by = ru.id
        ORDER BY dc.created_at DESC
      ''');

      final cases = result.map((row) => {
        'id': row[0],
        'student_name': row[1],
        'student_number': row[2],
        'incident_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3]?.toString(),
        'incident_description': row[4],
        'incident_location': row[5],
        'witnesses': row[6],
        'action_taken': row[7],
        'severity': row[8],
        'status': row[9],
        'admin_notes': row[10],
        'counselor_id': row[11],
        'grade_level': row[12],
        'program': row[13],
        'section': row[14],
        'created_at': row[15] is DateTime ? (row[15] as DateTime).toIso8601String() : row[15]?.toString(),
        'updated_at': row[16] is DateTime ? (row[16] as DateTime).toIso8601String() : row[16]?.toString(),
        'resolved_at': row[17] is DateTime ? (row[17] as DateTime).toIso8601String() : row[17]?.toString(),
        'resolved_by': row[18],
        'counselor_name': row[19],
        'resolved_by_name': row[20],
      }).toList();

      return Response.ok(jsonEncode({'cases': cases}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch discipline cases: $e'}),
      );
    }
  }

  Future<Response> createCounselorDisciplineCase(Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final counselorId = data['counselor_id'];

      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Validation
      if (data['student_name'] == null || data['student_name'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Student name is required'}));
      }
      if (data['student_number'] == null || data['student_number'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Student number is required'}));
      }
      if (data['incident_date'] == null || data['incident_date'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Incident date is required'}));
      }
      // Validate incident date format
      try {
        DateTime.parse(data['incident_date']);
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid incident date format. Use YYYY-MM-DD format'}));
      }
      if (data['incident_description'] == null || data['incident_description'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Incident description is required'}));
      }
      if (data['severity'] == null || data['severity'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Severity is required'}));
      }
      // Validate severity
      if (!['light_offenses', 'less_grave_offenses', 'grave_offenses'].contains(data['severity'])) {
        return Response(400, body: jsonEncode({'error': 'Invalid severity value. Must be one of: light_offenses, less_grave_offenses, grave_offenses'}));
      }
      // Validate status if provided
      if (data['status'] != null && !['open', 'under_investigation', 'resolved', 'closed'].contains(data['status'])) {
        return Response(400, body: jsonEncode({'error': 'Invalid status value. Must be one of: open, under_investigation, resolved, closed'}));
      }

      final insertData = {
        'student_name': data['student_name'],
        'student_number': data['student_number'],
        'incident_date': DateTime.parse(data['incident_date']),
        'incident_description': data['incident_description'],
        'incident_location': data['incident_location'],
        'witnesses': data['witnesses'],
        'severity': data['severity'],
        'status': data['status'] ?? 'open',
        'counselor_id': counselorId,
        'grade_level': data['grade_level'],
        'program': data['program'],
        'section': data['section'],
      };

      final result = await _database.query('''
        INSERT INTO discipline_cases (student_name, student_number, incident_date, incident_description, incident_location, witnesses, severity, status, counselor_id, grade_level, program, section)
        VALUES (@student_name, @student_number, @incident_date, @incident_description, @incident_location, @witnesses, @severity, @status, @counselor_id, @grade_level, @program, @section)
        RETURNING id, student_name, student_number, incident_date, incident_description, incident_location, witnesses, severity, status, counselor_id, grade_level, program, section, created_at
      ''', insertData);

      final row = result.first;

      return Response(201, body: jsonEncode({
        'id': row[0],
        'student_name': row[1],
        'student_number': row[2],
        'incident_date': row[3] is DateTime ? (row[3] as DateTime).toIso8601String() : row[3].toString(),
        'incident_description': row[4],
        'incident_location': row[5],
        'witnesses': row[6],
        'severity': row[7],
        'status': row[8],
        'counselor_id': row[9],
        'grade_level': row[10],
        'program': row[11],
        'section': row[12],
        'created_at': row[13] is DateTime ? (row[13] as DateTime).toIso8601String() : row[13].toString(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create discipline case: $e'}),
      );
    }
  }

  Future<Response> updateCounselorDisciplineCase(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final counselorId = data['counselor_id'];

      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Verify counselor owns this case
      final caseCheck = await _database.query(
        'SELECT counselor_id FROM discipline_cases WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (caseCheck.isEmpty) {
        return Response(404, body: jsonEncode({'error': 'Discipline case not found'}));
      }

      if (caseCheck.first[0] != counselorId) {
        return Response(403, body: jsonEncode({'error': 'You can only update your own discipline cases'}));
      }

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
      if (data['grade_level'] != null) {
        updateFields.add('grade_level = @grade_level');
        params['grade_level'] = data['grade_level'];
      }
      if (data['program'] != null) {
        updateFields.add('program = @program');
        params['program'] = data['program'];
      }
      if (data['section'] != null) {
        updateFields.add('section = @section');
        params['section'] = data['section'];
      }
      if (data['incident_date'] != null) {
        updateFields.add('incident_date = @incident_date');
        params['incident_date'] = DateTime.parse(data['incident_date']);
      }
      if (data['severity'] != null) {
        updateFields.add('severity = @severity');
        params['severity'] = data['severity'];
      }
      if (data['incident_location'] != null) {
        updateFields.add('incident_location = @incident_location');
        params['incident_location'] = data['incident_location'];
      }
      if (data['incident_description'] != null) {
        updateFields.add('incident_description = @incident_description');
        params['incident_description'] = data['incident_description'];
      }
      if (data['witnesses'] != null) {
        updateFields.add('witnesses = @witnesses');
        params['witnesses'] = data['witnesses'];
      }
      if (data['status'] != null) {
        updateFields.add('status = @status');
        params['status'] = data['status'];
      }
      if (data['action_taken'] != null) {
        updateFields.add('action_taken = @action_taken');
        params['action_taken'] = data['action_taken'];
      }

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');

        if (data['status'] == 'resolved' || data['status'] == 'closed') {
          updateFields.add('resolved_at = NOW()');
          updateFields.add('resolved_by = @resolved_by');
          params['resolved_by'] = counselorId;
        }

        final updateQuery = 'UPDATE discipline_cases SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Discipline case updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update discipline case: $e'}),
      );
    }
  }

  // ================= RE-ADMISSION CASES ENDPOINTS =================

  Future<Response> getCounselorReAdmissionCases(Request request) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['counselor_id'] ?? '0');
      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Pagination parameters
      final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      final offset = (page - 1) * limit;

      // Get total count
      final totalResult = await _database.query('SELECT COUNT(*) FROM re_admission_cases');
      final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

      // Get paginated results
      final result = await _database.query('''
        SELECT
          rac.id,
          rac.student_name,
          rac.student_number,
          rac.reason_of_absence,
          rac.notes,
          rac.status,
          rac.counselor_id,
          rac.created_at,
          rac.updated_at,
          rac.reviewed_at,
          rac.reviewed_by,
          rac.date,
          u.username as counselor_name,
          ru.username as reviewed_by_name
        FROM re_admission_cases rac
        LEFT JOIN users u ON rac.counselor_id = u.id
        LEFT JOIN users ru ON rac.reviewed_by = ru.id
        ORDER BY rac.created_at DESC
        LIMIT @limit OFFSET @offset
      ''', {'limit': limit, 'offset': offset});

      final cases = result.map((row) => {
        'id': row[0],
        'student_name': row[1],
        'student_number': row[2],
        'reason_of_absence': row[3],
        'notes': row[4],
        'status': row[5],
        'counselor_id': row[6],
        'created_at': row[7] is DateTime ? (row[7] as DateTime).toIso8601String() : row[7]?.toString(),
        'updated_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'reviewed_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'reviewed_by': row[10],
        'date': row[11] is DateTime ? (row[11] as DateTime).toIso8601String() : row[11]?.toString(),
        'counselor_name': row[12],
        'reviewed_by_name': row[13],
      }).toList();

      return Response.ok(jsonEncode({
        'cases': cases,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': total != null ? ((total as int) / limit).ceil() : 0,
        }
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch re-admission cases: $e'}),
      );
    }
  }

  Future<Response> createCounselorReAdmissionCase(Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final counselorId = data['counselor_id'];

      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Validation
      if (data['student_name'] == null || data['student_name'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Student name is required'}));
      }
      if (data['student_number'] == null || data['student_number'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Student number is required'}));
      }
      if (data['reason_of_absence'] == null || data['reason_of_absence'].toString().isEmpty) {
        return Response(400, body: jsonEncode({'error': 'Reason of absence is required'}));
      }

      final insertData = {
        'student_name': data['student_name'],
        'student_number': data['student_number'],
        'reason_of_absence': data['reason_of_absence'],
        'notes': data['notes'],
        'status': data['status'] ?? 'pending',
        'counselor_id': counselorId,
        'created_at': data['created_at'] != null ? DateTime.parse(data['created_at']) : null,
        'date': data['date'] != null && data['date'].toString().isNotEmpty ? DateTime.parse(data['date'].toString()) : null,
      };

      final result = await _database.query('''
        INSERT INTO re_admission_cases (student_name, student_number, reason_of_absence, notes, status, counselor_id, created_at, date)
        VALUES (@student_name, @student_number, @reason_of_absence, @notes, @status, @counselor_id, COALESCE(@created_at, NOW()), @date)
        RETURNING id, student_name, student_number, reason_of_absence, notes, status, counselor_id, created_at, date
      ''', insertData);

      final row = result.first;

      return Response(201, body: jsonEncode({
        'id': row[0],
        'student_name': row[1],
        'student_number': row[2],
        'reason_of_absence': row[3],
        'notes': row[4],
        'status': row[5],
        'counselor_id': row[6],
        'created_at': row[7] is DateTime ? (row[7] as DateTime).toIso8601String() : row[7]?.toString(),
        'date': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create re-admission case: $e'}),
      );
    }
  }

  Future<Response> updateCounselorReAdmissionCase(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final counselorId = data['counselor_id'];

      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      // Verify counselor owns this case
      final caseCheck = await _database.query(
        'SELECT counselor_id FROM re_admission_cases WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (caseCheck.isEmpty) {
        return Response(404, body: jsonEncode({'error': 'Re-admission case not found'}));
      }

      if (caseCheck.first[0] != counselorId) {
        return Response(403, body: jsonEncode({'error': 'You can only update your own re-admission cases'}));
      }

      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['status'] != null) {
        updateFields.add('status = @status');
        params['status'] = data['status'];
      }
      if (data['notes'] != null) {
        updateFields.add('notes = @notes');
        params['notes'] = data['notes'];
      }
      if (data['reason_of_absence'] != null) {
        updateFields.add('reason_of_absence = @reason_of_absence');
        params['reason_of_absence'] = data['reason_of_absence'];
      }

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');

        if (data['status'] == 'approved' || data['status'] == 'rejected') {
          updateFields.add('reviewed_at = NOW()');
          updateFields.add('reviewed_by = @reviewed_by');
          params['reviewed_by'] = counselorId;
        }

        final updateQuery = 'UPDATE re_admission_cases SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Re-admission case updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update re-admission case: $e'}),
      );
    }
  }
}
