import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../connection.dart';

class FormRoutes {
  final DatabaseConnection _database;

  FormRoutes(this._database);

  // ================= FORM MANAGEMENT ENDPOINTS =================

  // SCRF (Student Cumulative Records) endpoints
  Future<Response> createSCRF(Request request) async {
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
  }

  Future<Response> getSCRF(Request request, String userId) async {
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
            return (value as DateTime).toIso8601String();
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
            return (value as DateTime).toIso8601String();
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
            return (value as DateTime).toIso8601String();
          } else {
            return value?.toString();
          }
        }(),
        'updated_at': () {
          var value = row[44];
          if (value is DateTime) {
            return (value as DateTime).toIso8601String();
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
  }

  Future<Response> updateSCRF(Request request, String userId) async {
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

  // Good Moral Request endpoints
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
        return Response.forbidden(jsonEncode({'error': 'Only students can submit good moral requests'}));
      }

      final userRow = userResult.first;
      final studentName = '${userRow[1]} ${userRow[2]}';

      // Check if student already has a pending request
      final existingRequest = await _database.query(
        'SELECT id FROM good_moral_requests WHERE student_id = @student_id AND approval_status = @approval_status',
        {
          'student_id': data['user_id'],
          'approval_status': 'pending',
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
          student_id, student_name, course, purpose, address, school_year, ocr_data, approval_status
        ) VALUES (
          @student_id, @student_name, @course, @purpose, @address, @school_year, @ocr_data, @approval_status
        )
        RETURNING id
      ''', {
        'student_id': data['user_id'],
        'student_name': studentName,
        'course': data['course'] ?? '',
        'purpose': data['purpose'] ?? '',
        'address': data['address'] ?? '',
        'school_year': data['school_year'] ?? '',
        'ocr_data': jsonEncode(data['ocr_data']),
        'approval_status': 'pending'
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
          course,
          purpose,
          address,
          school_year,
          approval_status,
          created_at,
          updated_at,
          admin_notes,
          reviewed_at,
          reviewed_by,
          document_path
        FROM good_moral_requests
        WHERE student_id = @student_id
        ORDER BY created_at DESC
      ''', {'student_id': int.parse(userId)});

      final requests = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'course': row[3],
        'purpose': row[4],
        'address': row[5],
        'school_year': row[6],
        'approval_status': row[7],
        'created_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
        'updated_at': row[9] is DateTime ? (row[9] as DateTime).toIso8601String() : row[9]?.toString(),
        'admin_notes': row[10],
        'reviewed_at': row[11] is DateTime ? (row[11] as DateTime).toIso8601String() : row[11]?.toString(),
        'reviewed_by': row[12],
        'document_path': row[13]
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

  Future<Response> getGoodMoralNotifications(Request request) async {
    try {
      final userId = request.url.queryParameters['user_id'];

      if (userId == null) {
        return Response.badRequest(
          body: jsonEncode({'error': 'user_id parameter is required'}),
        );
      }

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
        return Response.forbidden(jsonEncode({'error': 'Only students can view their good moral notifications'}));
      }

      // Query for good moral notifications (approved/rejected status changes)
      final result = await _database.query('''
        SELECT
          id,
          student_id,
          student_name,
          approval_status,
          created_at,
          updated_at,
          admin_notes,
          reviewed_at,
          reviewed_by,
          document_path
        FROM good_moral_requests
        WHERE student_id = @user_id AND status IN ('approved', 'rejected')
        ORDER BY updated_at DESC
      ''', {'user_id': int.parse(userId)});

      final notifications = result.map((row) => {
        'id': row[0],
        'student_id': row[1],
        'student_name': row[2],
        'approval_status': row[3],
        'created_at': row[4] is DateTime ? (row[4] as DateTime).toIso8601String() : row[4]?.toString(),
        'updated_at': row[5] is DateTime ? (row[5] as DateTime).toIso8601String() : row[5]?.toString(),
        'admin_notes': row[6],
        'reviewed_at': row[7] is DateTime ? (row[7] as DateTime).toIso8601String() : row[7]?.toString(),
        'reviewed_by': row[8],
        'document_path': row[9],
        'notification_type': row[3], // 'approved' or 'rejected'
        'message': row[3] == 'approved'
            ? 'Your good moral request has been approved.'
            : 'Your good moral request has been rejected.',
      }).toList();

      return Response.ok(jsonEncode({
        'success': true,
        'count': notifications.length,
        'notifications': notifications
      }));
    } catch (e) {
      print('Error in getGoodMoralNotifications: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch good moral notifications: $e'}),
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
}
