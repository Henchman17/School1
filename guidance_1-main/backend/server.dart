import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'connection.dart';
import 'routes/api_routes.dart';
import 'routes/scrf_routes.dart';
import 'routes/admin_routes_new.dart';
import 'routes/head_routes.dart';
import 'routes/student_routes.dart';
import 'dart:async';

Future<void> _ensureTablesExist(DatabaseConnection database) async {
  try {
    // Create form_settings table
    await database.execute('''
      CREATE TABLE IF NOT EXISTS form_settings (
        id SERIAL PRIMARY KEY,
        scrf_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        routine_interview_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        good_moral_request_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        guidance_scheduling_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Insert default settings if table is empty
    final existingSettings = await database.query('SELECT COUNT(*) FROM form_settings');
    if (existingSettings.isNotEmpty && existingSettings.first[0] == 0) {
      await database.execute('INSERT INTO form_settings (scrf_enabled, routine_interview_enabled, good_moral_request_enabled, guidance_scheduling_enabled) VALUES (TRUE, TRUE, TRUE, TRUE)');
    }

    // Create user_form_settings table
    await database.execute('''
      CREATE TABLE IF NOT EXISTS user_form_settings (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        scrf_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        routine_interview_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        good_moral_request_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        guidance_scheduling_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        dass21_enabled BOOLEAN NOT NULL DEFAULT TRUE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      )
    ''');

    // Add dass21_enabled column if it doesn't exist (for existing tables)
    await database.execute('ALTER TABLE user_form_settings ADD COLUMN IF NOT EXISTS dass21_enabled BOOLEAN NOT NULL DEFAULT TRUE');

    // Create index for performance
    await database.execute('CREATE INDEX IF NOT EXISTS idx_user_form_settings_user_id ON user_form_settings(user_id)');

    print('Tables verified/created successfully');
  } catch (e) {
    print('Error ensuring tables exist: $e');
    rethrow;
  }
}

void main(List<String> args) async {
  while (true) {
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '8080');

    print('Starting server...');
    print('Initializing database connection...');

    final database = DatabaseConnection();
    try {
      await database.initialize();
      print('Database connected successfully');

      // Ensure required tables exist
      await _ensureTablesExist(database);
      print('Database tables verified/created successfully');
    } catch (e) {
      print('Failed to connect to database: $e');
      exit(1);
    }

    final router = Router();
    final apiRoutes = ApiRoutes(database);
    final adminRoutes = AdminRoutes(database);
    final headRoutes = HeadRoutes(database);
    final studentRoutes = StudentRoutes(database);

    final scrfRoutes = ScrfRoutes(database);

    // Mount routers
    router.mount('/api', apiRoutes.router.call);
    router.mount('/api/scrf', scrfRoutes.router.call);
    router.mount('/api/student', studentRoutes.router.call);
    router.mount('/api/admin', adminRoutes.router.call);
    router.mount('/api/head', headRoutes.router.call);

    // Middleware pipeline
    final handler = Pipeline()
        .addMiddleware(logRequests())
        .addMiddleware(corsHeaders(
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
          },
        ))
        .addHandler(router.call);

    try {
      final server = await shelf_io.serve(handler, ip, port);
      print('Server listening on: ${server.address.address}:${server.port}');
      print('Try accessing: http://localhost:${server.port}/health');
      print('From emulator use: http://10.0.2.2:${server.port}/health');

      print('Press r to restart the server, q to quit.');

      bool shouldRestart = false;
      await for (String line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
        line = line.trim();
        if (line == 'r') {
          print('Restarting server...');
          await server.close();
          shouldRestart = true;
          break;
        } else if (line == 'q') {
          print('Stopping server...');
          await server.close();
          return;
        }
      }
      if (!shouldRestart) break;
    } catch (e) {
      print('Failed to start server: $e');
      exit(1);
    }
  }
}
