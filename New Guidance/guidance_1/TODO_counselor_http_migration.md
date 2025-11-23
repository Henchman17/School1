# TODO: Migrate HTTP Calls in Counselor Files to Supabase

## Migration Tasks
- [x] Update counselor_appointments_page.dart: fetchAppointments, _completeAppointment, _confirmAppointment, _approveAppointment, _rejectAppointment, _editAppointment, _cancelAppointment, _deleteAppointment (Migrated to Supabase)
- [x] Update counselor_dashboard.dart: fetchDashboardData (Migrated to Supabase)
- [x] Update counselor_students_page.dart: fetchStudents, _viewStudentProfile (Migrated to Supabase)
- [x] Update counselor_scheduling_page.dart: _fetchCourses, _submitForm (Migrated to Supabase)
- [x] Update counselor_sessions_page.dart: fetchSessions (Migrated to Supabase)

## Details
- Replace http.get/post/put/delete with Supabase client methods using AppConfig.supabase
- Use .from('table').select() for GET requests
- Use .from('table').insert() for POST requests
- Use .from('table').update() for PUT requests
- Use .from('table').delete() for DELETE requests
- Ensure counselor_id filtering where applicable
- Update imports to include config.dart
- Test each change after implementation
