import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../connection.dart';

class ScrfRoutes {
  final DatabaseConnection _database;

  ScrfRoutes(this._database);

  Router get router {
    final router = Router();

    // Insert SCRF record
    router.post('/scrf', (Request request) async {
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
            @user_id, @student_id, @program_enrolled, @sex, @full_name, @address, @age,
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

    // Get SCRF record by user_id
    router.get('/scrf/<user_id>', (Request request, String userId) async {
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
          'age': row[11],
          'civil_status': row[12],
          'date_of_birth': row[13] is DateTime ? (row[13] as DateTime).toIso8601String() : row[13]?.toString(),
          'place_of_birth': row[14],
          'lrn': row[15],
          'cellphone': row[16],
          'email_address': row[17],
          'father_name': row[18],
          'father_age': row[19],
          'father_occupation': row[20],
          'mother_name': row[21],
          'mother_age': row[22],
          'mother_occupation': row[23],
          'living_with_parents': row[24],
          'guardian_name': row[25],
          'guardian_relationship': row[26],
          'siblings': row[27],
          'educational_background': row[28],
          'awards_received': row[29],
          'transferee_college_name': row[30],
          'transferee_program': row[31],
          'physical_defect': row[32],
          'allergies_food': row[33],
          'allergies_medicine': row[34],
          'exam_taken': row[35],
          'exam_date': row[36] is DateTime ? (row[36] as DateTime).toIso8601String() : row[36]?.toString(),
          'raw_score': row[37],
          'percentile': row[38],
          'adjectival_rating': row[39],
          'created_at': row[40] is DateTime ? (row[40] as DateTime).toIso8601String() : row[40]?.toString(),
          'updated_at': row[41] is DateTime ? (row[41] as DateTime).toIso8601String() : row[41]?.toString(),
        };

        return Response.ok(jsonEncode(scrfRecord));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch SCRF record: $e'}),
        );
      }
    });

    // Update SCRF record
    router.put('/scrf/<user_id>', (Request request, String userId) async {
      try {
        final body = await request.readAsString();
        final data = jsonDecode(body);

        final result = await _database.execute('''
          CALL update_scrf_record(
            @user_id, @program_enrolled, @sex, @full_name, @address, @age,
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

    return router;
  }
}
