import 'package:flutter/material.dart';
import 'package:guidance_1/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'privacy_policy_page.dart';

class SettingsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const SettingsPage({super.key, this.userData});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  String _selectedRole = 'student';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _studentData;
  bool _isLoading = false;

  // Database API endpoints
  static const String _baseUrl = 'http://10.0.2.2:8080/api'; // Adjust port as needed - 10.0.2.2 for Android emulator

  @override
  void initState() {
    super.initState();
    _loadDarkMode();
    _currentUser = widget.userData;
    _loadSettings();
  }

  Future<void> _loadDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('darkMode') ?? false;
    });
    _updateTheme();
  }

  void _updateTheme() {
    // Theme changes should be handled at the MaterialApp level using ThemeMode.
    // This function is left empty or can trigger a callback to a theme provider if implemented.
  }

  Future<void> _signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored preferences
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false, // Remove all previous routes
    );
  }

  Future<void> _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
    setState(() {
      _darkMode = value;
    });
    _updateTheme();
  }

  void _loadSettings() {
    // Always fetch fresh profile settings from users table API
    if (_currentUser != null && _currentUser!['id'] != null) {
      _loadUserProfile();
    } else if (widget.userData != null && widget.userData!['id'] != null) {
      // Use passed userData as fallback, but still fetch fresh data
      setState(() {
        _currentUser = widget.userData;
      });
      _loadUserProfile();
    }

    // Load other settings from SharedPreferences (non-user data)
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _darkMode);
    await prefs.setBool('notificationsEnabled', _notificationsEnabled);
    await prefs.setBool('emailNotifications', _emailNotifications);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        automaticallyImplyLeading: false,
        elevation: 4,
        shadowColor: Colors.green.shade300,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.lightBlue.withOpacity(0.3),
                    Colors.blue.shade900.withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Profile Settings', Icons.person),
                const SizedBox(height: 16),
                _buildProfileSection(),
                const SizedBox(height: 32),
                _buildSectionHeader('Preferences', Icons.settings),
                const SizedBox(height: 16),
                _buildPreferencesSection(),
                const SizedBox(height: 32),
                _buildSectionHeader('Notifications', Icons.notifications),
                const SizedBox(height: 16),
                _buildNotificationsSection(),
                const SizedBox(height: 32),
                _buildSectionHeader('Credential Change', Icons.edit),
                const SizedBox(height: 16),
                _buildCredentialRequestsSection(),
                const SizedBox(height: 32),
                _buildSectionHeader('Privacy & Security', Icons.security),
                const SizedBox(height: 16),
                _buildPrivacySection(),
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ElevatedButton(
                      onPressed: () async {
                        await _saveSettings();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Settings saved successfully'),
                            backgroundColor: Colors.green.shade600,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 6,
                        shadowColor: Colors.blue.shade300,
                      ),
                      child: const Text(
                        'Save Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade300, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue.shade800, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: const Icon(Icons.person, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
              enabled: false,
            ),
            const SizedBox(height: 12),
            // Display username from users table
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Username:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _currentUser?['username'] ?? 'N/A',
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Read-only role display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_circle, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'User Role:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedRole,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
              ),
            ),
            // Additional student information for students
            if (_selectedRole == 'student' && _studentData != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Student ID:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _studentData!['student_id'] ?? 'N/A',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.grade, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Status:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _studentData!['status'] ?? 'N/A',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.class_, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Text(
                      'Program:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _studentData!['program'] ?? 'N/A',
                      style: const TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Dark Mode'),
              subtitle: Text(_darkMode ? 'Dark theme enabled' : 'Light theme enabled'),
              value: _darkMode,
              onChanged: _toggleDarkMode,
              secondary: Icon(
                _darkMode ? Icons.dark_mode : Icons.light_mode,
                color: _darkMode ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Push Notifications'),
              subtitle: const Text('Receive app notifications'),
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Email Notifications'),
              subtitle: const Text('Receive email updates'),
              value: _emailNotifications,
              onChanged: (value) {
                setState(() {
                  _emailNotifications = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCredentialRequestsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, color: Colors.blue),
              title: const Text('Request Username Change'),
              subtitle: const Text('Submit a request to change your username'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCredentialChangeDialog('username'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Request Email Change'),
              subtitle: const Text('Submit a request to change your email address'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCredentialChangeDialog('email'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.blue),
              title: const Text('Request Password Change'),
              subtitle: const Text('Submit a request to change your password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCredentialChangeDialog('password'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.badge, color: Colors.blue),
              title: const Text('Request Student ID Change'),
              subtitle: const Text('Submit a request to change your student ID'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showCredentialChangeDialog('student_id'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: const Text('View Pending Requests'),
              subtitle: const Text('Check status of your credential change requests'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPendingRequestsDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: Colors.blue),
              title: const Text('Privacy Policy'),
              subtitle: const Text('View data protection and privacy information'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  // Database access methods for users and students tables

  /// Fetch user data from users table
  Future<Map<String, dynamic>?> _fetchUserData(int userId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/users/$userId'));
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);

        // Handle different response formats
        if (decodedData is Map<String, dynamic>) {
          return decodedData;
        } else if (decodedData is List && decodedData.isNotEmpty) {
          // If API returns a list, take the first item
          return decodedData.first as Map<String, dynamic>;
        } else {
          return null;
        }
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Load complete user profile from users table (merged structure)
  Future<void> _loadUserProfile() async {
    if (_currentUser == null || _currentUser!['id'] == null) return;

    if (mounted) setState(() => _isLoading = true);

    try {
      final userId = _currentUser!['id'];

      // Fetch fresh user data from users table (now contains all student data)
      final userData = await _fetchUserData(userId);
      if (userData != null) {
        setState(() {
          _currentUser = userData;
          _selectedRole = (userData['role'] ?? 'student').toString().toLowerCase();

          // Populate email field
          _emailController.text = userData['email'] ?? '';

          // For students, populate full name from first_name and last_name
          if (_selectedRole == 'student') {
            final firstName = userData['first_name'] ?? '';
            final lastName = userData['last_name'] ?? '';
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              _nameController.text = '$firstName $lastName';
            } else {
              // Fallback to username if names not available
              _nameController.text = userData['username'] ?? '';
            }
          } else {
            // For non-students, use username as display name
            _nameController.text = userData['username'] ?? '';
          }

          // Store student data for later use (only for students)
          if (_selectedRole == 'student') {
            _studentData = userData;
          } else {
            _studentData = null;
          }
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }













  /// Show dialog for credential change request
  void _showCredentialChangeDialog(String credentialType) {
    final TextEditingController controller = TextEditingController();
    String title = '';
    String label = '';
    String hint = '';

    switch (credentialType) {
      case 'username':
        title = 'Request Username Change';
        label = 'New Username';
        hint = 'Enter your desired username';
        break;
      case 'email':
        title = 'Request Email Change';
        label = 'New Email Address';
        hint = 'Enter your new email address';
        break;
      case 'password':
        title = 'Request Password Change';
        label = 'New Password';
        hint = 'Enter your new password';
        break;
      case 'student_id':
        title = 'Request Student ID Change';
        label = 'New Student ID';
        hint = 'Enter your new student ID';
        break;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                ),
                obscureText: credentialType == 'password',
                keyboardType: credentialType == 'email' ? TextInputType.emailAddress : TextInputType.text,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your request will be reviewed by an administrator. You will be notified once it is processed.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  await _submitCredentialChangeRequest(credentialType, controller.text);
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        );
      },
    );
  }

  /// Show dialog for pending credential change requests
  void _showPendingRequestsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pending Credential Change Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchCredentialRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error loading requests');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Text('No pending requests');
                } else {
                  final requests = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return ListTile(
                        title: Text('${request['request_type']} Change'),
                        subtitle: Text('Status: ${request['status']}'),
                        trailing: Text(request['created_at'] ?? ''),
                      );
                    },
                  );
                }
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  /// Submit credential change request to API
  Future<void> _submitCredentialChangeRequest(String credentialType, String newValue) async {
    if (_currentUser == null || _currentUser!['id'] == null) return;

    try {
      // Get current value based on credential type
      String currentValue = '';
      switch (credentialType) {
        case 'username':
          currentValue = _currentUser!['username'] ?? '';
          break;
        case 'email':
          currentValue = _currentUser!['email'] ?? '';
          break;
        case 'student_id':
          currentValue = _currentUser!['student_id'] ?? '';
          break;
        case 'password':
          // For password changes, we don't send the current password for security
          currentValue = '';
          break;
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/credential-change-requests'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': _currentUser!['id'],
          'request_type': credentialType,
          'current_value': currentValue,
          'new_value': newValue,
          'reason': 'User requested change via app',
          'status': 'pending',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request successful')),
        );
      } else {
        print('Failed to submit request. Status: ${response.statusCode}, Body: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request. Please try again.')),
        );
      }
    } catch (e) {
      print('Error submitting credential change request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting request. Please check your connection.')),
      );
    }
  }

  /// Fetch credential change requests for current user
  Future<List<Map<String, dynamic>>> _fetchCredentialRequests() async {
    if (_currentUser == null || _currentUser!['id'] == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/credential-change-requests/${_currentUser!['id']}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['requests'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
