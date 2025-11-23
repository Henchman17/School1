# Form Activation/Deactivation Implementation Plan

## Database Updates
- [x] Add `is_active` column to form tables (user will handle SQL queries)

## Backend Updates
- [x] Update `backend/routes/admin_routes.dart` to handle individual form activation/deactivation
- [x] Ensure form settings endpoints work with new `is_active` columns

## Admin Panel Updates
- [x] Update `lib/admin/admin_forms_page.dart` to properly toggle individual forms
- [x] Test admin form toggles update backend correctly

## Student Panel Updates
- [x] Update `lib/student/student_panel.dart` to conditionally show forms based on settings
- [x] Ensure form visibility logic respects `_formSettings`
- [x] Update `lib/student/student_panel.dart` to conditionally show "Answerable Forms" card only when student has active forms

## Testing
- [x] Test admin panel form toggles
- [x] Test student panel shows only enabled forms
- [x] Verify backend API responses include `is_active` status
