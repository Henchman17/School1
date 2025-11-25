import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'admin_route_helpers.dart';

class AdminFormRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;

  AdminFormRoutes(this._database) : _helpers = AdminRouteHelpers(_database);

  // ================= FORMS MANAGEMENT ENDPOINTS =================

  Future<Response> getAdminForms(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
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
          COALESCE(s.active, true) as active,
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
          COALESCE(ri.active, true) as active,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM routine_interviews ri
        JOIN users u ON ri.student_id = u.id
        ORDER BY ri.created_at DESC
      ''');



      // Get DASS-21 forms
      final dass21Result = await _database.query('''
        SELECT
          'dass21' as form_type,
          pe.id as form_id,
          pe.user_id,
          u.student_id,
          CONCAT(u.first_name, ' ', u.last_name) as student_name,
          u.student_id as student_number,
          u.program,
          pe.created_at as submitted_at,
          pe.updated_at as reviewed_at,
          'completed' as status,
          true as active,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM psych_exam pe
        JOIN users u ON pe.user_id = u.id
        ORDER BY pe.created_at DESC
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
          'active': row[10],
          'first_name': row[11],
          'last_name': row[12],
          'student_status': row[13],
          'program': row[14],
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
          'active': row[10],
          'first_name': row[11],
          'last_name': row[12],
          'student_status': row[13],
          'program': row[14],
        });
      }



      // Add DASS-21 forms
      for (final row in dass21Result) {
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
          'active': row[10],
          'first_name': row[11],
          'last_name': row[12],
          'student_status': row[13],
          'program': row[14],
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

  Future<Response> activateForm(Request request, String formType, String formId) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      String tableName;
      String idColumn = 'id';

      switch (formType.toLowerCase()) {
        case 'scrf':
          tableName = 'student_cumulative_records';
          break;
        case 'routine_interview':
          tableName = 'routine_interviews';
          break;
        case 'good_moral_request':
          tableName = 'good_moral_requests';
          break;
        default:
          return Response(400, body: jsonEncode({'error': 'Invalid form type'}));
      }

      await _database.execute(
        'UPDATE $tableName SET active = true WHERE $idColumn = @id',
        {'id': int.parse(formId)},
      );

      return Response.ok(jsonEncode({'message': '$formType form activated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to activate form: $e'}),
      );
    }
  }

  Future<Response> deactivateForm(Request request, String formType, String formId) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      String tableName;
      String idColumn = 'id';

      switch (formType.toLowerCase()) {
        case 'scrf':
          tableName = 'student_cumulative_records';
          break;
        case 'routine_interview':
          tableName = 'routine_interviews';
          break;
        case 'good_moral_request':
          tableName = 'good_moral_requests';
          break;
        default:
          return Response(400, body: jsonEncode({'error': 'Invalid form type'}));
      }

      await _database.execute(
        'UPDATE $tableName SET active = false WHERE $idColumn = @id',
        {'id': int.parse(formId)},
      );

      return Response.ok(jsonEncode({'message': '$formType form deactivated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to deactivate form: $e'}),
      );
    }
  }

  Future<Response> getFormSettings(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Get global form settings from database
      var settingsResult;
      try {
        settingsResult = await _database.query('SELECT scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled, dass21_enabled FROM form_settings LIMIT 1');
      } catch (e) {
        if (e.toString().contains('relation "form_settings" does not exist') || e.toString().contains('does not exist')) {
          // Create the table
          await _database.execute('''
            CREATE TABLE form_settings (
              id SERIAL PRIMARY KEY,
              scrf_enabled BOOLEAN NOT NULL DEFAULT TRUE,
              routine_interview_enabled BOOLEAN NOT NULL DEFAULT TRUE,
              good_moral_request_enabled BOOLEAN NOT NULL DEFAULT TRUE,
              guidance_scheduling_enabled BOOLEAN NOT NULL DEFAULT TRUE,
              dass21_enabled BOOLEAN NOT NULL DEFAULT TRUE,
              updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
          ''');
          // Insert default settings
          await _database.execute('INSERT INTO form_settings (scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled, dass21_enabled) VALUES (TRUE, TRUE, TRUE, TRUE, FALSE)');
          settingsResult = await _database.query('SELECT scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled, dass21_enabled FROM form_settings LIMIT 1');
        } else {
          rethrow;
        }
      }

      Map<String, dynamic> settings;
      if (settingsResult.isNotEmpty) {
        final row = settingsResult.first;
        settings = {
          'scrf_enabled': row[0] ?? true,
          'routine_interview_enabled': row[1] ?? true,
          'good_moral_request_enabled': row[2] ?? true,
          'guidance_scheduling_enabled': row[3] ?? true,
          'dass21_enabled': row[4] ?? true,
        };
      } else {
        // Default settings if no record exists
        settings = {
          'scrf_enabled': true,
          'routine_interview_enabled': true,
          'good_moral_request_enabled': true,
          'guidance_scheduling_enabled': true,
          'dass21_enabled': true,
        };
      }

      return Response.ok(jsonEncode({'settings': settings}));
    } catch (e) {
      print('Error in getFormSettings: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch form settings: $e'}),
      );
    }
  }

  Future<Response> updateFormSettings(Request request) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final body = await request.readAsString();
      final data = _helpers.parseJsonBody(body);
      if (data == null) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }

      // Extract settings from the nested structure
      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings == null) {
        return Response(400, body: jsonEncode({'error': 'Settings object is required'}));
      }

      // Validate required fields
      final requiredFields = ['scrf_enabled', 'routine_interview_enabled', 'good_moral_request_enabled', 'guidance_scheduling_enabled', 'dass21_enabled'];
      for (final field in requiredFields) {
        if (settings[field] == null) {
          return Response(400, body: jsonEncode({'error': '$field is required'}));
        }
      }

      // Check if settings record exists
      final existingSettings = await _database.query('SELECT id FROM form_settings LIMIT 1');

      if (existingSettings.isNotEmpty) {
        // Update existing record
        await _database.execute(
          'UPDATE form_settings SET scrf_enabled = @scrf, routine_interview_enabled = @routine, good_moral_request_enabled = @good_moral, guidance_scheduling_enabled = @guidance, dass21_enabled = @dass21 WHERE id = @id',
          {
            'scrf': settings['scrf_enabled'],
            'routine': settings['routine_interview_enabled'],
            'good_moral': settings['good_moral_request_enabled'],
            'guidance': settings['guidance_scheduling_enabled'],
            'dass21': settings['dass21_enabled'],
            'id': existingSettings.first[0],
          },
        );
      } else {
        // Insert new record
        await _database.execute(
          'INSERT INTO form_settings (scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled, dass21_enabled) VALUES (@scrf, @routine, @good_moral, @guidance, @dass21)',
          {
            'scrf': settings['scrf_enabled'],
            'routine': settings['routine_interview_enabled'],
            'good_moral': settings['good_moral_request_enabled'],
            'guidance': settings['guidance_scheduling_enabled'],
            'dass21': settings['dass21_enabled'],
          },
        );
      }

      return Response.ok(jsonEncode({'message': 'Form settings updated successfully'}));
    } catch (e) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update form settings: $e'}),
      );
    }
  }

  Future<Response> getStudentForms(Request request) async {
    try {
      final studentId = int.parse(request.url.queryParameters['student_id'] ?? '0');

      // Check if user exists and is a student
      final userCheck = await _database.query(
        'SELECT id, role FROM users WHERE id = @student_id',
        {'student_id': studentId},
      );

      if (userCheck.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'Student not found'}));
      }

      final userRole = userCheck.first[1]?.toString();
      if (userRole != 'student') {
        return Response.forbidden(jsonEncode({'error': 'Access restricted to students'}));
      }

      // Get student's active SCRF forms
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
          COALESCE(s.active, true) as active,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM student_cumulative_records s
        JOIN users u ON s.user_id = u.id
        WHERE s.user_id = @student_id AND COALESCE(s.active, true) = true
        ORDER BY s.created_at DESC
      ''', {'student_id': studentId});

      // Get student's active Routine Interview forms
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
          COALESCE(ri.active, true) as active,
          u.first_name,
          u.last_name,
          u.status,
          u.program
        FROM routine_interviews ri
        JOIN users u ON ri.student_id = u.id
        WHERE ri.student_id = @student_id AND COALESCE(ri.active, true) = true
        ORDER BY ri.created_at DESC
      ''', {'student_id': studentId});

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
          'active': row[10],
          'first_name': row[11],
          'last_name': row[12],
          'student_status': row[13],
          'program': row[14],
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
          'active': row[10],
          'first_name': row[11],
          'last_name': row[12],
          'student_status': row[13],
          'program': row[14],
        });
      }

      return Response.ok(jsonEncode({'forms': forms}));
    } catch (e) {
      print('Error in getStudentForms: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch student forms: $e'}),
      );
    }
  }

  Future<Response> getUserFormSettings(Request request, String userId) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      // Check if user exists
      final userCheck = await _database.query(
        'SELECT id FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userCheck.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      // Get form settings for the user (default to enabled if no settings exist)
      final settingsResult = await _database.query(
        'SELECT scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled FROM user_form_settings WHERE user_id = @user_id',
        {'user_id': int.parse(userId)},
      );

      Map<String, dynamic> settings;
      if (settingsResult.isNotEmpty) {
        final row = settingsResult.first;
        settings = {
          'scrf_enabled': row[0] ?? true,
          'routine_interview_enabled': row[1] ?? true,
          'good_moral_request_enabled': row[2] ?? true,
          'guidance_scheduling_enabled': row[3] ?? true,
        };
      } else {
        // Default settings if no record exists
        settings = {
          'scrf_enabled': true,
          'routine_interview_enabled': true,
          'good_moral_request_enabled': true,
          'guidance_scheduling_enabled': true,
        };
      }

      return Response.ok(jsonEncode({'settings': settings}));
    } catch (e) {
      print('Error in getUserFormSettings: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch user form settings: $e'}),
      );
    }
  }

  Future<Response> updateUserFormSettings(Request request, String userId) async {
    try {
      final adminId = int.parse(request.url.queryParameters['admin_id'] ?? '0');
      if (!await _helpers.checkUserRole(adminId, 'admin')) {
        return Response.forbidden(jsonEncode({'error': 'Admin access required'}));
      }

      final body = await request.readAsString();
      final data = _helpers.parseJsonBody(body);
      if (data == null) {
        return Response(400, body: jsonEncode({'error': 'Invalid JSON format'}));
      }

      // Check if user exists
      final userCheck = await _database.query(
        'SELECT id FROM users WHERE id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (userCheck.isEmpty) {
        return Response.notFound(jsonEncode({'error': 'User not found'}));
      }

      // Extract settings from the nested structure
      final settings = data['settings'] as Map<String, dynamic>?;
      if (settings == null) {
        return Response(400, body: jsonEncode({'error': 'Settings object is required'}));
      }

      // Validate required fields
      final requiredFields = ['scrf_enabled', 'routine_interview_enabled', 'good_moral_request_enabled', 'guidance_scheduling_enabled'];
      for (final field in requiredFields) {
        if (settings[field] == null) {
          return Response(400, body: jsonEncode({'error': '$field is required'}));
        }
      }

      // Check if settings record exists
      final existingSettings = await _database.query(
        'SELECT id FROM user_form_settings WHERE user_id = @user_id',
        {'user_id': int.parse(userId)},
      );

      if (existingSettings.isNotEmpty) {
        // Update existing record
        await _database.execute(
          'UPDATE user_form_settings SET scrf_enabled = @scrf, routine_interview_enabled = @routine, good_moral_request_enabled = @good_moral, guidance_scheduling_enabled = @guidance WHERE user_id = @user_id',
          {
            'scrf': settings['scrf_enabled'],
            'routine': settings['routine_interview_enabled'],
            'good_moral': settings['good_moral_request_enabled'],
            'guidance': settings['guidance_scheduling_enabled'],
            'user_id': int.parse(userId),
          },
        );
      } else {
        // Insert new record
        await _database.execute(
          'INSERT INTO user_form_settings (user_id, scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled) VALUES (@user_id, @scrf, @routine, @good_moral, @guidance)',
          {
            'user_id': int.parse(userId),
            'scrf': settings['scrf_enabled'],
            'routine': settings['routine_interview_enabled'],
            'good_moral': settings['good_moral_request_enabled'],
            'guidance': settings['guidance_scheduling_enabled'],
          },
        );
      }

      return Response.ok(jsonEncode({'message': 'User form settings updated successfully'}));
    } catch (e) {
      print('Error in updateUserFormSettings: $e');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to update user form settings: $e'}),
      );
    }
  }
}
