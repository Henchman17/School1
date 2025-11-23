import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:backend/document_generator.dart';

class AdminRoutes {
  final dynamic _database;

  AdminRoutes(this._database);

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

  // ================= ADMIN ENDPOINTS =================

  Future<Response> getAdminDashboard(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _checkUserRole(userId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get user statistics directly from users table
      final totalUsersResult = await _database.query('SELECT COUNT(*) FROM users');
      final adminCountResult = await _database.query("SELECT COUNT(*) FROM users WHERE role = 'admin'");
      final counselorCountResult = await _database.query("SELECT COUNT(*) FROM users WHERE role = 'counselor'");
      final studentCountResult = await _database.query("SELECT COUNT(*) FROM users WHERE role = 'student'");
      final newUsers30DaysResult = await _database.query("SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'");
      final newUsers7DaysResult = await _database.query("SELECT COUNT(*) FROM users WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'");
      final newUsersTodayResult = await _database.query("SELECT COUNT(*) FROM users WHERE role = 'student' AND created_at >= CURRENT_DATE");

      // Get appointment statistics directly from appointments table
      final totalAppointmentsResult = await _database.query('SELECT COUNT(*) FROM appointments');
      final scheduledCountResult = await _database.query("SELECT COUNT(*) FROM appointments WHERE apt_status = 'scheduled'");
      final completedCountResult = await _database.query("SELECT COUNT(*) FROM appointments WHERE apt_status = 'completed'");
      final cancelledCountResult = await _database.query("SELECT COUNT(*) FROM appointments WHERE apt_status = 'cancelled'");
      final upcomingCountResult = await _database.query('SELECT COUNT(*) FROM appointments WHERE appointment_date >= CURRENT_DATE');
      final overdueCountResult = await _database.query("SELECT COUNT(*) FROM appointments WHERE appointment_date < CURRENT_DATE AND apt_status = 'scheduled'");
      final avgDaysResult = await _database.query("SELECT AVG(EXTRACT(EPOCH FROM (appointment_date - created_at))/86400) FROM appointments WHERE appointment_date > created_at");
      final appointments30DaysResult = await _database.query("SELECT COUNT(*) FROM appointments WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'");

      // Get counselor workload directly
      final counselorWorkloadResult = await _database.query('''
        SELECT
          u.id as counselor_id,
          u.username as counselor_name,
          u.email as counselor_email,
          COUNT(a.id) as total_appointments,
          COUNT(CASE WHEN a.apt_status = 'scheduled' THEN 1 END) as scheduled_appointments,
          COUNT(CASE WHEN a.apt_status = 'completed' THEN 1 END) as completed_appointments,
          COUNT(CASE WHEN a.appointment_date >= CURRENT_DATE THEN 1 END) as upcoming_appointments,
          COUNT(CASE WHEN a.appointment_date < CURRENT_DATE AND a.apt_status = 'scheduled' THEN 1 END) as overdue_appointments
        FROM users u
        LEFT JOIN appointments a ON u.id = a.counselor_id
        WHERE u.role = 'counselor'
        GROUP BY u.id, u.username, u.email
      ''');

      final newUsersTodayCount = newUsersTodayResult.isNotEmpty ? newUsersTodayResult.first[0] : 0;

      return Response.ok(jsonEncode({
        'user_statistics': {
          'total_users': totalUsersResult.isNotEmpty ? totalUsersResult.first[0] : 0,
          'admin_count': adminCountResult.isNotEmpty ? adminCountResult.first[0] : 0,
          'counselor_count': counselorCountResult.isNotEmpty ? counselorCountResult.first[0] : 0,
          'student_count': studentCountResult.isNotEmpty ? studentCountResult.first[0] : 0,
          'new_users_30_days': newUsers30DaysResult.isNotEmpty ? newUsers30DaysResult.first[0] : 0,
          'new_users_7_days': newUsers7DaysResult.isNotEmpty ? newUsers7DaysResult.first[0] : 0,
          'new_users_today': newUsersTodayResult.isNotEmpty ? newUsersTodayResult.first[0] : 0,
        },
        'appointment_statistics': {
          'total_appointments': totalAppointmentsResult.isNotEmpty ? totalAppointmentsResult.first[0] : 0,
          'scheduled_count': scheduledCountResult.isNotEmpty ? scheduledCountResult.first[0] : 0,
          'completed_count': completedCountResult.isNotEmpty ? completedCountResult.first[0] : 0,
          'cancelled_count': cancelledCountResult.isNotEmpty ? cancelledCountResult.first[0] : 0,
          'upcoming_count': upcomingCountResult.isNotEmpty ? upcomingCountResult.first[0] : 0,
          'overdue_count': overdueCountResult.isNotEmpty ? overdueCountResult.first[0] : 0,
          'avg_days_to_appointment': avgDaysResult.isNotEmpty && avgDaysResult.first[0] != null ? avgDaysResult.first[0] : 0,
          'appointments_30_days': appointments30DaysResult.isNotEmpty ? appointments30DaysResult.first[0] : 0,
        },
        'counselor_workload': counselorWorkloadResult.map((row) => {
          'counselor_id': row[0],
          'counselor_name': row[1],
          'counselor_email': row[2],
          'total_appointments': row[3],
          'scheduled_appointments': row[4],
          'completed_appointments': row[5],
          'upcoming_appointments': row[6],
          'overdue_appointments': row[7],
        }).toList(),
      }));
    } catch (e) {
      print('Error in getAdminDashboard: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch admin dashboard: $e'}),
      );
    }
  }

  Future<Response> getAdminUsers(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _checkUserRole(userId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final result = await _database.query('''
        SELECT id, username, email, role, created_at, student_id, first_name, last_name, status, program
        FROM users
        ORDER BY role, created_at DESC
      ''');

      final users = result.map((row) => {
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

      return Response.ok(jsonEncode({'users': users}));
    } catch (e, stackTrace) {
      print('Error in getAdminUsers: $e');
      print('Stack trace: $stackTrace');
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Failed to fetch users: $e',
          'details': stackTrace.toString()
        }),
      );
    }
  }

  Future<Response> createAdminUser(Request request) async {
    try {
      // Parse request body
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }

      // Validate admin access
      final adminId = data['admin_id'];
      if (adminId == null) {
        return Response(400, body: jsonEncode({'error': 'Admin ID is required'}));
      }

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Validate required fields
      final requiredFields = ['username', 'email', 'password'];
      for (final field in requiredFields) {
        if (data[field] == null || data[field].toString().trim().isEmpty) {
          return Response(400, body: jsonEncode({'error': '$field is required'}));
        }
      }

      final username = data['username'].toString().trim();
      final email = data['email'].toString().trim().toLowerCase();
      final password = data['password'].toString();

      // Validate email format
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(email)) {
        return Response(400, body: jsonEncode({'error': 'Invalid email format'}));
      }

      // Validate password strength
      if (password.length < 8) {
        return Response(400, body: jsonEncode({'error': 'Password must be at least 8 characters long'}));
      }

      // Check for existing username
      final existingUsername = await _database.query(
        'SELECT id FROM users WHERE username = @username',
        {'username': username},
      );
      if (existingUsername.isNotEmpty) {
        return Response(409, body: jsonEncode({'error': 'Username already exists'}));
      }

      // Check for existing email
      final existingEmail = await _database.query(
        'SELECT id FROM users WHERE email = @email',
        {'email': email},
      );
      if (existingEmail.isNotEmpty) {
        return Response(409, body: jsonEncode({'error': 'Email already exists'}));
      }

      // Validate role
      final role = data['role'] ?? 'student';
      final validRoles = ['admin', 'counselor', 'student'];
      if (!validRoles.contains(role)) {
        return Response(400, body: jsonEncode({'error': 'Invalid role. Must be one of: ${validRoles.join(', ')}'}));
      }

      // Hash the password using bcrypt
      final hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt());

      // Prepare user data
      final userData = {
        'username': username,
        'email': email,
        'password': hashedPassword,
        'role': role,
      };

      // Add role-specific fields
      if (role == 'student') {
        final studentId = data['student_id']?.toString().trim() ??
            'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

        // Check for existing student_id if provided
        if (data['student_id'] != null) {
          final existingStudentId = await _database.query(
            'SELECT id FROM users WHERE student_id = @student_id',
            {'student_id': studentId},
          );
          if (existingStudentId.isNotEmpty) {
            return Response(409, body: jsonEncode({'error': 'Student ID already exists'}));
          }
        }

        // Validate program against courses table if provided
        final program = data['program']?.toString().trim();
        if (program != null && program.isNotEmpty && program != 'Unknown') {
          final existingCourse = await _database.query(
            'SELECT id FROM courses WHERE course_name = @course_name AND is_active = true',
            {'course_name': program},
          );
          if (existingCourse.isEmpty) {
            return Response(400, body: jsonEncode({'error': 'Invalid program. Program must match an existing course from the courses table'}));
          }
        }

        userData.addAll({
          'student_id': studentId,
          'first_name': data['first_name']?.toString().trim() ?? username,
          'last_name': data['last_name']?.toString().trim() ?? '',
          'status': data['status']?.toString().trim() ?? 'Unknown',
          'program': program ?? 'Unknown',
        });
      } else {
        userData.addAll({
          'student_id': null,
          'first_name': null,
          'last_name': null,
          'status': null,
          'program': null,
        });
      }

      // Insert user into database
      final userResult = await _database.query('''
        INSERT INTO users (username, email, password, role, student_id, first_name, last_name, status, program)
        VALUES (@username, @email, @password, @role, @student_id, @first_name, @last_name, @status, @program)
        RETURNING id, username, email, role, created_at, student_id, first_name, last_name, status, program
      ''', userData);

      if (userResult.isEmpty) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to create user'}),
        );
      }

      final userRow = userResult.first;

      return Response(201, body: jsonEncode({
        'id': userRow[0],
        'username': userRow[1],
        'email': userRow[2],
        'role': userRow[3],
        'created_at': userRow[4]?.toIso8601String(),
        'student_id': userRow[5],
        'first_name': userRow[6],
        'last_name': userRow[7],
        'status': userRow[8],
        'program': userRow[9],
        'message': 'User created successfully by admin',
      }));
    } catch (e) {
      print('Error in createAdminUser: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create user: $e'}),
      );
    }
  }

  Future<Response> updateAdminUser(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Build update query
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['username'] != null) {
        updateFields.add('username = @username');
        params['username'] = data['username'];
      }
      if (data['email'] != null) {
        updateFields.add('email = @email');
        params['email'] = data['email'];
      }
      if (data['role'] != null) {
        updateFields.add('role = @role');
        params['role'] = data['role'];
      }
      if (data['student_id'] != null) {
        updateFields.add('student_id = @student_id');
        params['student_id'] = data['student_id'];
      }
      if (data['first_name'] != null) {
        updateFields.add('first_name = @first_name');
        params['first_name'] = data['first_name'];
      }
      if (data['last_name'] != null) {
        updateFields.add('last_name = @last_name');
        params['last_name'] = data['last_name'];
      }
      if (data['status'] != null) {
        updateFields.add('status = @status');
        params['status'] = data['status'];
      }
      if (data['program'] != null) {
        updateFields.add('program = @program');
        params['program'] = data['program'];
      }

      if (updateFields.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'No fields to update'}));
      }

      final updateQuery = 'UPDATE users SET ${updateFields.join(', ')} WHERE id = @id';
      await _database.execute(updateQuery, params);

      return Response.ok(jsonEncode({'message': 'User updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update user: $e'}),
      );
    }
  }

  Future<Response> deleteAdminUser(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Delete user
      await _database.execute('DELETE FROM users WHERE id = @id', {'id': int.parse(id)});

      return Response.ok(jsonEncode({'message': 'User deleted successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete user: $e'}),
      );
    }
  }

  Future<Response> getAdminAppointments(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
        ORDER BY a.appointment_date DESC
      ''');

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

  Future<Response> getAdminAnalytics(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
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

  // ================= COUNSELOR ENDPOINTS =================

  Future<Response> getCounselorDashboard(Request request) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['counselor_id'] ?? '0');
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
        }).toList(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch counselor dashboard: $e'}),
      );
    }
  }

  Future<Response> getCounselorStudents(Request request) async {
    try {
      final counselorId = int.parse(request.url.queryParameters['counselor_id'] ?? '0');
      if (!await _checkUserRole(counselorId, 'counselor')) {
        return Response.forbidden(jsonEncode({'error': 'Counselor access required'}));
      }

      final result = await _database.query('''
        SELECT DISTINCT
          s.id,
          s.username,
          s.email,
          s.student_id,
          s.first_name,
          s.last_name,
          s.status,
          s.program,
          COUNT(a.id) as total_appointments,
          MAX(a.appointment_date) as last_appointment
        FROM users s
        LEFT JOIN appointments a ON s.id = a.student_id AND a.counselor_id = @counselor_id
        WHERE s.role = 'student'
        GROUP BY s.id, s.username, s.email, s.student_id, s.first_name, s.last_name, s.status, s.program
        ORDER BY s.last_name, s.first_name
      ''', {'counselor_id': counselorId});

      final students = result.map((row) => {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'student_id': row[3],
        'first_name': row[4],
        'last_name': row[5],
        'status': row[6],
        'program': row[7],
        'total_appointments': row[8],
        'last_appointment': row[9]?.toString(),
      }).toList();

      return Response.ok(jsonEncode({'students': students}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch students: $e'}),
      );
    }
  }

  Future<Response> updateCounselorAppointment(Request request, String id) async {
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

      // Verify counselor owns this appointment
      final appointmentCheck = await _database.query(
        'SELECT counselor_id FROM appointments WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (appointmentCheck.isEmpty) {
        return Response(404, body: jsonEncode({'error': 'Appointment not found'}));
      }

      if (appointmentCheck.first[0] != counselorId) {
        return Response(403, body: jsonEncode({'error': 'You can only update your own appointments'}));
      }

      // Build update query
      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      if (data['appointment_date'] != null) {
        updateFields.add('appointment_date = @appointment_date');
        params['appointment_date'] = DateTime.parse(data['appointment_date']);
      }
      if (data['purpose'] != null) {
        updateFields.add('purpose = @purpose');
        params['purpose'] = data['purpose'];
      }
      if (data['course'] != null) {
        updateFields.add('course = @course');
        params['course'] = data['course'];
      }
      if (data['status'] != null) {
        updateFields.add('apt_status = @apt_status');
        params['apt_status'] = data['status'];
      }
      if (data['notes'] != null) {
        updateFields.add('notes = @notes');
        params['notes'] = data['notes'];
      }

      if (updateFields.isEmpty) {
        return Response(400, body: jsonEncode({'error': 'No fields to update'}));
      }

      final updateQuery = 'UPDATE appointments SET ${updateFields.join(', ')} WHERE id = @id';
      await _database.execute(updateQuery, params);

      return Response.ok(jsonEncode({'message': 'Appointment updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update appointment: $e'}),

      );
    }
  }

  // ================= CASE MANAGEMENT ENDPOINTS =================

  // Re-admission Cases
  Future<Response> getReAdmissionCases(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

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
      ''');

      final cases = result.map((row) => {
        'id': row[0],
        'student_name': row[1],
        'student_number': row[2],
        'reason_of_absence': row[3],
        'notes': row[4],
        'status': row[5],
        'counselor_id': row[6],
        'created_at': row[7]?.toIso8601String(),
        'updated_at': row[8]?.toIso8601String(),
        'reviewed_at': row[9]?.toIso8601String(),
        'reviewed_by': row[10],
        'date': row[11]?.toIso8601String(),
        'counselor_name': row[12],
        'reviewed_by_name': row[13],
      }).toList();

      return Response.ok(jsonEncode({'cases': cases}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch re-admission cases: $e'}),
      );
    }
  }

  Future<Response> createReAdmissionCase(Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
        'counselor_id': data['counselor_id'] ?? data['admin_id'], // Accept admin_id as counselor_id for admin-created cases
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
        'created_at': row[7]?.toIso8601String(),
        'date': row[8]?.toIso8601String(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create re-admission case: $e'}),
      );
    }
  }

  Future<Response> updateReAdmissionCase(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
      if (data['counselor_id'] != null) {
        updateFields.add('counselor_id = @counselor_id');
        params['counselor_id'] = data['counselor_id'];
      }

      if (updateFields.isNotEmpty) {
        updateFields.add('reviewed_at = NOW()');
        updateFields.add('reviewed_by = @reviewed_by');
        params['reviewed_by'] = adminId;

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

  // Discipline Cases
  Future<Response> getDisciplineCases(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
        'incident_date': row[3]?.toIso8601String(),
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
        'created_at': row[15]?.toIso8601String(),
        'updated_at': row[16]?.toIso8601String(),
        'resolved_at': row[17]?.toIso8601String(),
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

  Future<Response> createDisciplineCase(Request request) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
        'counselor_id': data['counselor_id'] ?? adminId,
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
        'incident_date': row[3]?.toIso8601String(),
        'incident_description': row[4],
        'incident_location': row[5],
        'witnesses': row[6],
        'severity': row[7],
        'status': row[8],
        'counselor_id': row[9],
        'grade_level': row[10],
        'program': row[11],
        'section': row[12],
        'created_at': row[13]?.toIso8601String(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create discipline case: $e'}),
      );
    }
  }

  Future<Response> updateDisciplineCase(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
      if (data['admin_notes'] != null) {
        updateFields.add('admin_notes = @admin_notes');
        params['admin_notes'] = data['admin_notes'];
      }
      if (data['action_taken'] != null) {
        updateFields.add('action_taken = @action_taken');
        params['action_taken'] = data['action_taken'];
      }
      if (data['counselor_id'] != null) {
        updateFields.add('counselor_id = @counselor_id');
        params['counselor_id'] = data['counselor_id'];
      }

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');

        if (data['status'] == 'resolved' || data['status'] == 'closed') {
          updateFields.add('resolved_at = NOW()');
          updateFields.add('resolved_by = @resolved_by');
          params['resolved_by'] = adminId;
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

  // Exit Interviews
  Future<Response> getExitInterviews(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final result = await _database.query('''
        SELECT
          ei.id,
          ei.student_id,
          ei.student_name,
          ei.student_number,
          ei.interview_type,
          ei.interview_date,
          ei.reason_for_leaving,
          ei.satisfaction_rating,
          ei.academic_experience,
          ei.support_services_experience,
          ei.facilities_experience,
          ei.overall_improvements,
          ei.future_plans,
          ei.contact_info,
          ei.status,
          ei.admin_notes,
          ei.counselor_id,
          ei.created_at,
          ei.updated_at,
          ei.completed_at,
          u.username as counselor_name
        FROM exit_interviews ei
        LEFT JOIN users u ON ei.counselor_id = u.id
        ORDER BY ei.created_at DESC
      ''');

      final interviews = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'student_number': row[3],
        'interview_type': row[4],
        'interview_date': row[5]?.toIso8601String(),
        'reason_for_leaving': row[6],
        'satisfaction_rating': row[7],
        'academic_experience': row[8],
        'support_services_experience': row[9],
        'facilities_experience': row[10],
        'overall_improvements': row[11],
        'future_plans': row[12],
        'contact_info': row[13],
        'status': row[14],
        'admin_notes': row[15],
        'counselor_id': row[16],
        'created_at': row[17]?.toIso8601String(),
        'updated_at': row[18]?.toIso8601String(),
        'completed_at': row[19]?.toIso8601String(),
        'counselor_name': row[20],
      }).toList();

      return Response.ok(jsonEncode({'interviews': interviews}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch exit interviews: $e'}),
      );
    }
  }

  Future<Response> updateExitInterview(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = data['admin_id'];

      if (!await _checkUserRole(adminId, 'admin')) {
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
      if (data['counselor_id'] != null) {
        updateFields.add('counselor_id = @counselor_id');
        params['counselor_id'] = data['counselor_id'];
      }

      if (updateFields.isNotEmpty) {
        if (data['status'] == 'completed') {
          updateFields.add('completed_at = NOW()');
        }

        final updateQuery = 'UPDATE exit_interviews SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Exit interview updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update exit interview: $e'}),
      );
    }
  }

  // Get Case Summary for Dashboard
  Future<Response> getCaseSummary(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
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

  // ================= CREDENTIAL CHANGE REQUESTS ENDPOINTS =================

  Future<Response> getCredentialChangeRequests(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
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
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');

      if (!await _checkUserRole(adminId, 'admin')) {
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

      if (!await _checkUserRole(adminId, 'admin')) {
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

  // ================= RECENT ACTIVITIES ENDPOINTS =================

  Future<Response> getRecentActivities(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
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

  // ================= FORMS MANAGEMENT ENDPOINTS =================

  Future<Response> getAdminForms(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get SCRF forms
      final scrfResult = await _database.query('''
        SELECT
          'scrf' as form_type,
          s.id as form_id,
          s.user_id,
          s.student_id,
          CONCAT(u.first_name, ' ', u.last_name) as student_name,
          u.student_id as student_number,
          s.program_enrolled,
          s.created_at as submitted_at,
          s.updated_at as reviewed_at,
          'completed' as status,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM student_cumulative_records s
        JOIN users u ON s.user_id = u.id
        ORDER BY s.created_at DESC
      ''');

      // Get Routine Interview forms
      final riResult = await _database.query('''
        SELECT
          'routine_interview' as form_type,
          ri.id as form_id,
          ri.student_id as user_id,
          u.student_id,
          CONCAT(u.first_name, ' ', u.last_name) as student_name,
          u.student_id as student_number,
          ri.grade_course_year_section as program_enrolled,
          ri.created_at as submitted_at,
          ri.updated_at as reviewed_at,
          CASE
            WHEN ri.applicant_signature IS NOT NULL AND ri.applicant_signature != '' THEN 'completed'
            ELSE 'pending'
          END as status,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM routine_interviews ri
        JOIN users u ON ri.student_id = u.id
        ORDER BY ri.created_at DESC
      ''');

      // Get Good Moral Request forms
      final gmrResult = await _database.query('''
        SELECT
          'good_moral_request' as form_type,
          gmr.id as form_id,
          gmr.student_id as user_id,
          u.student_id,
          gmr.student_name,
          gmr.student_number,
          gmr.course as program_enrolled,
          gmr.created_at as submitted_at,
          gmr.updated_at as reviewed_at,
          gmr.status,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM good_moral_requests gmr
        JOIN users u ON gmr.student_id = u.id
        ORDER BY gmr.created_at DESC
      ''');

      // Combine results
      final forms = [];

      // Add SCRF forms
      for (final row in scrfResult) {
        forms.add({
          'form_type': row[0],
          'form_id': row[1],
          'user_id': row[2],
          'student_id': row[3],
          'student_name': row[4],
          'student_number': row[5],
          'program_enrolled': row[6],
          'submitted_at': row[7]?.toIso8601String(),
          'reviewed_at': row[8]?.toIso8601String(),
          'status': row[9],
          'first_name': row[10],
          'last_name': row[11],
          'student_status': row[12],
          'program': row[13],
        });
      }

      // Add Routine Interview forms
      for (final row in riResult) {
        forms.add({
          'form_type': row[0],
          'form_id': row[1],
          'user_id': row[2],
          'student_id': row[3],
          'student_name': row[4],
          'student_number': row[5],
          'program_enrolled': row[6],
          'submitted_at': row[7]?.toIso8601String(),
          'reviewed_at': row[8]?.toIso8601String(),
          'status': row[9],
          'first_name': row[10],
          'last_name': row[11],
          'student_status': row[12],
          'program': row[13],
        });
      }

      // Add Good Moral Request forms
      for (final row in gmrResult) {
        forms.add({
          'form_type': row[0],
          'form_id': row[1],
          'user_id': row[2],
          'student_id': row[3],
          'student_name': row[4],
          'student_number': row[5],
          'program_enrolled': row[6],
          'submitted_at': row[7]?.toIso8601String(),
          'reviewed_at': row[8]?.toIso8601String(),
          'status': row[9],
          'first_name': row[10],
          'last_name': row[11],
          'student_status': row[12],
          'program': row[13],
        });
      }

      return Response.ok(jsonEncode({'forms': forms}));
    } catch (e) {
      print('Error in getAdminForms: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch forms: $e'}),
      );
    }
  }

  // ================= GOOD MORAL REQUEST ENDPOINTS =================

  Future<Response> getGoodMoralRequests(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
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
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if request exists and get request details
      final existingRequest = await _database.query(
        'SELECT id, student_name, student_number, course, year_level, purpose, ocr_data FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      final requestData = existingRequest.first;
      final studentName = requestData[1] as String;
      final studentNumber = requestData[2] as String;
      final course = requestData[3] as String;
      final yearLevel = requestData[4] as String;
      final purpose = requestData[5] as String;
      Map<String, dynamic> ocrData = {};
      if (requestData[6] != null) {
        try {
          ocrData = (jsonDecode(requestData[6] as String) as Map).cast<String, dynamic>();
        } catch (e) {
          // Use empty map if invalid JSON
        }
      }

      // Update status to approved
      await _database.execute(
        'UPDATE good_moral_requests SET status = @status, updated_at = NOW() WHERE id = @id',
        {'status': 'approved', 'id': int.parse(id)},
      );

      // Generate PDF certificate
      final certificatePath = await BackendDocumentGenerator.generateGoodMoralCertificate(
        int.parse(id),
        ocrData,
        studentName,
        studentNumber,
        course,
        yearLevel,
        purpose,
      );

      if (certificatePath == null) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Request approved but failed to generate certificate'}),
        );
      }

      return Response.ok(jsonEncode({
        'message': 'Good moral request approved successfully',
        'certificate_path': certificatePath
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to approve good moral request: $e'}),
      );    }
  }

  Future<Response> rejectGoodMoralRequest(Request request, String id) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if request exists
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (existingRequest.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Good moral request not found'}));
      }

      // Update status to rejected
      await _database.execute(
        'UPDATE good_moral_requests SET status = @status, updated_at = NOW() WHERE id = @id',
        {'status': 'rejected', 'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'Good moral request rejected successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to reject good moral request: $e'}),
      );
    }
  }
}
