import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminUsersPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminUsersPage({super.key, this.userData});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  List<dynamic> users = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedRoleFilter = 'All';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchUsers() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/users?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          users = data['users'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load users';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredUsers {
    var filtered = users;

    // Apply role filter
    if (selectedRoleFilter != 'All') {
      filtered = filtered.where((user) => user['role'] == selectedRoleFilter.toLowerCase()).toList();
    }

    // Apply search filter across multiple fields
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((user) {
        final username = user['username']?.toString().toLowerCase() ?? '';
        final email = user['email']?.toString().toLowerCase() ?? '';
        final studentId = user['student_id']?.toString().toLowerCase() ?? '';
        final firstName = user['first_name']?.toString().toLowerCase() ?? '';
        final lastName = user['last_name']?.toString().toLowerCase() ?? '';

        return username.contains(searchTerm) ||
               email.contains(searchTerm) ||
               studentId.contains(searchTerm) ||
               firstName.contains(searchTerm) ||
               lastName.contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  Future<void> deleteUser(int userId) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/api/admin/users/$userId?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'counselor':
        return Colors.blue;
      case 'head':
        return Colors.purple;
      case 'student':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: value ?? 'N/A',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(dynamic user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E88E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF1E88E5),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${user['username']}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E88E5),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(user['role'] ?? 'unknown').withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(user['role'] ?? 'unknown').withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        user['role'] == 'admin' ? Icons.admin_panel_settings :
                        user['role'] == 'counselor' ? Icons.support_agent :
                        user['role'] == 'student' ? Icons.school :
                        Icons.help_outline,
                        color: _getRoleColor(user['role'] ?? 'unknown'),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (user['role'] ?? 'unknown').toUpperCase(),
                        style: TextStyle(
                          color: _getRoleColor(user['role'] ?? 'unknown'),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.email, 'Email', user['email']),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Created', user['created_at']?.toString().split('T')[0]),
                  if (user['role'] == 'student') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.badge, 'Student ID', user['student_id']),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.person_outline, 'Name', '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.info, 'Status', user['status']),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.school, 'Program', user['program']),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showUserDetailsDialog(user),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showFormActivationDialog(user),
                  icon: const Icon(Icons.assignment, size: 16),
                  label: const Text('Activate Forms'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showEditUserDialog(user),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _showDeleteConfirmationDialog(user),
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getRoleColor(user['role'] ?? 'unknown').withOpacity(0.2),
              child: Text(
                user['username']?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  color: _getRoleColor(user['role'] ?? 'unknown'),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(user['username'] ?? 'Unknown'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Username', user['username'] ?? 'N/A'),
              _buildDetailRow('Email', user['email'] ?? 'N/A'),
              _buildDetailRow('Role', (user['role'] ?? 'N/A').toUpperCase()),
              _buildDetailRow('Created', user['created_at'] ?? 'N/A'),
              if (user['role'] == 'student') ...[
                const Divider(),
                _buildDetailRow('Student ID', user['student_id'] ?? 'N/A'),
                _buildDetailRow('First Name', user['first_name'] ?? 'N/A'),
                _buildDetailRow('Last Name', user['last_name'] ?? 'N/A'),
                _buildDetailRow('Status', user['status'] ?? 'N/A'),
                _buildDetailRow('Program', user['program'] ?? 'N/A'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(dynamic user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['username']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              deleteUser(user['id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFormActivationDialog(dynamic user) {
    // Form activation settings for this user
    Map<String, bool> userFormSettings = {
      'scrf_enabled': false,
      'routine_interview_enabled': false,
    };

    // Fetch current form settings for this user
    _fetchUserFormSettings(user['id']).then((settings) {
      if (settings != null) {
        setState(() {
          userFormSettings = settings;
        });
      }

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Activate Forms for ${user['username']}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select which forms to activate for this user:',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  _buildFormActivationSwitch(
                    'Student Cumulative Record Form (SCRF)',
                    'scrf_enabled',
                    userFormSettings,
                    setState,
                  ),
                  _buildFormActivationSwitch(
                    'Routine Interview',
                    'routine_interview_enabled',
                    userFormSettings,
                    setState,
                  ),

                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _updateUserFormSettings(user['id'], userFormSettings);
                  Navigator.of(context).pop();
                },
                child: const Text('Save Settings'),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFormActivationSwitch(String title, String settingKey, Map<String, bool> settings, StateSetter setState) {
    return SwitchListTile(
      title: Text(title),
      value: settings[settingKey] ?? false,
      onChanged: (value) {
        setState(() {
          settings[settingKey] = value;
        });
      },
      activeColor: Colors.green,
      contentPadding: EdgeInsets.zero,
    );
  }

  Future<Map<String, bool>?> _fetchUserFormSettings(int userId) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/users/$userId/form-settings?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['settings'] as Map<String, dynamic>;
        return {
          'scrf_enabled': settings['scrf_enabled'] ?? false,
          'routine_interview_enabled': settings['routine_interview_enabled'] ?? false,
          'good_moral_request_enabled': settings['good_moral_request_enabled'] ?? false,
          'guidance_scheduling_enabled': settings['guidance_scheduling_enabled'] ?? false,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateUserFormSettings(int userId, Map<String, bool> settings) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/users/$userId/form-settings?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'settings': settings}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Form settings updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update form settings'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating form settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showEditUserDialog(dynamic user) {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController(text: user['username']);
    final emailController = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'student';
    final studentIdController = TextEditingController(text: user['student_id']);
    final firstNameController = TextEditingController(text: user['first_name']);
    final lastNameController = TextEditingController(text: user['last_name']);
    final statusController = TextEditingController(text: user['status']);
    final programController = TextEditingController(text: user['program']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'counselor', 'student']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                if (selectedRole == 'student') ...[
                  TextFormField(
                    controller: studentIdController,
                    decoration: const InputDecoration(labelText: 'Student ID'),
                  ),
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                  ),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                  ),
                  TextFormField(
                    controller: statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  TextFormField(
                    controller: programController,
                    decoration: const InputDecoration(labelText: 'Program'),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final adminId = widget.userData?['id'] ?? 0;
                  final updateData = {
                    'admin_id': adminId,
                    'username': usernameController.text,
                    'email': emailController.text,
                    'role': selectedRole,
                  };

                  if (selectedRole == 'student') {
                    updateData.addAll({
                      'student_id': studentIdController.text,
                      'first_name': firstNameController.text,
                      'last_name': lastNameController.text,
                      'status': statusController.text,
                      'program': programController.text,
                    });
                  }

                  final response = await http.put(
                    Uri.parse('$apiBaseUrl/api/admin/users/${user['id']}'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(updateData),
                  );

                  if (response.statusCode == 200) {
                    Navigator.of(context).pop();
                    fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update user'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleFilterChip(String label, Color color) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selectedRoleFilter == label ? Colors.white : color)),
      selected: selectedRoleFilter == label,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.15),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedRoleFilter = label;
          });
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void showCreateUserDialog() {
    final formKey = GlobalKey<FormState>();
    final usernameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final studentIdController = TextEditingController();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final statusController = TextEditingController();
    final programController = TextEditingController();
    String selectedRole = 'student';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New User'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  items: ['admin', 'counselor', 'student']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(role.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => selectedRole = value!),
                  decoration: const InputDecoration(labelText: 'Role'),
                ),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                if (selectedRole == 'student') ...[
                  TextFormField(
                    controller: studentIdController,
                    decoration: const InputDecoration(labelText: 'Student ID'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: statusController,
                    decoration: const InputDecoration(labelText: 'Status'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: programController,
                    decoration: const InputDecoration(labelText: 'Program'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final adminId = widget.userData?['id'] ?? 0;
                  final userData = {
                    'admin_id': adminId,
                    'username': usernameController.text,
                    'email': emailController.text,
                    'password': passwordController.text,
                    'role': selectedRole,
                  };

                  if (selectedRole == 'student') {
                    userData.addAll({
                      'student_id': studentIdController.text,
                      'first_name': firstNameController.text,
                      'last_name': lastNameController.text,
                      'status': statusController.text,
                      'program': programController.text,
                    });
                  }

                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/api/admin/users'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(userData),
                  );

                  if (response.statusCode == 201) {
                    Navigator.of(context).pop();
                    fetchUsers();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User created successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to create user'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: const Color(0xFF1E88E5),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading users...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('User Management'),
          backgroundColor: const Color(0xFF1E88E5),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchUsers,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'User Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Add section
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search users by username, email, or student ID...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add User', style: TextStyle(color: Colors.white)),
                          onPressed: showCreateUserDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Role',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildRoleFilterChip('All', Colors.grey.shade600),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Admin', Colors.red.shade600),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Counselor', Colors.blue.shade600),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Head', Colors.purple.shade600),
                      const SizedBox(width: 8),
                      _buildRoleFilterChip('Student', Colors.green.shade600),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Users list
          Expanded(
            child: _filteredUsers.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No users found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_filteredUsers[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
