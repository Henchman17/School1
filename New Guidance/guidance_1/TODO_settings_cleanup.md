# Settings.dart Cleanup Tasks

## Step 1: Remove unused imports
- Check for any unused imports and remove them

## Step 2: Remove unused variables
- Remove _phoneController (not used)
- Remove _credentialRequests (not used)

## Step 3: Remove debug print statements
- Remove all print statements used for debugging

## Step 4: Remove unused API methods
- Remove _fetchAllUsers()
- Remove _fetchAllStudentsWithUsers()
- Remove _searchUsersAndStudents()
- Remove _deleteUser()
- Remove _getDatabaseStats()
- Remove _updateUserData() and _updateStudentData() (profile is read-only)
- Remove _saveUserProfile() (profile is read-only)

## Step 5: Clean up settings saving/loading
- Modify _saveSettings() to only save actual preferences (dark mode, notifications)
- Remove profile data saving from _saveSettings()
- Remove profile loading from _loadPreferences()

## Step 6: Organize code structure
- Group related methods together (e.g., API methods, UI builders)
- Improve method ordering for better readability

## Step 7: Ensure consistency
- Use consistent role checking (lowercase 'student' vs _selectedRole)
- Clean up null safety checks

## Step 8: Final cleanup
- Remove any remaining unused code
- Ensure all methods are properly used or removed

## Step 9: Test functionality
- Verify settings page loads correctly
- Test dark mode toggle
- Test notification toggles
- Test credential request dialogs
- Test navigation
