import 'dart:convert';
import 'package:shelf/shelf.dart';

class AdminRouteHelpers {
  final dynamic _database;

  AdminRouteHelpers(this._database);

  // Helper method for role-based authorization
  Future<bool> checkUserRole(int userId, String requiredRole) async {
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

  // Helper function to get month name
  String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Helper to safely format date-like values
  String? formatDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toIso8601String();
    try {
      return v.toString();
    } catch (_) {
      return null;
    }
  }

  // Helper to safely get index from row
  dynamic getRowValue(List row, int idx) {
    try {
      if (idx < 0) return null;
      if (idx >= row.length) return null;
      return row[idx];
    } catch (_) {
      return null;
    }
  }

  // Validate required fields in request data
  Response validateRequiredFields(Map<String, dynamic> data, List<String> requiredFields) {
    for (final field in requiredFields) {
      if (data[field] == null || data[field].toString().trim().isEmpty) {
        return Response(400, body: jsonEncode({'error': '$field is required'}));
      }
    }
    return Response.ok(''); // Valid
  }

  // Parse JSON request body with error handling
  Map<String, dynamic>? parseJsonBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
}
