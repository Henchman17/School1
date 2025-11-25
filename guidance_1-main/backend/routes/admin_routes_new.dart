import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'admin/admin_route_helpers.dart';
import 'admin/admin_user_routes.dart';
import 'admin/admin_appointment_routes.dart';
import 'admin/admin_case_routes.dart';
import 'admin/admin_credential_routes.dart';
import 'admin/admin_activity_routes.dart';
import 'admin/admin_form_routes.dart';
import 'admin/admin_good_moral_routes.dart';

class AdminRoutes {
  final dynamic _database;
  final AdminRouteHelpers _helpers;
  final AdminUserRoutes _userRoutes;
  final AdminAppointmentRoutes _appointmentRoutes;
  final AdminCaseRoutes _caseRoutes;
  final AdminCredentialRoutes _credentialRoutes;
  final AdminActivityRoutes _activityRoutes;
  final AdminFormRoutes _formRoutes;
  final AdminGoodMoralRoutes _goodMoralRoutes;

  AdminRoutes(this._database)
      : _helpers = AdminRouteHelpers(_database),
        _userRoutes = AdminUserRoutes(_database),
        _appointmentRoutes = AdminAppointmentRoutes(_database),
        _caseRoutes = AdminCaseRoutes(_database),
        _credentialRoutes = AdminCredentialRoutes(_database),
        _activityRoutes = AdminActivityRoutes(_database),
        _formRoutes = AdminFormRoutes(_database),
        _goodMoralRoutes = AdminGoodMoralRoutes(_database);

  Router get router => Router()
    // ================= DASHBOARD ENDPOINTS =================
    ..get('/dashboard', _userRoutes.getAdminDashboard)

    // ================= USER MANAGEMENT ENDPOINTS =================
    ..get('/users', _userRoutes.getAdminUsers)
    ..post('/users', _userRoutes.createAdminUser)
    ..put('/users/<id>', _userRoutes.updateAdminUser)
    ..delete('/users/<id>', _userRoutes.deleteAdminUser)

    // ================= APPOINTMENT MANAGEMENT ENDPOINTS =================
    ..get('/appointments', _appointmentRoutes.getAdminAppointments)
    ..post('/appointments/<id>/approve', _appointmentRoutes.approveAppointment)
    ..post('/appointments/<id>/reject', _appointmentRoutes.rejectAppointment)
    ..get('/analytics', _appointmentRoutes.getAdminAnalytics)

    // ================= CASE MANAGEMENT ENDPOINTS =================
    ..get('/re-admission-cases', _caseRoutes.getReAdmissionCases)
    ..post('/re-admission-cases', _caseRoutes.createReAdmissionCase)
    ..put('/re-admission-cases/<id>', _caseRoutes.updateReAdmissionCase)
    ..get('/discipline-cases', _caseRoutes.getDisciplineCases)
    ..post('/discipline-cases', _caseRoutes.createDisciplineCase)
    ..put('/discipline-cases/<id>', _caseRoutes.updateDisciplineCase)
    ..get('/exit-interviews', _caseRoutes.getExitInterviews)
    ..put('/exit-interviews/<id>', _caseRoutes.updateExitInterview)
    ..get('/exit-survey-graduating', _caseRoutes.getExitSurveyGraduating)
    ..put('/exit-survey-graduating/<id>', _caseRoutes.updateExitSurveyGraduating)

    // ================= CREDENTIAL CHANGE REQUESTS ENDPOINTS =================
    ..get('/credential-change-requests', _credentialRoutes.getCredentialChangeRequests)
    ..put('/credential-change-requests/<id>', _credentialRoutes.updateCredentialChangeRequest)
    ..post('/credential-change-requests/<id>/approve', _credentialRoutes.approveCredentialChangeRequest)

    // ================= RECENT ACTIVITIES ENDPOINTS =================
    ..get('/recent-activities', _activityRoutes.getRecentActivities)
    ..get('/case-summary', _activityRoutes.getCaseSummary)

    // ================= FORMS MANAGEMENT ENDPOINTS =================
    ..get('/forms', _formRoutes.getAdminForms)
    ..post('/forms/<formType>/<formId>/activate', _formRoutes.activateForm)
    ..post('/forms/<formType>/<formId>/deactivate', _formRoutes.deactivateForm)
    ..get('/form-settings', _formRoutes.getFormSettings)
    ..put('/form-settings', _formRoutes.updateFormSettings)
    ..get('/student-forms', _formRoutes.getStudentForms)
    ..get('/user-form-settings/<userId>', _formRoutes.getUserFormSettings)
    ..put('/user-form-settings/<userId>', _formRoutes.updateUserFormSettings)

// ================= GOOD MORAL REQUEST ENDPOINTS =================
    ..get('/good-moral-requests', _goodMoralRoutes.getGoodMoralRequests)
    ..post('/good-moral-requests/<id>/approve', _goodMoralRoutes.approveGoodMoralRequest)
    ..post('/good-moral-requests/<id>/reject', _goodMoralRoutes.rejectGoodMoralRequest)
    ..put('/good-moral-requests/<id>', _goodMoralRoutes.updateGoodMoralRequest)
    ..post('/good-moral-requests/<id>/cancel', _goodMoralRoutes.cancelGoodMoralRequest)
    ..get('/good-moral-requests/<id>/download', _goodMoralRoutes.downloadGoodMoralDocument);
}
