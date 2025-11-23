import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserMigrationPage extends StatefulWidget {
  const UserMigrationPage({super.key});

  @override
  State<UserMigrationPage> createState() => _UserMigrationPageState();
}

class _UserMigrationPageState extends State<UserMigrationPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;
  String _status = 'Loading users...';
  int _migratedCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('id, email, username, first_name, last_name, role, student_id')
          .limit(100); // Limit to avoid too many at once

      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _totalCount = _users.length;
        _isLoading = false;
        _status = 'Found ${_users.length} users to migrate';
      });
    } catch (e) {
      setState(() {
        _status = 'Error loading users: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _migrateUsers() async {
    setState(() {
      _isLoading = true;
      _status = 'Starting migration...';
      _migratedCount = 0;
    });

    for (final user in _users) {
      try {
        await _migrateSingleUser(user);
        setState(() {
          _migratedCount++;
          _status = 'Migrated $_migratedCount of $_totalCount users...';
        });
      } catch (e) {
        print('Error migrating user ${user['email']}: $e');
        // Continue with next user
      }
    }

    setState(() {
      _isLoading = false;
      _status = 'Migration completed! $_migratedCount users migrated successfully.';
    });
  }

  Future<void> _migrateSingleUser(Map<String, dynamic> user) async {
    final email = user['email'];
    if (email == null || email.isEmpty) {
      throw Exception('User has no email');
    }

    // Generate a default password (you should change this)
    final defaultPassword = 'TempPass123!';

    try {
      // Create user in Supabase Auth
      final authResponse = await Supabase.instance.client.auth.admin.createUser(
        AdminUserAttributes(
          email: email,
          password: defaultPassword,
          emailConfirm: true, // Auto-confirm email
          userMetadata: {
            'username': user['username'],
            'first_name': user['first_name'],
            'last_name': user['last_name'],
            'role': user['role'],
            'student_id': user['student_id'],
          },
        ),
      );

      if (authResponse.user != null) {
        // Update the user record with the auth user ID
        await Supabase.instance.client
            .from('users')
            .update({'id': authResponse.user!.id})
            .eq('email', email);

        print('Successfully migrated user: $email');
      } else {
        throw Exception('Failed to create auth user');
      }
    } catch (e) {
      // If admin API fails, try signup (less reliable)
      print('Admin API failed for $email, trying signup...');
      await _trySignupMigration(user, defaultPassword);
    }
  }

  Future<void> _trySignupMigration(Map<String, dynamic> user, String password) async {
    final email = user['email'];

    try {
      // This won't work for existing users, but let's try
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user != null) {
        // Update the user record
        await Supabase.instance.client
            .from('users')
            .update({'id': authResponse.user!.id})
            .eq('email', email);

        print('Successfully migrated user via signup: $email');
      }
    } catch (e) {
      print('Signup also failed for $email: $e');
      throw e;
    }
  }

  Future<void> _resetUserIds() async {
    // This is a dangerous operation - only use if you know what you're doing
    setState(() {
      _status = 'Resetting user IDs...';
      _isLoading = true;
    });

    try {
      // Generate new UUIDs for all users
      for (final user in _users) {
        final newId = Supabase.instance.client.auth.currentUser?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';
        await Supabase.instance.client
            .from('users')
            .update({'id': newId})
            .eq('email', user['email']);
      }

      setState(() {
        _status = 'User IDs reset. You may need to recreate auth users.';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error resetting IDs: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Migration Tool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Migration Status:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 16),

            if (_users.isNotEmpty) ...[
              Text(
                'Users to Migrate (${_users.length}):',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _users.length,
                  itemBuilder: (context, index) {
                    final user = _users[index];
                    return Card(
                      child: ListTile(
                        title: Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'),
                        subtitle: Text(
                          'Email: ${user['email'] ?? 'N/A'}\n'
                          'Role: ${user['role'] ?? 'N/A'}\n'
                          'Student ID: ${user['student_id'] ?? 'N/A'}',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _migrateUsers,
                      child: const Text('Migrate All Users'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _resetUserIds,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Reset User IDs'),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.yellow.shade50,
                  border: Border.all(color: Colors.yellow.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⚠️ WARNING: This tool will create auth users with default password "TempPass123!". '
                  'Users should change their passwords after first login. '
                  'Make sure you have admin privileges in Supabase.',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
