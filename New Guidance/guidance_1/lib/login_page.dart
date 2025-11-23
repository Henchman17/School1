import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'student/student_panel.dart';
import 'admin/admin_dashboard.dart';
import 'counselor/counselor_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _admissionNumberController = TextEditingController();
  String? _selectedStatus;
  String? _selectedProgram;
  List<Map<String, dynamic>> _courses = [];
  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _errorMessage = '';



  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await Supabase.instance.client.from('courses').select();
      setState(() {
        _courses = List<Map<String, dynamic>>.from(courses);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching courses: $e';
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _studentIdController.dispose();
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isLogin) {
        await _login();
      } else {
        await _register();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    try {
      final loginValue = _emailController.text.trim();
      final isEmail = loginValue.contains('@');

      String emailToUse;
      if (isEmail) {
        emailToUse = loginValue;
      } else {
        // Fetch email by student ID
        final userQuery = await Supabase.instance.client
            .from('users')
            .select('email')
            .eq('student_id', loginValue)
            .single();
        emailToUse = userQuery['email'];
      }

      // Use Supabase Auth for login
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: emailToUse,
        password: _passwordController.text,
      );

      if (authResponse.user != null) {
        // Fetch user data from Supabase
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        _navigateToMainApp(userData);
      } else {
        throw Exception('Login failed. Please try again.');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _register() async {
    try {
      // Sign up with Supabase Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (authResponse.user != null) {
        // Insert additional user data into the users table
        await Supabase.instance.client.from('users').insert({
          'id': authResponse.user!.id,
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'student_id': _studentIdController.text.trim(),
          'admission_number': _studentIdController.text.trim(),
          'role': 'student',
          'first_name': _firstNameController.text.trim(),
          'last_name': _lastNameController.text.trim(),
          'status': _selectedStatus,
          'program': _selectedProgram,
        });

        // Fetch the complete user data
        final userData = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', authResponse.user!.id)
            .single();

        _navigateToMainApp(userData);
      } else {
        throw Exception('Registration failed. Please try again.');
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  void _navigateToMainApp(Map<String, dynamic> userData) async {
    // Save user data to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userData['id']);
    await prefs.setString('user_role', userData['role']);
    await prefs.setString('user_email', userData['email'] ?? '');
    await prefs.setString('user_name', '${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}'.trim());

    if (userData['role'] == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardPage(userData: userData),
        ),
      );
    } else if (userData['role'] == 'counselor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => CounselorDashboardPage(userData: userData),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StudentPanel(userData: userData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image with gradient overlay
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/school.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.lightGreen.withOpacity(0.3),
                        const Color.from(alpha: 1, red: 0.106, green: 0.369, blue: 0.125).withOpacity(0.9),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Login/Signup Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/s_logo.jpg',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          
                          // Title
                          Text(
                            _isLogin ? 'Welcome Back' : 'Create Account',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 30, 182, 88),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin 
                              ? 'Sign in to continue' 
                              : 'Sign up to get started',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          
                          // Username field for registration
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Username',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a username';
                                }
                                if (value.length < 3) {
                                  return 'Username must be at least 3 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: _isLogin ? 'Email or Student ID' : 'Email',
                              hintText: _isLogin ? 'Enter your email address or student ID' : 'Enter your email address',
                              prefixIcon: Icon(_isLogin ? Icons.login : Icons.email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            keyboardType: _isLogin ? TextInputType.text : TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _isLogin ? 'Please enter your email or student ID' : 'Please enter your email';
                              }
                              if (_isLogin) {
                                // Login validation: either email or student ID
                                if (value.contains('@')) {
                                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                } else {
                                  if (value.length < 3) {
                                    return 'Student ID must be at least 3 characters';
                                  }
                                }
                              } else {
                                // Signup validation: only email
                                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Student/Admission Number Field (signup only)
                          if (!_isLogin) ...[
                            TextFormField(
                              controller: _studentIdController,
                              decoration: InputDecoration(
                                labelText: 'Student/Admission Number',
                                hintText: 'Enter your student ID or admission number if new student',
                                prefixIcon: const Icon(Icons.badge),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your student or admission number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Login hint text
                          if (_isLogin) ...[
                            Text(
                              'You can login with either your email address or student ID',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword 
                                    ? Icons.visibility 
                                    : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          
                          // Additional fields for signup
                          if (!_isLogin) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              obscureText: _obscurePassword,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                labelText: 'First Name',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                labelText: 'Last Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedStatus,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                prefixIcon: const Icon(Icons.school),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: const [
                                DropdownMenuItem(value: 'New Student', child: Text('New Student')),
                                DropdownMenuItem(value: 'Old Student', child: Text('Old Student')),
                                DropdownMenuItem(value: 'Current Student', child: Text('Current Student')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedStatus = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your status';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedProgram,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Program',
                                prefixIcon: const Icon(Icons.class_),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              items: _courses.where((course) => course['id'] != null && course['course_name'] != null).map((course) => DropdownMenuItem<String>(
                                value: course['id'].toString(),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    course['course_name'],
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedProgram = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select your program';
                                }
                                return null;
                              },
                            ),
                          ],
                          
                          // Error message
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Login/Signup Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 30, 182, 88),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              onPressed: _isLoading ? null : _handleAuth,
                              child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    _isLogin ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Toggle between login and signup
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                                _errorMessage = '';
                              });
                            },
                            child: Text(
                              _isLogin 
                                ? 'Don\'t have an account? Sign Up' 
                                : 'Already have an account? Sign In',
                              style: const TextStyle(
                                color: Color.fromARGB(255, 30, 182, 88),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
