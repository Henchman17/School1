# TODO: Update Remaining HTTP Calls in Admin Files

## Migration Tasks
- [x] Update admin_users_page.dart: deleteUser, update user, create user methods
- [x] Update admin_re_admission_page.dart: _fetchCases, _updateCaseStatus, _showAddDialog POST
- [x] Update admin_forms_page.dart: HTTP calls for good-moral-requests
- [x] Update admin_good_moral_requests_page.dart: HTTP calls
- [ ] Update admin_exit_interviews_page.dart: HTTP calls
- [ ] Update admin_discipline_page.dart: HTTP calls
- [ ] Update admin_dashboard.dart: HTTP calls for credential-change-requests, recent-activities
- [ ] Update admin_appointments_page.dart: HTTP calls
- [ ] Update admin_analytics_page.dart: HTTP calls

## Details
- Replace http.get/post/put/delete with Supabase client methods
- Use AppConfig.supabase for queries
- Ensure admin_id filtering where applicable
- Test each change after implementation
