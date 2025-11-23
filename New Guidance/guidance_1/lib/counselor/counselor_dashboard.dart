import 'package:flutter/material.dart';
import '../config.dart';
import '../login_page.dart';
import 'counselor_students_page.dart';
import 'counselor_appointments_page.dart';

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

  // static const String apiBaseUrl = 'http://localhost:8080'; // Commented out, using AppConfig.apiBaseUrl

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

      // Fetch statistics
      final statsResponse = await AppConfig.supabase
          .from('appointments')
          .select('apt_status, approval_status')
          .eq('counselor_id', userId);

      final totalStudentsResponse = await AppConfig.supabase
          .from('users')
          .select('id')
          .eq('role', 'student');

      final recentStudentsResponse = await AppConfig.supabase
          .from('users')
          .select('first_name, last_name, grade_level, section, id')
          .eq('role', 'student')
          .limit(5);

      final upcomingAppointmentsResponse = await AppConfig.supabase
          .from('appointments')
          .select('*, students(first_name, last_name)')
          .eq('counselor_id', userId)
          .or('apt_status.eq.pending,apt_status.eq.confirmed,apt_status.eq.scheduled')
          .order('date', ascending: true)
          .limit(5);

      // Process statistics
      final appointments = statsResponse as List<dynamic>;
      final totalStudents = totalStudentsResponse.length;
      final counselingSessions = appointments.length;
      final pendingRequests = appointments.where((a) => a['approval_status'] == 'pending').length;
      final completedSessions = appointments.where((a) => a['apt_status'] == 'completed').length;

      setState(() {
        dashboardData = {
          'statistics': {
            'total_students': totalStudents,
            'counseling_sessions': counselingSessions,
            'pending_requests': pendingRequests,
            'completed_sessions': completedSessions,
          },
          'recent_students': recentStudentsResponse,
          'upcoming_appointments': upcomingAppointmentsResponse.map((appointment) {
            final student = appointment['students'] as Map<String, dynamic>?;
            return {
              ...appointment,
              'student_name': student != null ? '${student['first_name']} ${student['last_name']}' : 'Unknown Student',
            };
          }).toList(),
        };
        isLoading = false;
      });
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
        // Title bar always above
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Counselor Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: fetchDashboardData,
            displacement: 0,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Metrics Row
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 300,
                            child: _buildMetricCard(
                              'Total Students',
                              stats['total_students']?.toString() ?? '0',
                              Icons.school,
                              Colors.blue,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 300,
                            child: _buildMetricCard(
                              'Appointments',
                              stats['counseling_sessions']?.toString() ?? '0',
                              Icons.event_note,
                              Colors.green,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 300,
                            child: _buildMetricCard(
                              'Pending Requests',
                              stats['pending_requests']?.toString() ?? '0',
                              Icons.pending_actions,
                              Colors.orange,
                            ),
                          ),
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 300,
                            child: _buildMetricCard(
                              'Completed Sessions',
                              stats['completed_sessions']?.toString() ?? '0',
                              Icons.check_circle,
                              Colors.purple,
                            ),
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
      case 3: // Logout
        _handleLogout();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar with user avatar
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
                  "PLSP Guidance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Notification icon
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No new notifications')),
                    );
                  },
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 10),
                // User Avatar with profile info
                if (_currentUser != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('User Profile'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    _currentUser!['username']?.substring(0, 1).toUpperCase() ?? 'C',
                                    style: const TextStyle(fontSize: 32, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Username: ${_currentUser!['username']}'),
                              Text('Email: ${_currentUser!['email'] ?? 'N/A'}'),
                              Text('Role: ${_currentUser!['role'] ?? 'Counselor'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white,
                          child: Text(
                            _currentUser!['username']?.substring(0, 1).toUpperCase() ?? 'C',
                            style: const TextStyle(
                              color: Color.fromARGB(255, 30, 182, 88),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentUser!['username'] ?? 'Counselor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _currentUser!['role'] ?? 'Counselor',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // Always visible NavigationRail
                SizedBox(
                  width: 220,
                  child: NavigationRail(
                    extended: true,
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: _handleNavigation,
                    labelType: null,
                    destinations: _buildNavigationDestinations(),
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
                              : Container(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
