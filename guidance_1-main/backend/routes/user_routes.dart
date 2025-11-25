import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../connection.dart';

class UserRoutes {
  final DatabaseConnection _database;

  UserRoutes(this._database);

  // ================= USER MANAGEMENT ENDPOINTS =================

  Future<Response> login(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final email = data['email'];
      final password = data['password'];
      final studentId = data['student_id'];

      // Check if password is provided
      if (password == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Password is required'}),
        );
      }

      // Check if either email or student_id is provided
      if ((email == null || email.isEmpty) && (studentId == null || studentId.isEmpty)) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Either email or student ID is required'}),
        );
      }

      // Build query based on provided credentials
      String query = '''
        SELECT id, username, email, role, created_at,
               student_id, first_name, last_name
        FROM users
        WHERE password = @password
      ''';
      Map<String, dynamic> params = {'password': password};

      // Add email or student_id condition
      if (email != null && email.isNotEmpty) {
        query += ' AND email = @email';
        params['email'] = email;
      } else if (studentId != null && studentId.isNotEmpty) {
        query += ' AND student_id = @student_id';
        params['student_id'] = studentId;
      }

      final result = await _database.query(query, params);

      if (result.isEmpty) {
        return Response.unauthorized(
          jsonEncode({'error': 'Invalid email or password'}),
        );
      }

      final row = result.first;
      final username = row[1] ?? 'User';

      final responseData = {
        'id': row[0],
        'username': username,
        'email': row[2],
        'role': row[3],
        'created_at': row[4] is DateTime ? (row[4] as DateTime).toIso8601String() : row[4]?.toString(),
        'student_id': row[5], // Will be null for non-students
        'first_name': row[6], // Will be null for non-students
        'last_name': row[7], // Will be null for non-students
        'message': 'Login successful',
      };

      return Response.ok(jsonEncode(responseData));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Login failed: $e'}),
      );
    }
  }

  Future<Response> getAllUsers(Request request) async {
    try {
      final result = await _database.query('SELECT * FROM users ORDER BY id');
      final users = result.map((row) => {
        'id': row[0],
        'username': row[1],
        'email': row[2],
        'role': row[3],
        'created_at': row[4] is DateTime ? (row[4] as DateTime).toIso8601String() : row[4]?.toString(),
      }).toList();

      return Response.ok(jsonEncode({'users': users}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch users: $e'}),
      );
    }
  }

  Future<Response> getUserById(Request request, String id) async {
    try {
      final result = await _database.query(
        'SELECT id, username, email, role, created_at, student_id, first_name, last_name FROM users WHERE id = @id',
        {'id': int.parse(id)},
      );

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
        );
      }

      final user = result.first;
      return Response.ok(jsonEncode({
        'id': user[0],
        'username': user[1],
        'email': user[2],
        'role': user[3],
        'created_at': user[4] is DateTime ? (user[4] as DateTime).toIso8601String() : user[4]?.toString(),
        'student_id': user[5], // Include student-specific fields
        'first_name': user[6],
        'last_name': user[7],
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch user: $e'}),
      );
    }
  }

  Future<Response> createUser(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      final role = data['role'] ?? 'student';

      // Prepare user data
      final userData = {
        'username': data['username'],
        'email': data['email'],
        'password': data['password'], // In production, hash this!
        'role': role,
      };

      // Add student-specific fields if role is student
      if (role == 'student') {
        userData.addAll({
          'student_id': data['student_id'] ?? 'STU${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}', // Use provided student_id or generate unique one
          'first_name': data['first_name'] ?? data['username'], // Use provided first_name or fallback to username
          'last_name': data['last_name'] ?? '', // Use provided last_name or empty
        });
      }

      // Insert into users table (now includes all student data)
      final userResult = await _database.query(
        '''
        INSERT INTO users (username, email, password, role, student_id, first_name, last_name)
        VALUES (@username, @email, @password, @role, @student_id, @first_name, @last_name)
        RETURNING id, username, email, role, created_at, student_id, first_name, last_name
        ''',
        userData,
      );

      final userRow = userResult.first;
      final responseData = {
        'id': userRow[0],
        'username': userRow[1],
        'email': userRow[2],
        'role': userRow[3],
        'created_at': userRow[4] is DateTime ? (userRow[4] as DateTime).toIso8601String() : userRow[4]?.toString(),
        'student_id': userRow[5], // null for non-students
        'first_name': userRow[6], // null for non-students
        'last_name': userRow[7], // null for non-students
        'message': 'User created successfully. Please login to continue.',
        'requires_login': true,
      };

      return Response.ok(jsonEncode(responseData));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create user: $e'}),
      );
    }
  }

  Future<Response> updateUser(Request request, String id) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      await _database.execute(
        'UPDATE users SET username = @username, email = @email, role = @role WHERE id = @id',
        {
          'id': int.parse(id),
          'username': data['username'],
          'email': data['email'],
          'role': data['role'],
        },
      );

      return Response.ok(jsonEncode({'message': 'User updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update user: $e'}),
      );
    }
  }

  Future<Response> deleteUser(Request request, String id) async {
    try {
      await _database.execute(
        'DELETE FROM users WHERE id = @id',
        {'id': int.parse(id)},
      );

      return Response.ok(jsonEncode({'message': 'User deleted successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to delete user: $e'}),
      );
    }
  }

  Future<Response> getAllStudents(Request request) async {
    try {
      final result = await _database.query('''
        SELECT id, username, email, role, created_at,
               student_id, first_name, last_name, status, program
        FROM users
        WHERE role = 'student'
        ORDER BY last_name, first_name
      ''');

      final students = result.map((row) => {
        'user_id': row[0],
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

      return Response.ok(jsonEncode({'students': students}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch students: $e'}),
      );
    }
  }

  Future<Response> getStudentById(Request request, String id) async {
    try {
      final result = await _database.query('''
        SELECT id, username, email, role, created_at,
               student_id, first_name, last_name
        FROM users
        WHERE id = @id AND role = 'student'
      ''', {'id': int.parse(id)});

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Student not found'}),
        );
      }

      final student = result.first;
      return Response.ok(jsonEncode({
        'user_id': student[0],
        'username': student[1],
        'email': student[2],
        'role': student[3],
        'created_at': student[4] is DateTime ? (student[4] as DateTime).toIso8601String() : student[4]?.toString(),
        'student_id': student[5],
        'first_name': student[6],
        'last_name': student[7],
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch student: $e'}),
      );
    }
  }
}
