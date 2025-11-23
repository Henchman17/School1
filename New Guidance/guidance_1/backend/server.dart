import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:watcher/watcher.dart';
import 'connection.dart';
import 'routes/api_routes.dart';
import 'routes/scrf_routes.dart';
import 'routes/admin_routes.dart';

void main(List<String> args) async {
  while (true) {
    final ip = InternetAddress.anyIPv4;
    final port = int.parse(Platform.environment['PORT'] ?? '8080');

    print('Starting server...');
    print('Server will be accessible at:');
    print('- Local: http://localhost:$port');
    print('- Network: http://192.168.1.10:$port');
    print('- For physical devices on same network: http://192.168.1.10:$port');
    print('- For Android emulator: http://10.0.2.2:$port');
    print('- For iOS simulator: http://127.0.0.1:$port');
    print('Initializing database connection...');

    final database = DatabaseConnection();
    try {
      await database.initialize();
      print('Database connected successfully');
    } catch (e) {
      print('Failed to connect to database: $e');
      exit(1);
    }

    final router = Router();
    final apiRoutes = ApiRoutes(database);
    final adminRoutes = AdminRoutes(database);

    final scrfRoutes = ScrfRoutes(database);

    // Mount additional routers
    router.mount('/api/scrf', scrfRoutes.router.call);

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
  router.get('/api/admin/forms', adminRoutes.getAdminForms);

    // Good Moral Request routes
    router.post('/api/good-moral-requests/extract-ocr', apiRoutes.extractOcrData);
    router.post('/api/good-moral-requests', apiRoutes.createGoodMoralRequest);

    // Admin Good Moral Request routes
    router.get('/api/admin/good-moral-requests', adminRoutes.getGoodMoralRequests);
    router.put('/api/admin/good-moral-requests/<id>/approve', adminRoutes.approveGoodMoralRequest);
    router.put('/api/admin/good-moral-requests/<id>/reject', adminRoutes.rejectGoodMoralRequest);

    // Counselor routes
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
      print('Server will auto-restart on file changes. Press r to restart manually, q to quit.');

      bool shouldRestart = false;
      final watcher = DirectoryWatcher('.');
      final watcherSubscription = watcher.events.listen((event) {
        if (event.path.endsWith('.dart') &&
            (event.type == ChangeType.MODIFY || event.type == ChangeType.ADD || event.type == ChangeType.REMOVE)) {
          print('File changed: ${event.path}, restarting server...');
          shouldRestart = true;
          server.close();
        }
      });

      await for (String line in stdin.transform(utf8.decoder).transform(LineSplitter())) {
        if (shouldRestart) break;
        line = line.trim();
        if (line == 'r') {
          print('Restarting server...');
          await server.close();
          shouldRestart = true;
          break;
        } else if (line == 'q') {
          print('Stopping server...');
          await server.close();
          watcherSubscription.cancel();
          return;
        }
      }
      watcherSubscription.cancel();
      if (!shouldRestart) break;
    } catch (e) {
      print('Failed to start server: $e');
      exit(1);
    }
  }
}
