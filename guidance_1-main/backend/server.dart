import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'connection.dart';
import 'routes/api_routes.dart';
import 'routes/scrf_routes.dart';
import 'routes/admin_routes.dart';
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

    // Mount additional routers
    router.mount('/api/scrf', scrfRoutes.router.call);
    router.mount('/api/student', studentRoutes.router.call);

    // API routes
    router.get('/health', apiRoutes.healthCheck);
    router.post('/api/users/login', apiRoutes.login);
    router.get('/api/users', apiRoutes.getAllUsers);
    router.get('/api/users/<id>', apiRoutes.getUserById);
    router.post('/api/users', apiRoutes.createUser);
    router.put('/api/users/<id>', apiRoutes.updateUser);
    router.delete('/api/users/<id>', apiRoutes.deleteUser);

    // Guidance system specific routes
    router.get('/api/students', apiRoutes.getAllStudents);
    router.get('/api/students/<id>', apiRoutes.getStudentById);
    router.post('/api/appointments', apiRoutes.createAppointment);
    router.get('/api/appointments', apiRoutes.getAppointments);
    router.put('/api/appointments/<id>', apiRoutes.updateAppointment);
    router.delete('/api/appointments/<id>', apiRoutes.deleteAppointment);
    router.get('/api/courses', apiRoutes.getCourses);

    // JOIN examples for signup process
    router.get('/api/examples/join-signup', apiRoutes.getSignupJoinExamples);

    // Credential Change Request routes
    router.post('/api/credential-change-requests', apiRoutes.createCredentialChangeRequest);
    router.get('/api/credential-change-requests/<userId>', apiRoutes.getUserCredentialChangeRequests);

    // Admin Credential Change Request routes
    router.get('/api/admin/credential-change-requests', adminRoutes.getCredentialChangeRequests);
    router.put('/api/admin/credential-change-requests/<id>', adminRoutes.updateCredentialChangeRequest);
    router.put('/api/admin/credential-change-requests/<id>/approve', adminRoutes.approveCredentialChangeRequest);

    // Admin routes
  router.get('/api/admin/dashboard', adminRoutes.getAdminDashboard);
  router.get('/api/admin/users', adminRoutes.getAdminUsers);
  router.post('/api/admin/users', adminRoutes.createAdminUser);
  router.put('/api/admin/users/<id>', adminRoutes.updateAdminUser);
  router.delete('/api/admin/users/<id>', adminRoutes.deleteAdminUser);
  router.get('/api/admin/users/<userId>/form-settings', adminRoutes.getUserFormSettings);
  router.put('/api/admin/users/<userId>/form-settings', adminRoutes.updateUserFormSettings);
  router.get('/api/admin/appointments', adminRoutes.getAdminAppointments);
  router.put('/api/admin/appointments/<id>/approve', adminRoutes.approveAppointment);
  router.put('/api/admin/appointments/<id>/reject', adminRoutes.rejectAppointment);
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
  router.get('/api/admin/forms', adminRoutes.getAdminForms);
  router.put('/api/admin/forms/<formType>/<formId>/activate', adminRoutes.activateForm);
  router.put('/api/admin/forms/<formType>/<formId>/deactivate', adminRoutes.deactivateForm);
  router.get('/api/student/forms', adminRoutes.getStudentForms);
  router.get('/api/admin/form-settings', adminRoutes.getFormSettings);
  router.put('/api/admin/form-settings', adminRoutes.updateFormSettings);

    // Good Moral Request routes
    router.post('/api/good-moral-requests/extract-ocr', apiRoutes.extractOcrData);
    router.post('/api/good-moral-requests', apiRoutes.createGoodMoralRequest);

    // Student routes are mounted above

    // Admin Good Moral Request routes
    router.get('/api/admin/good-moral-requests', adminRoutes.getGoodMoralRequests);
    router.put('/api/admin/good-moral-requests/<id>/approve', adminRoutes.approveGoodMoralRequest);
    router.put('/api/admin/good-moral-requests/<id>/reject', adminRoutes.rejectGoodMoralRequest);

    // Counselor routes
    // Head routes
    router.get('/api/head/dashboard', headRoutes.getDashboard);
    router.get('/api/head/good-moral-requests', headRoutes.getGoodMoralRequests);
    router.put('/api/head/good-moral-requests/<id>/approve', headRoutes.approveGoodMoralRequest);
    router.put('/api/head/good-moral-requests/<id>/reject', headRoutes.rejectGoodMoralRequest);

    router.get('/api/counselor/dashboard', apiRoutes.counselorRoutes.getCounselorDashboard);
    router.get('/api/counselor/students', apiRoutes.counselorRoutes.getCounselorStudents);
    router.get('/api/counselor/students/<studentId>/profile', apiRoutes.counselorRoutes.getStudentProfile);
    router.get('/api/counselor/appointments', apiRoutes.counselorRoutes.getCounselorAppointments);
    router.get('/api/counselor/sessions', apiRoutes.counselorRoutes.getCounselorSessions);
    router.put('/api/counselor/appointments/<id>', adminRoutes.updateCounselorAppointment);
    router.put('/api/counselor/appointments/<id>/complete', apiRoutes.counselorRoutes.completeAppointment);
    router.put('/api/counselor/appointments/<id>/confirm', apiRoutes.counselorRoutes.confirmAppointment);
    router.put('/api/counselor/appointments/<id>/approve', apiRoutes.counselorRoutes.approveAppointment);
    router.put('/api/counselor/appointments/<id>/reject', apiRoutes.counselorRoutes.rejectAppointment);
    router.put('/api/counselor/appointments/<id>/cancel', apiRoutes.counselorRoutes.cancelAppointment);
    router.delete('/api/counselor/appointments/<id>', apiRoutes.counselorRoutes.deleteAppointment);
    router.get('/api/counselor/guidance-schedules', apiRoutes.counselorRoutes.getCounselorGuidanceSchedules);
    router.put('/api/counselor/guidance-schedules/<id>/approve', apiRoutes.counselorRoutes.approveGuidanceSchedule);
    router.put('/api/counselor/guidance-schedules/<id>/reject', apiRoutes.counselorRoutes.rejectGuidanceSchedule);

    // Counselor case management routes
    router.get('/api/counselor/discipline-cases', apiRoutes.counselorRoutes.getCounselorDisciplineCases);
    router.post('/api/counselor/discipline-cases', apiRoutes.counselorRoutes.createCounselorDisciplineCase);
    router.put('/api/counselor/discipline-cases/<id>', apiRoutes.counselorRoutes.updateCounselorDisciplineCase);
    router.get('/api/counselor/re-admission-cases', apiRoutes.counselorRoutes.getCounselorReAdmissionCases);
    router.post('/api/counselor/re-admission-cases', apiRoutes.counselorRoutes.createCounselorReAdmissionCase);
    router.put('/api/counselor/re-admission-cases/<id>', apiRoutes.counselorRoutes.updateCounselorReAdmissionCase);
    router.get('/api/counselor/good-moral-requests', apiRoutes.counselorRoutes.getGoodMoralRequests);
    router.put('/api/counselor/good-moral-requests/<id>/approve', apiRoutes.counselorRoutes.approveGoodMoralRequest);
    router.put('/api/counselor/good-moral-requests/<id>/reject', apiRoutes.counselorRoutes.rejectGoodMoralRequest);

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
