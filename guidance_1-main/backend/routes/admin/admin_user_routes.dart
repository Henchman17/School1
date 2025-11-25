import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:bcrypt/bcrypt.dart';
import 'admin_route_helpers.dart';

class AdminUserRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminUserRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= DASHBOARD ENDPOINTS =================

  Future<Response> getAdminDashboard(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _helpers.checkUserRole(userId, 'admin')) {
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

      // Get exit interview statistics directly from exit_interviews table
      final totalExitInterviewsResult = await _database.query('SELECT COUNT(*) FROM exit_interviews');

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

      // Get recent activity - students with most recent appointments
      final recentActivityResult = await _database.query('''
        SELECT DISTINCT
          s.id,
          s.first_name,
          s.last_name,
          s.status,
          s.program,
          MAX(a.appointment_date) as last_appointment_date,
          c.username as counselor_name,
          a.purpose,
          a.apt_status
        FROM users s
        JOIN appointments a ON s.id = a.student_id
        LEFT JOIN users c ON a.counselor_id = c.id
        WHERE s.role = 'student'
        GROUP BY s.id, s.first_name, s.last_name, s.status, s.program, c.username, a.purpose, a.apt_status
        ORDER BY MAX(a.appointment_date) DESC
        LIMIT 10
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
        'exit_interview_statistics': {
          'total_exit_interviews': totalExitInterviewsResult.isNotEmpty ? totalExitInterviewsResult.first[0] : 0,
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
        'recent_activity': recentActivityResult.map((row) => {
          'student_id': row[0],
          'first_name': row[1],
          'last_name': row[2],
          'status': row[3],
          'program': row[4],
          'last_appointment_date': row[5] is DateTime ? (row[5] as DateTime).toIso8601String() : row[5]?.toString(),
          'counselor_name': row[6],
          'purpose': row[7],
          'appointment_status': row[8],
        }).toList(),
      }));
    } catch (e) {
      print('Error in getAdminDashboard: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch admin dashboard: $e'}),
      );
    }
  }

  // ================= USER MANAGEMENT ENDPOINTS =================

  Future<Response> getAdminUsers(Request request) async {
    try {
      final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');
      if (!await _helpers.checkUserRole(userId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Pagination parameters
      final page = int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      final limit = int.tryParse(request.url.queryParameters['limit'] ?? '10') ?? 10;
      final offset = (page - 1) * limit;

      // Get total count
      final totalResult = await _database.query('SELECT COUNT(*) FROM users');
      final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

      // Get paginated results
      final result = await _database.query('''
        SELECT id, username, email, role, created_at, student_id, first_name, last_name, status, program
        FROM users
        ORDER BY role, created_at DESC
        LIMIT @limit OFFSET @offset
      ''', {'limit': limit, 'offset': offset});

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

      return Response.ok(jsonEncode({
        'users': users,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': (total / limit).ceil(),
        }
      }));
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

        userData.addAll({
          'student_id': studentId,
          'first_name': data['first_name']?.toString().trim() ?? username,
          'last_name': data['last_name']?.toString().trim() ?? '',
          'status': data['status']?.toString().trim() ?? 'Unknown',
          'program': data['program']?.toString().trim() ?? 'Unknown',
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

      return Response(200, body: jsonEncode({
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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
}
