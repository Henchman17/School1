import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../connection.dart';

class StudentRoutes {
  final DatabaseConnection _database;
  
  StudentRoutes(this._database);

  Router get router {
    final router = Router();

    // Get student forms
    router.get('/forms', (Request request) async {
      try {
        final studentId = int.parse(request.url.queryParameters['student_id'] ?? '0');

        // Get SCRF forms
        final scrfResult = await _database.query('''
          SELECT id, user_id, 'scrf' as form_type, active, status, created_at, updated_at
          FROM student_cumulative_records
          WHERE user_id = @studentId AND active = true
        ''', {'studentId': studentId});

        // Get Routine Interview forms
        final routineResult = await _database.query('''
          SELECT id, student_id as user_id, 'routine_interview' as form_type, active, status, created_at, updated_at
          FROM routine_interviews
          WHERE student_id = @studentId AND active = true
        ''', {'studentId': studentId});

        // Get Good Moral Request forms
        final goodMoralResult = await _database.query('''
          SELECT id, student_id as user_id, 'good_moral_request' as form_type, active, status, created_at, updated_at
          FROM good_moral_requests
          WHERE student_id = @studentId AND active = true
        ''', {'studentId': studentId});

        // Get DASS-21 forms
        final dass21Result = await _database.query('''
          SELECT id, user_id, 'dass21' as form_type, active, status, created_at, updated_at
          FROM psych_exam
          WHERE user_id = @studentId AND active = true
        ''', {'studentId': studentId});

        // Get Exit Interview forms
        final exitInterviewResult = await _database.query('''
          SELECT id, 'exit_interview_' || interview_type as form_type, student_id as user_id, status, created_at, updated_at
          FROM exit_interviews
          WHERE student_id = @studentId
        ''', {'studentId': studentId});

        final allForms = [
          ...scrfResult.map((row) => {
            'id': row[0],
            'user_id': row[1],
            'form_type': row[2],
            'active': row[3],
            'status': row[4] ?? 'draft',
            'created_at': (row[5] as DateTime?)?.toIso8601String(),
            'updated_at': (row[6] as DateTime?)?.toIso8601String(),
          }),
          ...routineResult.map((row) => {
            'id': row[0],
            'user_id': row[1],
            'form_type': row[2],
            'active': row[3],
            'status': row[4] ?? 'draft',
            'created_at': (row[5] as DateTime?)?.toIso8601String(),
            'updated_at': (row[6] as DateTime?)?.toIso8601String(),
          }),
          ...goodMoralResult.map((row) => {
            'id': row[0],
            'user_id': row[1],
            'form_type': row[2],
            'active': row[3],
            'status': row[4] ?? 'draft',
            'created_at': (row[5] as DateTime?)?.toIso8601String(),
            'updated_at': (row[6] as DateTime?)?.toIso8601String(),
          }),
          ...dass21Result.map((row) => {
            'id': row[0],
            'user_id': row[1],
            'form_type': row[2],
            'active': row[3],
            'status': row[4] ?? 'draft',
            'created_at': (row[5] as DateTime?)?.toIso8601String(),
            'updated_at': (row[6] as DateTime?)?.toIso8601String(),
          }),
          ...exitInterviewResult.map((row) => {
            'id': row[0],
            'user_id': row[2],
            'form_type': row[1],
            'active': true,
            'status': row[3] ?? 'draft',
            'created_at': (row[4] as DateTime?)?.toIso8601String(),
            'updated_at': (row[5] as DateTime?)?.toIso8601String(),
          }),
        ];

        // Add dummy entries for exit interviews if not already present
        if (!allForms.any((f) => f['form_type'] == 'exit_interview_graduating')) {
          allForms.add({
            'id': null,
            'user_id': studentId,
            'form_type': 'exit_interview_graduating',
            'active': true,
            'status': 'draft',
            'created_at': null,
            'updated_at': null,
          });
        }
        if (!allForms.any((f) => f['form_type'] == 'exit_interview_transferring')) {
          allForms.add({
            'id': null,
            'user_id': studentId,
            'form_type': 'exit_interview_transferring',
            'active': true,
            'status': 'draft',
            'created_at': null,
            'updated_at': null,
          });
        }

        return Response.ok(
          jsonEncode({'forms': allForms}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch student forms: $e'}),
        );
      }
    });

    // Submit exit interview
    router.post('/exit-interview', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final studentId = data['student_id'] as int;
        final studentName = data['student_name'] as String;
        final studentNumber = data['student_number'] as String;
        final interviewType = data['interview_type'] as String;
        final interviewDate = data['interview_date'] as String;
        final reasonForLeaving = data['reason_for_leaving'] as String;
        final satisfactionRating = data['satisfaction_rating'] as int;
        final academicExperience = data['academic_experience'] as String?;
        final supportServicesExperience = data['support_services_experience'] as String?;
        final facilitiesExperience = data['facilities_experience'] as String?;
        final overallImprovements = data['overall_improvements'] as String?;
        final futurePlans = data['future_plans'] as String?;
        final contactInfo = data['contact_info'] as String?;

        await _database.execute('''
          INSERT INTO exit_interviews (
            student_id, student_name, student_number, interview_type, interview_date,
            reason_for_leaving, satisfaction_rating, academic_experience,
            support_services_experience, facilities_experience, overall_improvements,
            future_plans, contact_info, status
          ) VALUES (
            @studentId, @studentName, @studentNumber, @interviewType, @interviewDate::date,
            @reasonForLeaving, @satisfactionRating, @academicExperience,
            @supportServicesExperience, @facilitiesExperience, @overallImprovements,
            @futurePlans, @contactInfo, 'completed'
          )
        ''', {
          'studentId': studentId,
          'studentName': studentName,
          'studentNumber': studentNumber,
          'interviewType': interviewType,
          'interviewDate': interviewDate,
          'reasonForLeaving': reasonForLeaving,
          'satisfactionRating': satisfactionRating,
          'academicExperience': academicExperience,
          'supportServicesExperience': supportServicesExperience,
          'facilitiesExperience': facilitiesExperience,
          'overallImprovements': overallImprovements,
          'futurePlans': futurePlans,
          'contactInfo': contactInfo,
        });

        return Response.ok(
          jsonEncode({'message': 'Exit interview submitted successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to submit exit interview: $e'}),
        );
      }
    });

    // Get DASS-21 assessment
    router.get('/dass21', (Request request) async {
      try {
        final userId = int.parse(request.url.queryParameters['user_id'] ?? '0');

        final result = await _database.query('''
          SELECT * FROM get_psych_exam_assessment(@userId)
        ''', {'userId': userId});

        if (result.isNotEmpty) {
          final assessment = result.first;
          final assessmentData = {
            'id': assessment[0],
            'user_id': assessment[1],
            'student_id': assessment[2],
            'username': assessment[3],
            'first_name': assessment[4],
            'last_name': assessment[5],
            'full_name': assessment[6],
            'program': assessment[7],
            'major': assessment[8],
            'assessment_date': (assessment[9] as DateTime?)?.toIso8601String(),
            'q1_hard_to_wind_down': assessment[10],
            'q2_dry_mouth': assessment[11],
            'q3_no_positive_feeling': assessment[12],
            'q4_breathing_difficulty': assessment[13],
            'q5_difficult_initiative': assessment[14],
            'q6_over_react': assessment[15],
            'q7_trembling': assessment[16],
            'q8_nervous_energy': assessment[17],
            'q9_worried_panic': assessment[18],
            'q10_nothing_to_look_forward': assessment[19],
            'q11_getting_agitated': assessment[20],
            'q12_difficult_relax': assessment[21],
            'q13_down_hearted': assessment[22],
            'q14_intolerant_delays': assessment[23],
            'q15_close_to_panic': assessment[24],
            'q16_unable_enthusiastic': assessment[25],
            'q17_not_worth_much': assessment[26],
            'q18_rather_touchy': assessment[27],
            'q19_heart_action': assessment[28],
            'q20_scared_no_reason': assessment[29],
            'q21_life_meaningless': assessment[30],
            'depression_score': assessment[31],
            'anxiety_score': assessment[32],
            'stress_score': assessment[33],
            'depression_severity': assessment[34],
            'anxiety_severity': assessment[35],
            'stress_severity': assessment[36],
            'active': assessment[37],
            'status': assessment[38],
            'created_at': (assessment[39] as DateTime?)?.toIso8601String(),
            'updated_at': (assessment[40] as DateTime?)?.toIso8601String(),
          };

          return Response.ok(
            jsonEncode({'assessment': assessmentData}),
            headers: {'Content-Type': 'application/json'},
          );
        } else {
          return Response.ok(
            jsonEncode({'assessment': null}),
            headers: {'Content-Type': 'application/json'},
          );
        }
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch DASS-21 assessment: $e'}),
        );
      }
    });

    // Save DASS-21 assessment
    router.post('/dass21', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body) as Map<String, dynamic>;

        final userId = data['user_id'] as int;
        final studentId = data['student_id'] as String;
        final fullName = data['full_name'] as String?;
        final program = data['program'] as String?;
        final major = data['major'] as String?;
        final status = data['status'] as String? ?? 'draft';

        // Extract question responses
        final q1 = data['q1'] as int?;
        final q2 = data['q2'] as int?;
        final q3 = data['q3'] as int?;
        final q4 = data['q4'] as int?;
        final q5 = data['q5'] as int?;
        final q6 = data['q6'] as int?;
        final q7 = data['q7'] as int?;
        final q8 = data['q8'] as int?;
        final q9 = data['q9'] as int?;
        final q10 = data['q10'] as int?;
        final q11 = data['q11'] as int?;
        final q12 = data['q12'] as int?;
        final q13 = data['q13'] as int?;
        final q14 = data['q14'] as int?;
        final q15 = data['q15'] as int?;
        final q16 = data['q16'] as int?;
        final q17 = data['q17'] as int?;
        final q18 = data['q18'] as int?;
        final q19 = data['q19'] as int?;
        final q20 = data['q20'] as int?;
        final q21 = data['q21'] as int?;

        await _database.execute('''
          CALL save_dass21_assessment(
            @userId, @studentId, @fullName, @program, @major,
            @q1, @q2, @q3, @q4, @q5, @q6, @q7, @q8, @q9, @q10,
            @q11, @q12, @q13, @q14, @q15, @q16, @q17, @q18, @q19, @q20, @q21,
            @status, @userId
          )
        ''', {
          'userId': userId,
          'studentId': studentId,
          'fullName': fullName,
          'program': program,
          'major': major,
          'q1': q1, 'q2': q2, 'q3': q3, 'q4': q4, 'q5': q5,
          'q6': q6, 'q7': q7, 'q8': q8, 'q9': q9, 'q10': q10,
          'q11': q11, 'q12': q12, 'q13': q13, 'q14': q14, 'q15': q15,
          'q16': q16, 'q17': q17, 'q18': q18, 'q19': q19, 'q20': q20, 'q21': q21,
          'status': status,
        });

        return Response.ok(
          jsonEncode({'message': 'DASS-21 assessment saved successfully'}),
          headers: {'Content-Type': 'application/json'},
        );
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to save DASS-21 assessment: $e'}),
        );
      }
    });

    // Submit good moral request
    router.post('/good-moral-requests', (Request request) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);

        // Validate required fields
        if (data['student_id'] == null || data['ocr_data'] == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Missing required fields: student_id, ocr_data'}),
          );
        }

        // Check if user exists and is a student
        final userResult = await _database.query(
          'SELECT role, first_name, last_name FROM users WHERE id = @user_id',
          {'user_id': data['student_id']},
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
          'SELECT id FROM good_moral_requests WHERE student_id = @student_id AND status = @status',
          {
            'student_id': data['student_id'],
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
            student_id, student_name, course, purpose, address, school_year, ocr_data, status, active
          ) VALUES (
            @student_id, @student_name, @course, @purpose, @address, @school_year, @ocr_data, @status, @active
          )
          RETURNING id
        ''', {
          'student_id': data['student_id'],
          'student_name': studentName,
          'course': data['course'] ?? '',
          'purpose': data['purpose'] ?? '',
          'address': data['address'] ?? '',
          'school_year': data['school_year'] ?? '',
          'ocr_data': jsonEncode(data['ocr_data']),
          'status': 'pending',
          'active': true,
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
    });

    return router;
  }
}
