import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../connection.dart';
import 'counselor_routes_updated.dart';
import 'admin_routes_new.dart';
import 'head_routes.dart';
import 'system_routes.dart';
import 'user_routes.dart';
import 'appointment_routes.dart';
import 'form_routes.dart';
import 'credential_routes.dart';

class ApiRoutes {
  final DatabaseConnection _database;
  late final CounselorRoutes counselorRoutes;
  late final AdminRoutes adminRoutes;
  late final HeadRoutes headRoutes;
  late final SystemRoutes systemRoutes;
  late final UserRoutes userRoutes;
  late final AppointmentRoutes appointmentRoutes;
  late final FormRoutes formRoutes;
  late final CredentialRoutes credentialRoutes;
  late final Router router;

  ApiRoutes(this._database) {
    counselorRoutes = CounselorRoutes(_database);
    adminRoutes = AdminRoutes(_database);
    headRoutes = HeadRoutes(_database);
    systemRoutes = SystemRoutes(_database);
    userRoutes = UserRoutes(_database);
    appointmentRoutes = AppointmentRoutes(_database);
    formRoutes = FormRoutes(_database);
    credentialRoutes = CredentialRoutes(_database);
    _setupRoutes();
  }

  void _setupRoutes() {
    router = Router();

    // Health check
    router.get('/health', systemRoutes.healthCheck);

    // User routes
    router.post('/users/login', userRoutes.login);
    router.get('/users', userRoutes.getAllUsers);
    router.get('/users/<id>', userRoutes.getUserById);
    router.post('/users', userRoutes.createUser);
    router.put('/users/<id>', userRoutes.updateUser);
    router.delete('/users/<id>', userRoutes.deleteUser);

    // Guidance system specific routes
    router.get('/students', userRoutes.getAllStudents);
    router.get('/students/<id>', userRoutes.getStudentById);
    router.post('/appointments', appointmentRoutes.createAppointment);
    router.get('/appointments', appointmentRoutes.getAppointments);
    router.get('/appointments/approved', appointmentRoutes.getApprovedAppointments);
    router.get('/appointments/notifications', appointmentRoutes.getAppointmentNotifications);
    router.put('/appointments/<id>', appointmentRoutes.updateAppointment);
    router.delete('/appointments/<id>', appointmentRoutes.deleteAppointment);
    router.get('/courses', appointmentRoutes.getCourses);

    // JOIN examples for signup process
    router.get('/examples/join-signup', systemRoutes.getSignupJoinExamples);

    // Routine Interview routes
    router.post('/routine-interviews', formRoutes.createRoutineInterview);
    router.get('/routine-interviews/<userId>', formRoutes.getRoutineInterview);
    router.put('/routine-interviews/<userId>', formRoutes.updateRoutineInterview);

    // Credential Change Request routes
    router.post('/credential-change-requests', credentialRoutes.createCredentialChangeRequest);
    router.get('/credential-change-requests/<userId>', credentialRoutes.getUserCredentialChangeRequests);

    // Admin routes are now handled by the mounted admin router in server.dart

    // Good Moral Request routes
    router.post('/good-moral-requests/extract-ocr', formRoutes.extractOcrData);
    router.post('/good-moral-requests', formRoutes.createGoodMoralRequest);
    router.get('/good-moral-requests/student/<user_id>', formRoutes.getStudentGoodMoralRequests);
    router.get('/good-moral-requests/notifications', formRoutes.getGoodMoralNotifications);

    // Admin Good Moral Request routes are now handled by the mounted admin router in server.dart

    // Counselor routes
    router.get('/counselor/dashboard', counselorRoutes.getCounselorDashboard);
    router.get('/counselor/students', counselorRoutes.getCounselorStudents);
    router.get('/counselor/students/<studentId>/profile', counselorRoutes.getStudentProfile);
    router.get('/counselor/appointments', counselorRoutes.getCounselorAppointments);
    router.get('/counselor/sessions', counselorRoutes.getCounselorSessions);
    router.put('/counselor/appointments/<id>/complete', counselorRoutes.completeAppointment);
    router.put('/counselor/appointments/<id>/confirm', counselorRoutes.confirmAppointment);
    router.put('/counselor/appointments/<id>/approve', counselorRoutes.approveAppointment);
    router.put('/counselor/appointments/<id>/reject', counselorRoutes.rejectAppointment);
    router.put('/counselor/appointments/<id>/cancel', counselorRoutes.cancelAppointment);
    router.delete('/counselor/appointments/<id>', counselorRoutes.deleteAppointment);
    router.get('/counselor/guidance-schedules', counselorRoutes.getCounselorGuidanceSchedules);
    router.put('/counselor/guidance-schedules/<id>/approve', counselorRoutes.approveGuidanceSchedule);
    router.put('/counselor/guidance-schedules/<id>/reject', counselorRoutes.rejectGuidanceSchedule);

    // Counselor case management routes
    router.get('/counselor/discipline-cases', counselorRoutes.getCounselorDisciplineCases);
    router.post('/counselor/discipline-cases', counselorRoutes.createCounselorDisciplineCase);
    router.put('/counselor/discipline-cases/<id>', counselorRoutes.updateCounselorDisciplineCase);
    router.get('/counselor/re-admission-cases', counselorRoutes.getCounselorReAdmissionCases);
    router.post('/counselor/re-admission-cases', counselorRoutes.createCounselorReAdmissionCase);
    router.put('/counselor/re-admission-cases/<id>', counselorRoutes.updateCounselorReAdmissionCase);
    router.get('/counselor/good-moral-requests', counselorRoutes.getGoodMoralRequests);
    router.put('/counselor/good-moral-requests/<id>/approve', counselorRoutes.approveGoodMoralRequest);
    router.put('/counselor/good-moral-requests/<id>/reject', counselorRoutes.rejectGoodMoralRequest);

    // Head routes
    router.get('/api/head/dashboard', headRoutes.getDashboard);
    router.get('/api/head/good-moral-requests', headRoutes.getGoodMoralRequests);
    router.put('/api/head/good-moral-requests/<id>/approve', headRoutes.approveGoodMoralRequest);
    router.put('/api/head/good-moral-requests/<id>/reject', headRoutes.rejectGoodMoralRequest);
    router.get('/head/pending-requests', (Request request) async {
      try {
        final result = await _database.query('''
          SELECT
            id,
            student_id,
            student_name,
            course,
            purpose,
            status,
            created_at,
            updated_at,
            reviewed_at,
            reviewed_by
          FROM good_moral_requests
          WHERE status = @status
          ORDER BY created_at DESC
        ''', {'status': 'pending'});

        final requests = result.map((row) => {
          'id': row[0],
          'student_id': row[1],
          'student_name': row[2],
          'course': row[3],
          'purpose': row[4],
          'status': row[5],
          'created_at': row[6] is DateTime ? (row[6] as DateTime).toIso8601String() : row[6]?.toString(),
          'updated_at': row[7] is DateTime ? (row[7] as DateTime).toIso8601String() : row[7]?.toString(),
          'reviewed_at': row[8] is DateTime ? (row[8] as DateTime).toIso8601String() : row[8]?.toString(),
          'reviewed_by': row[9],
        }).toList();

        return Response.ok(jsonEncode({
          'success': true,
          'count': requests.length,
          'pending_requests': requests,
        }));
      } catch (e) {
        return Response.internalServerError(
          body: jsonEncode({'error': 'Failed to fetch pending requests: $e'}),
        );
      }
    });
    router.get('/head/requests/<id>/history', (Request request, String id) async {
      // Temporary inline handler to avoid undefined getter on HeadRoutes.
      // Replace with headRoutes.getRequestApprovalHistory when implemented.
      return Response(501, body: jsonEncode({
        'success': false,
        'error': 'Not implemented: getRequestApprovalHistory handler is not available on HeadRoutes',
        'request_id': id,
      }));
    });

    // SCRF routes
    router.post('/scrf', formRoutes.createSCRF);
    router.get('/scrf/<user_id>', formRoutes.getSCRF);
    router.put('/scrf/<user_id>', formRoutes.updateSCRF);
  }
}
