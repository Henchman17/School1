import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';

import 'counselor_dashboard.dart';
import 'counselor_appointments_page.dart';
import 'counselor_scheduling_page.dart';

class CounselorStudentsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CounselorStudentsPage({super.key, this.userData});

  @override
  State<CounselorStudentsPage> createState() => _CounselorStudentsPageState();
}

class _CounselorStudentsPageState extends State<CounselorStudentsPage> {
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;
  String errorMessage = '';
  String searchQuery = '';
  int _selectedIndex = 1;

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchStudents();
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/students?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          students = List<Map<String, dynamic>>.from(data['students'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load students';
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



  List<Map<String, dynamic>> get filteredStudents {
    if (searchQuery.isEmpty) {
      return students;
    }
    return students.where((student) {
      final firstName = student['first_name'] ?? '';
      final lastName = student['last_name'] ?? '';
      final studentId = student['student_id']?.toString() ?? '';
      final name = '$firstName $lastName';
      return name.toLowerCase().contains(searchQuery.toLowerCase()) ||
             studentId.contains(searchQuery);
    }).toList();
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
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
                    '${student['first_name']} ${student['last_name']}',
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school,
                        color: Colors.green,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        (student['status'] ?? 'Active').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.green,
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
                  _buildInfoRow(Icons.badge, 'Student ID', student['student_id']),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.class_, 'Program', student['program']),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.calendar_today, 'Created', student['created_at']?.toString().split('T')[0]),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _viewStudentProfile(student),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Profile'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1E88E5),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _scheduleAppointment(student),
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: const Text('Schedule'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }


  Future<void> _viewStudentProfile(Map<String, dynamic> student) async {
    final studentId = student['user_id'] ?? student['id'];

    if (studentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student ID not found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final counselorId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/students/$studentId/profile?counselor_id=$counselorId'),
        headers: {'Content-Type': 'application/json'},
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (response.statusCode == 200) {
        final profileData = jsonDecode(response.body);

        // Show profile dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('${student['first_name']} ${student['last_name']} - Profile'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProfileSection('Basic Information', [
                    _buildProfileRow('Student ID', profileData['student_id']?.toString() ?? 'N/A'),
                    _buildProfileRow('Name', '${profileData['first_name'] ?? ''} ${profileData['last_name'] ?? ''}'),
                    _buildProfileRow('Email', profileData['email'] ?? 'N/A'),
                    _buildProfileRow('Status', profileData['status'] ?? 'N/A'),
                    _buildProfileRow('Program', profileData['program'] ?? 'N/A'),
                  ]),
                  const SizedBox(height: 16),
                  if (profileData['scrf_data'] != null && profileData['scrf_data'].isNotEmpty) ...[
                    _buildProfileSection('SCRF Information', [
                      _buildProfileRow('SCRF Status', profileData['scrf_data']['status'] ?? 'Not Available'),
                      if (profileData['scrf_data']['date_submitted'] != null)
                        _buildProfileRow('Date Submitted', profileData['scrf_data']['date_submitted']),
                      if (profileData['scrf_data']['counselor_notes'] != null)
                        _buildProfileRow('Counselor Notes', profileData['scrf_data']['counselor_notes']),
                    ]),
                  ],
                  const SizedBox(height: 16),
                  if (profileData['routine_interview'] != null) ...[
                    _buildProfileSection('Routine Interview', [
                      _buildProfileRow('Date', profileData['routine_interview']['date'] ?? 'N/A'),
                      _buildProfileRow('Grade/Course/Section', profileData['routine_interview']['grade_course_year_section'] ?? 'N/A'),
                      _buildProfileRow('Strengths', profileData['routine_interview']['strengths'] ?? 'N/A'),
                      _buildProfileRow('Weaknesses', profileData['routine_interview']['weaknesses'] ?? 'N/A'),
                      _buildProfileRow('Home Problems', profileData['routine_interview']['home_problems'] ?? 'N/A'),
                      _buildProfileRow('School Problems', profileData['routine_interview']['school_problems'] ?? 'N/A'),
                    ]),
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${response.statusCode}')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: $e')),
      );
    }
  }

  Widget _buildProfileSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildProfileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  void _scheduleAppointment(Map<String, dynamic> student) {
    // Navigate to the counselor scheduling page with the selected student info
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CounselorSchedulingPage(
          userData: widget.userData,
          selectedStudent: student,
        ),
      ),
    );
  }

  void _viewSessionHistory(Map<String, dynamic> student) {
    // TODO: Navigate to session history page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing session history for ${student['first_name']} ${student['last_name']}')),
    );
  }

  void _sendMessage(Map<String, dynamic> student) {
    // TODO: Navigate to messaging page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sending message to ${student['first_name']} ${student['last_name']}')),
    );
  }





  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Dashboard
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CounselorDashboardPage(userData: widget.userData),
          ),
        );
        break;
      case 1: // Students
        setState(() => _selectedIndex = 1);
        break;
      case 2: // Appointments
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => CounselorAppointmentsPage(userData: widget.userData),
          ),
        );
        break;
      case 3: // Logout
        _handleLogout();
        break;
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  List<NavigationRailDestination> _buildDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people),
        label: Text('Students'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calendar_today),
        label: Text('Appointments'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top header bar for this page
        Container(
          color: const Color.fromARGB(255, 30, 182, 88),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    "Student Management",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Search bar
                  Expanded(
                    flex: 2,
                    child: Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (value) => setState(() => searchQuery = value),
                        decoration: InputDecoration(
                          hintText: 'Search students by name or ID...',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(errorMessage, textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: fetchStudents,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: fetchStudents,
                      child: ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) => _buildStudentCard(filteredStudents[index]),
                      ),
                    ),
        ),
      ],
    );
  }
}
