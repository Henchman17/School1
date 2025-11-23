import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthTestPage extends StatefulWidget {
  const AuthTestPage({super.key});

  @override
  State<AuthTestPage> createState() => _AuthTestPageState();
}

class _AuthTestPageState extends State<AuthTestPage> {
  String _status = 'Checking authentication...';
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // Check current user
      final currentUser = Supabase.instance.client.auth.currentUser;
      setState(() {
        _status = currentUser != null
            ? 'Current user: ${currentUser.email ?? currentUser.id}'
            : 'No user currently logged in';
      });

      // Fetch users from database
      final usersResponse = await Supabase.instance.client
          .from('users')
          .select('id, email, username, student_id, role, first_name, last_name')
          .limit(10);

      setState(() {
        _users = List<Map<String, dynamic>>.from(usersResponse);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testLogin(String email, String password) async {
    setState(() {
      _status = 'Testing login...';
      _isLoading = true;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      setState(() {
        _status = response.user != null
            ? 'Login successful: ${response.user!.email}'
            : 'Login failed: No user returned';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Login error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    _checkAuthStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Test Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkAuthStatus,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Authentication Status:',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(_status),
            const SizedBox(height: 24),

            Text(
              'Database Users (first 10):',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          child: ListTile(
                            title: Text('${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'),
                            subtitle: Text(
                              'Email: ${user['email'] ?? 'N/A'}\n'
                              'Student ID: ${user['student_id'] ?? 'N/A'}\n'
                              'Role: ${user['role'] ?? 'N/A'}\n'
                              'Username: ${user['username'] ?? 'N/A'}',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.login),
                              onPressed: () {
                                final email = user['email'];
                                if (email != null) {
                                  _showLoginDialog(email);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showLoginDialog(''),
              child: const Text('Test Login with Custom Credentials'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLoginDialog(String prefilledEmail) {
    final emailController = TextEditingController(text: prefilledEmail);
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Login'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _testLogin(emailController.text, passwordController.text);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }
}
