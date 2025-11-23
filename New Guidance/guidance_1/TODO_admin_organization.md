# Admin/Counselor Application File Organization

## Completed Tasks
- [x] Create lib/admin/ directory structure
- [x] Create lib/student/ directory structure
- [x] Move admin files to lib/admin/ folder (admin_dashboard.dart, admin_users_page.dart, admin_appointments_page.dart, admin_analytics_page.dart)
- [x] Move student files to lib/student/ folder (guidance_scheduling_page.dart, answerable_forms.dart, good_moral_request.dart)
- [x] Update all import paths to reflect new folder structure
- [x] Fix navigation_rail_example.dart imports for admin and student files
- [x] Fix main.dart routing with required parameters for GuidanceSchedulingPage
- [x] Fix import paths in student files (guidance_scheduling_page.dart, answerable_forms.dart, good_moral_request.dart)

## Remaining Tasks
- [ ] Create lib/counselor/ directory structure
- [ ] Create counselor-specific components
- [ ] Create lib/shared/ directory for common components
- [ ] Implement counselor interface components
- [ ] Test role-based navigation and access control
- [ ] Update login_page.dart for role-based navigation

## File Structure Summary
```
lib/
├── admin/
│   ├── admin_dashboard.dart
│   ├── admin_users_page.dart
│   ├── admin_appointments_page.dart
│   └── admin_analytics_page.dart
├── student/
│   ├── guidance_scheduling_page.dart
│   ├── answerable_forms.dart
│   └── good_moral_request.dart
├── counselor/ (to be created)
├── shared/ (to be created)
├── main.dart (updated with new routes)
├── navigation_rail_example.dart (updated with role-based navigation)
├── login_page.dart
├── settings.dart
└── ... (other existing files)
