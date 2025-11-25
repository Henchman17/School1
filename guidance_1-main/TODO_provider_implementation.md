# TODO: Implement FormSettingsProvider

## Provider Implementation
- [x] Create FormSettingsProvider in lib/providers/form_settings_provider.dart
- [x] Add provider to MultiProvider in lib/main.dart

## Student Panel Refactor
- [x] Update lib/student/student_panel.dart to use FormSettingsProvider
- [x] Remove local _formSettings state
- [x] Remove _fetchFormSettings method
- [x] Update _navigateToGuidanceSchedulingPage, _navigateToGoodMoralRequestPage, _navigateToDASS21Page to use provider

## Admin Forms Page Refactor
- [x] Update lib/admin/admin_forms_page.dart to use FormSettingsProvider
- [x] Remove local _formSettings state
- [x] Remove _fetchFormSettings method
- [x] Update _buildSettingToggle to use provider
- [x] Update _updateFormSettings to use provider

## Testing
- [ ] Test form settings toggle in admin panel
- [ ] Test DASS-21 card visibility based on setting
- [ ] Test navigation restrictions when features are disabled
