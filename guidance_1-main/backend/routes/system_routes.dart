import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../connection.dart';

class SystemRoutes {
  final DatabaseConnection _database;

  SystemRoutes(this._database);

  // ================= SYSTEM ENDPOINTS =================

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
}
