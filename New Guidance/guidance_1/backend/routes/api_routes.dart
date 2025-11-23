import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:bcrypt/bcrypt.dart';
import '../connection.dart';
import 'counselor_routes_updated.dart';
import 'admin_routes.dart';

class ApiRoutes {
  final DatabaseConnection _database;
  late final CounselorRoutes counselorRoutes;
  late final AdminRoutes adminRoutes;
  late final Router router;

  ApiRoutes(this._database) {
    counselorRoutes = CounselorRoutes(_database);
    adminRoutes = AdminRoutes(_database);
    _setupRoutes();
  }

  void _setupRoutes() {
    router = Router();

    // Health check
    router.get('/health', healthCheck);

    // User routes
    router.post('/api/users/login', login);
    router.get('/api/users', getAllUsers);
    router.get('/api/users/<id>', getUserById);
    router.post('/api/users', createUser);
    router.put('/api/users/<id>', updateUser);
    router.delete('/api/users/<id>', deleteUser);

    // Guidance system specific routes
    router.get('/api/students', getAllStudents);
    router.get('/api/students/<id>', getStudentById);
    router.post('/api/appointments', createAppointment);
    router.get('/api/appointments', getAppointments);
    router.put('/api/appointments/<id>', updateAppointment);
    router.delete('/api/appointments/<id>', deleteAppointment);
    router.get('/api/courses', getCourses);

    // JOIN examples for signup process
    router.get('/api/examples/join-signup', getSignupJoinExamples);

    // Routine Interview routes
    router.post('/api/routine-interviews', createRoutineInterview);
    router.get('/api/routine-interviews/<userId>', getRoutineInterview);
    router.put('/api/routine-interviews/<userId>', updateRoutineInterview);

    // Credential Change Request routes
    router.post('/api/credential-change-requests', createCredentialChangeRequest);
    router.get('/api/credential-change-requests/<userId>', getUserCredentialChangeRequests);

    // Counselor routes
    router.get('/api/counselor/dashboard', counselorRoutes.getCounselorDashboard);
    router.get('/api/counselor/students', counselorRoutes.getCounselorStudents);
    router.get('/api/counselor/students/<studentId>/profile', counselorRoutes.getStudentProfile);
    router.get('/api/counselor/appointments', counselorRoutes.getCounselorAppointments);
    router.get('/api/counselor/sessions', counselorRoutes.getCounselorSessions);
    router.put('/api/counselor/appointments/<id>/complete', counselorRoutes.completeAppointment);
    router.put('/api/counselor/appointments/<id>/confirm', counselorRoutes.confirmAppointment);
    router.put('/api/counselor/appointments/<id>/approve', counselorRoutes.approveAppointment);
    router.put('/api/counselor/appointments/<id>/reject', counselorRoutes.rejectAppointment);
    router.put('/api/counselor/appointments/<id>/cancel', counselorRoutes.cancelAppointment);
    router.delete('/api/counselor/appointments/<id>', counselorRoutes.deleteAppointment);
    router.get('/api/counselor/guidance-schedules', counselorRoutes.getCounselorGuidanceSchedules);
    router.put('/api/counselor/guidance-schedules/<id>/approve', counselorRoutes.approveGuidanceSchedule);
    router.put('/api/counselor/guidance-schedules/<id>/reject', counselorRoutes.rejectGuidanceSchedule);

    // Admin routes
    router.get('/api/admin/dashboard', adminRoutes.getAdminDashboard);
    router.get('/api/admin/users', adminRoutes.getAdminUsers);
    router.post('/api/admin/users', adminRoutes.createAdminUser);
    router.put('/api/admin/users/<id>', adminRoutes.updateAdminUser);
    router.delete('/api/admin/users/<id>', adminRoutes.deleteAdminUser);
    router.get('/api/admin/appointments', adminRoutes.getAdminAppointments);
    router.get('/api/admin/analytics', adminRoutes.getAdminAnalytics);
    router.get('/api/admin/case-summary', adminRoutes.getCaseSummary);
    router.get('/api/admin/re-admission-cases', adminRoutes.getReAdmissionCases);
    router.post('/api/admin/re-admission-cases', adminRoutes.createReAdmissionCase);
    router.put('/api/admin/re-admission-cases/<id>', adminRoutes.updateReAdmissionCase);
    router.get('/api/admin/discipline-cases', adminRoutes.getDisciplineCases);
    router.post('/api/admin/discipline-cases', adminRoutes.createDisciplineCase);
    router.put('/api/admin/discipline-cases/<id>', adminRoutes.updateDisciplineCase);
    router.get('/api/admin/exit-interviews', adminRoutes.getExitInterviews);
    router.put('/api/admin/exit-interviews/<id>', adminRoutes.updateExitInterview);
    router.get('/api/admin/credential-change-requests', adminRoutes.getCredentialChangeRequests);
    router.put('/api/admin/credential-change-requests/<id>', adminRoutes.updateCredentialChangeRequest);
    router.put('/api/admin/credential-change-requests/<id>/approve', adminRoutes.approveCredentialChangeRequest);



    // Good Moral Request routes
    router.post('/api/good-moral-requests/extract-ocr', extractOcrData);
    router.post('/api/good-moral-requests', createGoodMoralRequest);
    router.get('/api/good-moral-requests/student/<user_id>', getStudentGoodMoralRequests);

    // Admin Good Moral Request routes
    router.get('/api/admin/good-moral-requests', adminRoutes.getGoodMoralRequests);
    router.put('/api/admin/good-moral-requests/<id>/approve', adminRoutes.approveGoodMoralRequest);
    router.put('/api/admin/good-moral-requests/<id>/reject', adminRoutes.rejectGoodMoralRequest);

    // SCRF routes
    router.post('/api/scrf', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);

        // Validate required fields
        if (data['user_id'] == null || data['student_id'] == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'user_id and student_id are required'}),
          );
        }

        final result = await _database.execute('''
          CALL insert_scrf_record(
            @user_id, @student_id, @program_enrolled, @sex, @full_name, @address, @city, @barangay, @zipcode, @age,
            @civil_status, @date_of_birth, @place_of_birth, @lrn, @cellphone, @email_address,
            @father_name, @father_age, @father_occupation, @mother_name, @mother_age, @mother_occupation,
            @living_with_parents, @guardian_name, @guardian_relationship, @siblings,
            @educational_background, @awards_received, @transferee_college_name, @transferee_program,
            @physical_defect, @allergies_food, @allergies_medicine, @exam_taken, @exam_date,
            @raw_score, @percentile, @adjectival_rating, @created_by
          )
        ''', {
          'user_id': data['user_id'],
          'student_id': data['student_id'],
          'program_enrolled': data['program_enrolled'],
          'sex': data['sex'],
          'full_name': data['full_name'],
          'address': data['address'],
          'city': data['city'],
          'barangay': data['barangay'],
          'zipcode': data['zipcode'],
          'age': data['age'],
          'civil_status': data['civil_status'],
          'date_of_birth': data['date_of_birth'],
          'place_of_birth': data['place_of_birth'],
          'lrn': data['lrn'],
          'cellphone': data['cellphone'],
          'email_address': data['email_address'],
          'father_name': data['father_name'],
          'father_age': data['father_age'],
          'father_occupation': data['father_occupation'],
          'mother_name': data['mother_name'],
          'mother_age': data['mother_age'],
          'mother_occupation': data['mother_occupation'],
          'living_with_parents': data['living_with_parents'],
          'guardian_name': data['guardian_name'],
          'guardian_relationship': data['guardian_relationship'],
          'siblings': jsonEncode(data['siblings']),
          'educational_background': jsonEncode(data['educational_background']),
          'awards_received': data['awards_received'],
          'transferee_college_name': data['transferee_college_name'],
          'transferee_program': data['transferee_program'],
          'physical_defect': data['physical_defect'],
          'allergies_food': data['allergies_food'],
          'allergies_medicine': data['allergies_medicine'],
          'exam_taken': data['exam_taken'],
          'exam_date': data['exam_date'],
          'raw_score': data['raw_score'],
          'percentile': data['percentile'],
          'adjectival_rating': data['adjectival_rating'],
          'created_by': data['user_id'],
        });

        return Response.ok(jsonEncode({'message': 'SCRF record inserted successfully'}));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to insert SCRF record: $e'}),
        );
      }
    });

    router.get('/api/scrf/<user_id>', (Request request, String userId) async {
      try {
        final result = await _database.query('SELECT * FROM get_scrf_record(@user_id)', {
          'user_id': int.parse(userId),
        });

        if (result.isEmpty) {
          return Response.notFound(jsonEncode({'error': 'SCRF record not found'}));
        }

        final row = result.first;
        // Map the row to a JSON object (adjust indices as per your function)
        final scrfRecord = {
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
          'city': row[11],
          'barangay': row[12],
          'zipcode': row[13],
          'age': row[14],
          'civil_status': row[15],
          'date_of_birth': () {
            var value = row[16];
            if (value is DateTime) {
              return (value).toIso8601String();
            } else {
              return value?.toString();
            }
          }(),
          'place_of_birth': row[17],
          'lrn': row[18],
          'cellphone': row[19],
          'email_address': row[20],
          'father_name': row[21],
          'father_age': row[22],
          'father_occupation': row[23],
          'mother_name': row[24],
          'mother_age': row[25],
          'mother_occupation': row[26],
          'living_with_parents': row[27],
          'guardian_name': row[28],
          'guardian_relationship': row[29],
          'siblings': row[30],
          'educational_background': row[31],
          'awards_received': row[32],
          'transferee_college_name': row[33],
          'transferee_program': row[34],
          'physical_defect': row[35],
          'allergies_food': row[36],
          'allergies_medicine': row[37],
          'exam_taken': row[38],
          'exam_date': () {
            var value = row[39];
            if (value is DateTime) {
              return (value).toIso8601String();
            } else {
              return value?.toString();
            }
          }(),
          'raw_score': row[40],
          'percentile': row[41],
          'adjectival_rating': row[42],
          'created_at': () {
            var value = row[43];
            if (value is DateTime) {
              return (value).toIso8601String();
            } else {
              return value?.toString();
            }
          }(),
          'updated_at': () {
            var value = row[44];
            if (value is DateTime) {
              return (value).toIso8601String();
            } else {
              return value?.toString();
            }
          }(),
        };

        return Response.ok(jsonEncode(scrfRecord));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch SCRF record: $e'}),
        );
      }
    });

    router.put('/api/scrf/<user_id>', (Request request, String userId) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);

        final result = await _database.execute('''
          CALL update_scrf_record(
            @user_id, @program_enrolled, @sex, @full_name, @address, @city, @barangay, @zipcode, @age,
            @civil_status, @date_of_birth, @place_of_birth, @lrn, @cellphone, @email_address,
            @father_name, @father_age, @father_occupation, @mother_name, @mother_age, @mother_occupation,
            @living_with_parents, @guardian_name, @guardian_relationship, @siblings,
            @educational_background, @awards_received, @transferee_college_name, @transferee_program,
            @physical_defect, @allergies_food, @allergies_medicine, @exam_taken, @exam_date,
            @raw_score, @percentile, @adjectival_rating, @updated_by
          )
        ''', {
          'user_id': int.parse(userId),
          'program_enrolled': data['program_enrolled'],
          'sex': data['sex'],
          'full_name': data['full_name'],
          'address': data['address'],
          'city': data['city'],
          'barangay': data['barangay'],
          'zipcode': data['zipcode'],
          'age': data['age'],
          'civil_status': data['civil_status'],
          'date_of_birth': data['date_of_birth'],
          'place_of_birth': data['place_of_birth'],
          'lrn': data['lrn'],
          'cellphone': data['cellphone'],
          'email_address': data['email_address'],
          'father_name': data['father_name'],
          'father_age': data['father_age'],
          'father_occupation': data['father_occupation'],
          'mother_name': data['mother_name'],
          'mother_age': data['mother_age'],
          'mother_occupation': data['mother_occupation'],
          'living_with_parents': data['living_with_parents'],
          'guardian_name': data['guardian_name'],
          'guardian_relationship': data['guardian_relationship'],
          'siblings': jsonEncode(data['siblings']),
          'educational_background': jsonEncode(data['educational_background']),
          'awards_received': data['awards_received'],
          'transferee_college_name': data['transferee_college_name'],
          'transferee_program': data['transferee_program'],
          'physical_defect': data['physical_defect'],
          'allergies_food': data['allergies_food'],
          'allergies_medicine': data['allergies_medicine'],
          'exam_taken': data['exam_taken'],
          'exam_date': data['exam_date'],
          'raw_score': data['raw_score'],
          'percentile': data['percentile'],
          'adjectival_rating': data['adjectival_rating'],
          'updated_by': data['user_id'],
        });

        return Response.ok(jsonEncode({'message': 'SCRF record updated successfully'}));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to update SCRF record: $e'}),
        );
      }
    });
  }

  Future<Response> healthCheck(Request request) async {
    try {
      final result = await _database.query('SELECT 1');
      return Response.ok(jsonEncode({
        'status': 'healthy',
        'database': 'connected',
        'timestamp': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({
          'status': 'unhealthy',
          'database': 'disconnected',
          'error': e.toString(),
        }),
      );
    }
  }

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

      // Hash the password
      final hashedPassword = BCrypt.hashpw(data['password'], BCrypt.gensalt());

      // Prepare user data
      final userData = {
        'username': data['username'],
        'email': data['email'],
        'password': hashedPassword,
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

  /// Query to demonstrate JOIN operations during signup process
  Future<Response> getSignupJoinExamples(Request request) async {
    try {
      // Example 1: INNER JOIN - Only users with student records
      final innerJoinResult = await _database.query('''
        SELECT u.username, u.email, u.role, s.student_id, s.first_name, s.last_name
        FROM users u
        INNER JOIN students s ON u.id = s.user_id
        ORDER BY u.created_at DESC
        LIMIT 5
      ''');

      // Example 2: LEFT JOIN - All users, with student info if available
      final leftJoinResult = await _database.query('''
        SELECT u.username, u.email, u.role,
               COALESCE(s.student_id, 'N/A') as student_id,
               COALESCE(s.first_name, 'N/A') as first_name,
               COALESCE(s.last_name, 'N/A') as last_name
        FROM users u
        LEFT JOIN students s ON u.id = s.user_id
        ORDER BY u.created_at DESC
        LIMIT 5
      ''');

      // Example 3: RIGHT JOIN - All students with their user info
      final rightJoinResult = await _database.query('''
        SELECT s.student_id, s.first_name, s.last_name, s.status, s.program,
               u.username, u.email, u.role
        FROM students s
        RIGHT JOIN users u ON s.user_id = u.id
        ORDER BY s.created_at DESC
        LIMIT 5
      ''');

      // Example 4: FULL OUTER JOIN simulation (using UNION)
      final fullJoinResult = await _database.query('''
        SELECT u.username, u.email, u.role, s.student_id, s.first_name, s.last_name, 'USER' as source
        FROM users u
        LEFT JOIN students s ON u.id = s.user_id
        UNION
        SELECT u.username, u.email, u.role, s.student_id, s.first_name, s.last_name, 'STUDENT' as source
        FROM students s
        LEFT JOIN users u ON s.user_id = u.id
        ORDER BY username
        LIMIT 10
      ''');

      return Response.ok(jsonEncode({
        'inner_join_example': {
          'description': 'INNER JOIN - Only users with student records',
          'query': 'SELECT u.username, u.email, u.role, s.student_id, s.first_name, s.last_name FROM users u INNER JOIN students s ON u.id = s.user_id',
          'results': innerJoinResult.map((row) => {
            'username': row[0],
            'email': row[1],
            'role': row[2],
            'student_id': row[3],
            'first_name': row[4],
            'last_name': row[5],
          }).toList(),
        },
        'left_join_example': {
          'description': 'LEFT JOIN - All users with student info if available',
          'query': 'SELECT u.username, u.email, u.role, COALESCE(s.student_id, \'N/A\') as student_id FROM users u LEFT JOIN students s ON u.id = s.user_id',
          'results': leftJoinResult.map((row) => {
            'username': row[0],
            'email': row[1],
            'role': row[2],
            'student_id': row[3],
            'first_name': row[4],
            'last_name': row[5],
          }).toList(),
        },
        'right_join_example': {
          'description': 'RIGHT JOIN - All students with their user info',
          'query': 'SELECT s.student_id, s.first_name, s.last_name, u.status, u.username, u.email FROM students s RIGHT JOIN users u ON s.user_id = u.id',
          'results': rightJoinResult.map((row) => {
            'student_id': row[0],
            'first_name': row[1],
            'last_name': row[2],
            'status': row[3],
            'username': row[4],
            'email': row[5],
            'role': row[6],
          }).toList(),
        },
        'full_join_simulation': {
          'description': 'FULL OUTER JOIN simulation using UNION',
          'query': 'SELECT u.username, u.email, u.role, s.student_id FROM users u LEFT JOIN students s ON u.id = s.user_id UNION SELECT u.username, u.email, u.role, s.student_id FROM students s LEFT JOIN users u ON s.user_id = u.id',
          'results': fullJoinResult.map((row) => {
            'username': row[0],
            'email': row[1],
            'role': row[2],
            'student_id': row[3],
            'first_name': row[4],
            'last_name': row[5],
            'source': row[6],
          }).toList(),
        },
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to demonstrate JOIN examples: $e'}),
      );
    }
  }

  // Guidance system specific endpoints
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

      query += ' ORDER BY a.appointment_date DESC';

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

  // Routine Interview endpoints
  Future<Response> createRoutineInterview(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Validate required fields
      if (data['user_id'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id is required'}),
        );
      }

      // Get student_id from user_id
      final userResult = await _database.query(
        'SELECT id FROM users WHERE id = @user_id AND role = @role',
        {'user_id': data['user_id'], 'role': 'student'},
      );

      if (userResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Student not found'}),
        );
      }

      final result = await _database.execute('''
        INSERT INTO routine_interviews (
          student_id, name, date, grade_course_year_section, nickname,
          ordinal_position, student_description, familial_description,
          strengths, weaknesses, achievements, best_work_person,
          first_choice, goals, contribution, talents_skills,
          home_problems, school_problems, applicant_signature, signature_date
        ) VALUES (
          @student_id, @name, @date, @grade_course_year_section, @nickname,
          @ordinal_position, @student_description, @familial_description,
          @strengths, @weaknesses, @achievements, @best_work_person,
          @first_choice, @goals, @contribution, @talents_skills,
          @home_problems, @school_problems, @applicant_signature, @signature_date
        )
        RETURNING id
      ''', {
        'student_id': data['user_id'],
        'name': data['name'] ?? '',
        'date': data['date'] != null ? DateTime.parse(data['date']) : DateTime.now(),
        'grade_course_year_section': data['grade_course_year_section'] ?? '',
        'nickname': data['nickname'] ?? '',
        'ordinal_position': data['ordinal_position'] ?? '',
        'student_description': data['student_description'] ?? '',
        'familial_description': data['familial_description'] ?? '',
        'strengths': data['strengths'] ?? '',
        'weaknesses': data['weaknesses'] ?? '',
        'achievements': data['achievements'] ?? '',
        'best_work_person': data['best_work_person'] ?? '',
        'first_choice': data['first_choice'] ?? '',
        'goals': data['goals'] ?? '',
        'contribution': data['contribution'] ?? '',
        'talents_skills': data['talents_skills'] ?? '',
        'home_problems': data['home_problems'] ?? '',
        'school_problems': data['school_problems'] ?? '',
        'applicant_signature': data['applicant_signature'] ?? '',
        'signature_date': data['signature_date'] != null ? DateTime.parse(data['signature_date']) : null,
      });

      return Response.ok(jsonEncode({
        'message': 'Routine interview created successfully',
        'interview_id': result,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create routine interview: $e'}),
      );
    }
  }

  Future<Response> getRoutineInterview(Request request, String userId) async {
    try {
      final result = await _database.query('''
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
      ''', {'user_id': int.parse(userId)});

      if (result.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Routine interview not found'}),
        );
      }

      final row = result.first;
      return Response.ok(jsonEncode({
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
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch routine interview: $e'}),
      );
    }
  }

  Future<Response> updateRoutineInterview(Request request, String userId) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Check if routine interview exists
      final existingResult = await _database.query(
        'SELECT id FROM routine_interviews WHERE student_id = @student_id',
        {'student_id': int.parse(userId)},
      );

      if (existingResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'Routine interview not found'}),
        );
      }

      // Build update query
      final updateFields = <String>[];
      final params = <String, dynamic>{'student_id': int.parse(userId)};

      if (data['name'] != null) {
        updateFields.add('name = @name');
        params['name'] = data['name'];
      }
      if (data['date'] != null) {
        updateFields.add('date = @date');
        params['date'] = DateTime.parse(data['date']);
      }
      if (data['grade_course_year_section'] != null) {
        updateFields.add('grade_course_year_section = @grade_course_year_section');
        params['grade_course_year_section'] = data['grade_course_year_section'];
      }
      if (data['nickname'] != null) {
        updateFields.add('nickname = @nickname');
        params['nickname'] = data['nickname'];
      }
      if (data['ordinal_position'] != null) {
        updateFields.add('ordinal_position = @ordinal_position');
        params['ordinal_position'] = data['ordinal_position'];
      }
      if (data['student_description'] != null) {
        updateFields.add('student_description = @student_description');
        params['student_description'] = data['student_description'];
      }
      if (data['familial_description'] != null) {
        updateFields.add('familial_description = @familial_description');
        params['familial_description'] = data['familial_description'];
      }
      if (data['strengths'] != null) {
        updateFields.add('strengths = @strengths');
        params['strengths'] = data['strengths'];
      }
      if (data['weaknesses'] != null) {
        updateFields.add('weaknesses = @weaknesses');
        params['weaknesses'] = data['weaknesses'];
      }
      if (data['achievements'] != null) {
        updateFields.add('achievements = @achievements');
        params['achievements'] = data['achievements'];
      }
      if (data['best_work_person'] != null) {
        updateFields.add('best_work_person = @best_work_person');
        params['best_work_person'] = data['best_work_person'];
      }
      if (data['first_choice'] != null) {
        updateFields.add('first_choice = @first_choice');
        params['first_choice'] = data['first_choice'];
      }
      if (data['goals'] != null) {
        updateFields.add('goals = @goals');
        params['goals'] = data['goals'];
      }
      if (data['contribution'] != null) {
        updateFields.add('contribution = @contribution');
        params['contribution'] = data['contribution'];
      }
      if (data['talents_skills'] != null) {
        updateFields.add('talents_skills = @talents_skills');
        params['talents_skills'] = data['talents_skills'];
      }
      if (data['home_problems'] != null) {
        updateFields.add('home_problems = @home_problems');
        params['home_problems'] = data['home_problems'];
      }
      if (data['school_problems'] != null) {
        updateFields.add('school_problems = @school_problems');
        params['school_problems'] = data['school_problems'];
      }
      if (data['applicant_signature'] != null) {
        updateFields.add('applicant_signature = @applicant_signature');
        params['applicant_signature'] = data['applicant_signature'];
      }
      if (data['signature_date'] != null) {
        updateFields.add('signature_date = @signature_date');
        params['signature_date'] = DateTime.parse(data['signature_date']);
      }

      updateFields.add('updated_at = NOW()');

      if (updateFields.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'No valid fields to update'}),
        );
      }

      final updateQuery = 'UPDATE routine_interviews SET ${updateFields.join(', ')} WHERE student_id = @student_id';
      await _database.execute(updateQuery, params);

      return Response.ok(jsonEncode({
        'message': 'Routine interview updated successfully',
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update routine interview: $e'}),
      );
    }
  }

  // Credential Change Request endpoints
  Future<Response> createCredentialChangeRequest(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      print('Credential Change Request Body: $data');

      // Validate required fields
      if (data['user_id'] == null || data['request_type'] == null || data['new_value'] == null) {
        print('Missing required fields: user_id=${data['user_id']}, request_type=${data['request_type']}, new_value=${data['new_value']}');
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: user_id, request_type, new_value'}),
        );
      }

      // Validate request_type
      final validTypes = ['username', 'email', 'password', 'student_id'];
      if (!validTypes.contains(data['request_type'])) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Invalid request_type. Must be one of: ${validTypes.join(', ')}'}),
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

      // Check if there's already a pending request for this user and type
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

      // Insert the request
      final result = await _database.execute('''
        INSERT INTO credential_change_requests (
          user_id, request_type, current_value, new_value, reason, status, admin_notes
        ) VALUES (
          @user_id, @request_type, @current_value, @new_value, @reason, @status, @admin_notes
        )
        RETURNING id
      ''', {
        'user_id': data['user_id'],
        'request_type': data['request_type'],
        'current_value': data['current_value'] ?? '',
        'new_value': data['new_value'],
        'reason': data['reason'] ?? '',
        'status': 'pending',
        'admin_notes': '',
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
          ccr.updated_at,
          u.username,
          u.email,
          u.first_name,
          u.last_name,
          u.student_id
        FROM credential_change_requests ccr
        JOIN users u ON ccr.user_id = u.id
        WHERE ccr.user_id = @user_id
        ORDER BY ccr.created_at DESC
      ''', {'user_id': int.parse(userId)});

      final requests = result.map((row) => {
        'id': row[0],
        'user_id': row[1],
        'request_type': row[2],
        'current_value': row[3],
        'new_value': row[4],
        'reason': row[5],
        'status': row[6],
        'admin_notes': row[7],
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'updated_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'username': row[10],
        'email': row[11],
        'first_name': row[12],
        'last_name': row[13],
        'student_id': row[14],
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

  // OCR Data Extraction endpoint (deprecated - now handled locally on client)
  Future<Response> extractOcrData(Request request) async {
    return Response.ok(jsonEncode({
      'message': 'OCR processing is now handled locally on the client',
      'deprecated': true,
    }));
  }

  // Good Moral Request endpoint
  Future<Response> createGoodMoralRequest(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);

      // Validate required fields
      if (data['user_id'] == null || data['ocr_data'] == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'Missing required fields: user_id, ocr_data'}),
        );
      }

      // Check if user exists and is a student
      final userResult = await _database.query(
        'SELECT role, first_name, last_name, student_id FROM users WHERE id = @user_id',
        {'user_id': data['user_id']},
      );

      if (userResult.isEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Only students can submit good moral requests'}));
      }

      final userRow = userResult.first;
      final studentName = '${userRow[1]} ${userRow[2]}';
      final studentNumber = userRow[3];

      // Check if student already has a pending request
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE student_id = @student_id AND status = @status',
        {
          'student_id': data['user_id'],
          'status': 'pending',
        },
      );

      if (existingRequest.isNotEmpty) {
        return Response.badRequest(
          body: jsonEncode({'error': 'You already have a pending good moral request'}),
        );
      }

      // Insert the request
      final result = await _database.execute('''
        INSERT INTO good_moral_requests (
          student_id, student_name, student_number, course, year_level, purpose, ocr_data, status
        ) VALUES (
          @student_id, @student_name, @student_number, @course, @year_level, @purpose, @ocr_data, @status
        )
        RETURNING id
      ''', {
        'student_id': data['user_id'],
        'student_name': studentName,
        'student_number': studentNumber,
        'course': data['course'] ?? '',
        'year_level': data['year_level'] ?? '',
        'purpose': data['purpose'] ?? '',
        'ocr_data': jsonEncode(data['ocr_data']),
        'status': 'pending',
      });

      return Response.ok(jsonEncode({
        'message': 'Good moral request submitted successfully',
        'request_id': result,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to create good moral request: $e'}),
      );
    }
  }

  Future<Response> getStudentGoodMoralRequests(Request request, String userId) async {
    try {
      // Check if user exists and is a student
      final userResult = await _database.query(
        'SELECT role FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userResult.isEmpty) {
        return Response.notFound(
          jsonEncode({'error': 'User not found'}),
        );
      }

      final userRole = userResult.first[0];
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Only students can view their good moral requests'}));
      }

      // Fetch student's good moral requests
      final result = await _database.query('''
        SELECT
          id,
          student_id,
          student_name,
          student_number,
          course,
          year_level,
          purpose,
          status,
          created_at,
          updated_at,
          admin_notes
        FROM good_moral_requests
        WHERE student_id = @student_id
        ORDER BY created_at DESC
      ''', {'student_id': int.parse(userId)});

      final requests = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'student_number': row[3],
        'course': row[4],
        'year_level': row[5],
        'purpose': row[6],
        'status': row[7],
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'updated_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'admin_notes': row[10],
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': requests.length,
        'requests': requests,
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch good moral requests: $e'}),
      );
    }
  }

  // NOTE:
  // To allow your emulator to access the backend API, make sure your server is started with:
  //   host: '0.0.0.0'
  // Example (in your main server file):
  //   var server = await serve(handler, '0.0.0.0', port);
  // For Android emulator, use '10.0.2.2' as the base URL in your app to access your PC's localhost.
}
