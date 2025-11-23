import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';
import 'counselor_students_page.dart';
import 'counselor_appointments_page.dart';
import 'counselor_discipline_page.dart';
import 'counselor_re_admission_page.dart';
import 'counselor_good_moral_page.dart';

class CounselorDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CounselorDashboardPage({super.key, this.userData});

  @override
  State<CounselorDashboardPage> createState() => _CounselorDashboardPageState();
}

class _CounselorDashboardPageState extends State<CounselorDashboardPage> with SingleTickerProviderStateMixin {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic>? _currentUser;
  int _selectedIndex = 0;

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userData;
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/dashboard?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          dashboardData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load dashboard data';
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

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMetricCard(String title, String value, IconData icon, List<Color> gradientColors, IconData trendIcon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: gradientColors.first.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(width: 8),
                  Icon(trendIcon, size: 20, color: Colors.white.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentStudents() {
    final recentStudents = dashboardData?['recent_students'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Students',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/counselor-students'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentStudents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No recent students',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...recentStudents.map((student) {
                final name = '${student['first_name']} ${student['last_name']}';
                final details = 'Grade ${student['grade_level']} - Section ${student['section']}';
                final lastAppointment = student['last_appointment_date'] != null
                    ? 'Last appointment: ${DateTime.parse(student['last_appointment_date']).toLocal().toString().split(' ')[0]}'
                    : 'No recent appointment';
                return _buildStudentItem(
                  name,
                  details,
                  lastAppointment,
                  Icons.person,
                  Colors.blue,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentItem(String name, String details, String status, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  details,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointments() {
    final upcomingAppointments = dashboardData?['upcoming_appointments'] as List<dynamic>? ?? [];

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming Appointments',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/counselor-appointments'),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (upcomingAppointments.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No upcoming appointments',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...upcomingAppointments.map((appointment) {
                final studentName = appointment['student_name'] ?? 'Unknown Student';
                final purpose = appointment['purpose'] ?? 'General Counseling';
                final appointmentDate = appointment['appointment_date'] != null
                    ? DateTime.parse(appointment['appointment_date']).toLocal()
                    : DateTime.now();
                final timeString = '${appointmentDate.hour.toString().padLeft(2, '0')}:${appointmentDate.minute.toString().padLeft(2, '0')}';
                final dateString = appointmentDate.toString().split(' ')[0];
                final displayTime = 'Date: $dateString, Time: $timeString';
                return _buildAppointmentItem(
                  studentName,
                  purpose,
                  displayTime,
                  Icons.calendar_today,
                  Colors.blue,
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentItem(String student, String type, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard data...'),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: fetchDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final stats = dashboardData?['statistics'] ?? {};

    return Column(
      children: [
        Container(
          color: Colors.lightBlue.shade100,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PLSP Counselor Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 211, 224, 233), Color(0xFFFFFFFF)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: RefreshIndicator(
              onRefresh: fetchDashboardData,
              displacement: 0,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Metrics Row
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Total Students',
                              stats['total_students']?.toString() ?? '0',
                              Icons.school,
                              [Colors.blue.shade400, Colors.blue.shade600, Colors.blue.shade800],
                              Icons.group,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Appointments',
                              stats['counseling_sessions']?.toString() ?? '0',
                              Icons.event_note,
                              [Colors.green.shade400, Colors.green.shade600, Colors.green.shade800],
                              Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Pending Requests',
                              stats['pending_requests']?.toString() ?? '0',
                              Icons.pending_actions,
                              [Colors.orange.shade400, Colors.orange.shade600, Colors.orange.shade800],
                              Icons.hourglass_empty,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Completed Sessions',
                              stats['completed_sessions']?.toString() ?? '0',
                              Icons.check_circle,
                              [Colors.purple.shade400, Colors.purple.shade600, Colors.purple.shade800],
                              Icons.done_all,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recent Students
                    _buildRecentStudents(),

                    // Upcoming Appointments
                    _buildUpcomingAppointments(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<NavigationRailDestination> _buildNavigationDestinations() {
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
        icon: Icon(Icons.gavel),
        label: Text('Discipline'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assignment_return),
        label: Text('Re-admission'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.verified_user),
        label: Text('Good Moral'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Dashboard
        setState(() => _selectedIndex = 0);
        break;
      case 1: // Students
        setState(() => _selectedIndex = 1);
        break;
      case 2: // Appointments
        setState(() => _selectedIndex = 2);
        break;
      case 3: // Discipline
        setState(() => _selectedIndex = 3);
        break;
      case 4: // Re-admission
        setState(() => _selectedIndex = 4);
        break;
      case 5: // Good Moral
        setState(() => _selectedIndex = 5);
        break;
      case 6: // Logout
        _handleLogout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar with logo
          Container(
            color: const Color.fromARGB(255, 30, 182, 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/s_logo.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "PLSP Guidance Counselor",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 249, 250, 250),
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Always visible NavigationRail
                  SizedBox(
                    width: 220,
                    child: ListView(
                      children: [
                        for (int i = 0; i < _buildNavigationDestinations().length; i++)
                          ListTile(
                            leading: _buildNavigationDestinations()[i].icon,
                            title: _buildNavigationDestinations()[i].label,
                            selected: _selectedIndex == i,
                            onTap: () => _handleNavigation(i),
                          ),
                      ],
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  // Main content area
                  Expanded(
                    child: _selectedIndex == 0
                        ? _buildDashboardContent()
                        : _selectedIndex == 1
                            ? CounselorStudentsPage(userData: _currentUser)
                            : _selectedIndex == 2
                                ? CounselorAppointmentsPage(userData: _currentUser)
                                : _selectedIndex == 3
                                    ? CounselorDisciplinePage(userData: _currentUser)
                                    : _selectedIndex == 4
                                        ? CounselorReAdmissionPage(userData: _currentUser)
                                        : _selectedIndex == 5
                                            ? CounselorGoodMoralRequestsPage(userData: _currentUser)
                                            : Container(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
