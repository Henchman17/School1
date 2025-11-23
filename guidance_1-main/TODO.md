# TODO: Add DASS-21 Form Card and Admin Activation

## Backend Updates
- [ ] Update form_settings_table.sql to include dass21_enabled column
- [ ] Update admin_routes.dart getFormSettings to include dass21_enabled
- [ ] Update admin_routes.dart updateFormSettings to update dass21_enabled in database
- [ ] Update admin_routes.dart getAdminForms to include DASS-21 forms from psych_exam table
- [ ] Update admin_routes.dart activateForm/deactivateForm to handle dass21 form type

## Admin Side Updates
- [ ] Update admin_forms_page.dart to include dass21_enabled in _formSettings
- [ ] Update admin_forms_page.dart _fetchFormSettings to fetch dass21_enabled
- [ ] Update admin_forms_page.dart to add DASS-21 Enabled toggle in settings

## Student Side Updates
- [ ] Update student_panel.dart to import psych_exxam.dart
- [ ] Update student_panel.dart _formSettings to include dass21_enabled
- [ ] Update student_panel.dart _fetchFormSettings to fetch dass21_enabled
- [ ] Add _navigateToDASS21Page method in student_panel.dart
- [ ] Add DASS-21 card in student panel UI

## Testing
- [ ] Test admin form settings toggle
- [ ] Test DASS-21 card visibility based on setting
- [ ] Test navigation to DASS-21 form
- [ ] Test form submission and backend integration
