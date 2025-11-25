import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'admin_route_helpers.dart';

class AdminCaseRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminCaseRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= RE-ADMISSION CASE ENDPOINTS =================

  Future<Response> getReAdmissionCases(Request request) async {
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
        'created_at': row[7]?.toIso8601String(),
        'updated_at': row[8]?.toIso8601String(),
        'reviewed_at': row[9]?.toIso8601String(),
        'reviewed_by': row[10],
        'date': row[11]?.toIso8601String(),
        'counselor_name': row[12],
        'reviewed_by_name': row[13],
      }).toList();

      return Response.ok(jsonEncode({
        'cases': cases,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': total != null ? (total / limit).ceil() : 0,
        }
      }));
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

  // ================= DISCIPLINE CASE ENDPOINTS =================

  Future<Response> getDisciplineCases(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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

  // ================= EXIT INTERVIEW ENDPOINTS =================

  Future<Response> getExitInterviews(Request request) async {
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
      final totalResult = await _database.query('SELECT COUNT(*) FROM exit_interviews');
      final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

      // Get paginated results
      final result = await _database.query('''
        SELECT
          ei.id,
          ei.student_id,
          ei.student_name,
          ei.student_number,
          ei.interview_date,
          ei.grade_year_level,
          ei.present_program,
          ei.address,
          ei.father_name,
          ei.mother_name,
          ei.reason_family,
          ei.reason_classmate,
          ei.reason_academic,
          ei.reason_financial,
          ei.reason_teacher,
          ei.reason_other,
          ei.transfer_school,
          ei.transfer_program,
          ei.difficulties,
          ei.suggestions,
          ei.interviewee_signature,
          ei.interviewer_signature,
          ei.consent_given,
          ei.created_at,
          ei.updated_at
        FROM exit_interviews ei
        ORDER BY ei.created_at DESC
        LIMIT @limit OFFSET @offset
      ''', {'limit': limit, 'offset': offset});

      final interviews = result.map((row) => {
        'id': _helpers.getRowValue(row, 0),
        'student_id': _helpers.getRowValue(row, 1),
        'student_name': _helpers.getRowValue(row, 2),
        'student_number': _helpers.getRowValue(row, 3),
        'interview_date': _helpers.formatDate(_helpers.getRowValue(row, 4)),
        'grade_year_level': _helpers.getRowValue(row, 5),
        'present_program': _helpers.getRowValue(row, 6),
        'address': _helpers.getRowValue(row, 7),
        'father_name': _helpers.getRowValue(row, 8),
        'mother_name': _helpers.getRowValue(row, 9),
        'reason_family': _helpers.getRowValue(row, 10),
        'reason_classmate': _helpers.getRowValue(row, 11),
        'reason_academic': _helpers.getRowValue(row, 12),
        'reason_financial': _helpers.getRowValue(row, 13),
        'reason_teacher': _helpers.getRowValue(row, 14),
        'reason_other': _helpers.getRowValue(row, 15),
        'transfer_school': _helpers.getRowValue(row, 16),
        'transfer_program': _helpers.getRowValue(row, 17),
        'difficulties': _helpers.getRowValue(row, 18),
        'suggestions': _helpers.getRowValue(row, 19),
        'interviewee_signature': _helpers.getRowValue(row, 20),
        'interviewer_signature': _helpers.getRowValue(row, 21),
        'consent_given': _helpers.getRowValue(row, 22),
        'created_at': _helpers.formatDate(_helpers.getRowValue(row, 23)),
        'updated_at': _helpers.formatDate(_helpers.getRowValue(row, 24)),
      }).toList();

      return Response.ok(jsonEncode({
        'interviews': interviews,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': total != null ? (total / limit).ceil() : 0,
        }
      }));
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
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      // Note: The exit_interviews table doesn't have status or admin_notes fields in the new schema
      // Admins can update counselor assignment and other relevant fields
      if (data['counselor_id'] != null) {
        updateFields.add('counselor_id = @counselor_id');
        params['counselor_id'] = data['counselor_id'];
      }
      // Add other updatable fields as needed based on schema

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');
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

  // ================= EXIT SURVEY GRADUATING ENDPOINTS =================

  Future<Response> getExitSurveyGraduating(Request request) async {
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
      final totalResult = await _database.query('SELECT COUNT(*) FROM exit_survey_graduating');
      final total = totalResult.isNotEmpty ? totalResult.first[0] : 0;

      // Get paginated results
      final result = await _database.query('''
        SELECT
          esg.id,
          esg.student_id,
          esg.student_name,
          esg.student_number,
          esg.email,
          esg.last_name,
          esg.first_name,
          esg.middle_name,
          esg.selected_program,
          esg.selected_colleges,
          esg.career_plans,
          esg.career_aspirations,
          esg.achieving_plans,
          esg.community_contribution,
          esg.preparedness_rating,
          esg.need_counseling,
          esg.lessons_rating,
          esg.teachers_rating,
          esg.knowledge_rating,
          esg.skills_rating,
          esg.values_rating,
          esg.practical_experiences_rating,
          esg.guidance_rating,
          esg.faculty_rating,
          esg.deans_rating,
          esg.emiso_rating,
          esg.library_rating,
          esg.laboratories_rating,
          esg.external_linkages_rating,
          esg.finance_rating,
          esg.registrar_rating,
          esg.cafeteria_rating,
          esg.health_clinic_rating,
          esg.admission_rating,
          esg.research_rating,
          esg.suggestions,
          esg.alumni_survey,
          esg.consent_given,
          esg.created_at,
          esg.updated_at
        FROM exit_survey_graduating esg
        ORDER BY esg.created_at DESC
        LIMIT @limit OFFSET @offset
      ''', {'limit': limit, 'offset': offset});

      final surveys = result.map((row) => {
        'id': _helpers.getRowValue(row, 0),
        'student_id': _helpers.getRowValue(row, 1),
        'student_name': _helpers.getRowValue(row, 2),
        'student_number': _helpers.getRowValue(row, 3),
        'email': _helpers.getRowValue(row, 4),
        'last_name': _helpers.getRowValue(row, 5),
        'first_name': _helpers.getRowValue(row, 6),
        'middle_name': _helpers.getRowValue(row, 7),
        'selected_program': _helpers.getRowValue(row, 8),
        'selected_colleges': _helpers.getRowValue(row, 9),
        'career_plans': _helpers.getRowValue(row, 10),
        'career_aspirations': _helpers.getRowValue(row, 11),
        'achieving_plans': _helpers.getRowValue(row, 12),
        'community_contribution': _helpers.getRowValue(row, 13),
        'preparedness_rating': _helpers.getRowValue(row, 14),
        'need_counseling': _helpers.getRowValue(row, 15),
        'lessons_rating': _helpers.getRowValue(row, 16),
        'teachers_rating': _helpers.getRowValue(row, 17),
        'knowledge_rating': _helpers.getRowValue(row, 18),
        'skills_rating': _helpers.getRowValue(row, 19),
        'values_rating': _helpers.getRowValue(row, 20),
        'practical_experiences_rating': _helpers.getRowValue(row, 21),
        'guidance_rating': _helpers.getRowValue(row, 22),
        'faculty_rating': _helpers.getRowValue(row, 23),
        'deans_rating': _helpers.getRowValue(row, 24),
        'emiso_rating': _helpers.getRowValue(row, 25),
        'library_rating': _helpers.getRowValue(row, 26),
        'laboratories_rating': _helpers.getRowValue(row, 27),
        'external_linkages_rating': _helpers.getRowValue(row, 28),
        'finance_rating': _helpers.getRowValue(row, 29),
        'registrar_rating': _helpers.getRowValue(row, 30),
        'cafeteria_rating': _helpers.getRowValue(row, 31),
        'health_clinic_rating': _helpers.getRowValue(row, 32),
        'admission_rating': _helpers.getRowValue(row, 33),
        'research_rating': _helpers.getRowValue(row, 34),
        'suggestions': _helpers.getRowValue(row, 35),
        'alumni_survey': _helpers.getRowValue(row, 36),
        'consent_given': _helpers.getRowValue(row, 37),
        'created_at': _helpers.formatDate(_helpers.getRowValue(row, 38)),
        'updated_at': _helpers.formatDate(_helpers.getRowValue(row, 39)),
      }).toList();

      return Response.ok(jsonEncode({
        'surveys': surveys,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': total,
          'total_pages': total != null ? (total / limit).ceil() : 0,
        }
      }));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch exit surveys for graduating students: $e'}),
      );
    }
  }

  Future<Response> updateExitSurveyGraduating(Request request, String id) async {
    try {
      final body = await request.readAsString();
      Map<String, dynamic> data;
      try {
        data = jsonDecode(body) as Map<String, dynamic>;
      } catch (e) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');

      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final updateFields = <String>[];
      final params = <String, dynamic>{'id': int.parse(id)};

      // Admins can update consent status or other administrative fields
      if (data['consent_given'] != null) {
        updateFields.add('consent_given = @consent_given');
        params['consent_given'] = data['consent_given'];
      }
      // Add other updatable fields as needed

      if (updateFields.isNotEmpty) {
        updateFields.add('updated_at = NOW()');
        final updateQuery = 'UPDATE exit_survey_graduating SET ${updateFields.join(', ')} WHERE id = @id';
        await _database.execute(updateQuery, params);
      }

      return Response.ok(jsonEncode({'message': 'Exit survey for graduating student updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update exit survey for graduating student: $e'}),
      );
    }
  }
}
