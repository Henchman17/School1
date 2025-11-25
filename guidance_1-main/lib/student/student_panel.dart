import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'guidance_scheduling_page.dart';
import 'answerable_forms.dart';
import 'good_moral_request.dart';
import 'psych_exxam.dart';
import '../login_page.dart';
import '../settings.dart';
import '../shared_enums.dart';
import '../providers/auth_provider.dart';
import '../providers/form_settings_provider.dart';

class StudentPanel extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const StudentPanel({super.key, this.userData});

  @override
  State<StudentPanel> createState() => _StudentPanelState();
}

class _StudentPanelState extends State<StudentPanel> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isSidebarVisible = false; // Controls sidebar visibility (false = hidden, true = icon-only)
  SchedulingStatus _schedulingStatus = SchedulingStatus.none;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _approvedAppointments = [];
  List<Map<String, dynamic>> _appointmentNotifications = [];
  List<Map<String, dynamic>> _goodMoralNotifications = [];
  List<Map<String, dynamic>> _allNotifications = [];
  bool _isLoadingNotifications = false;

  List<Map<String, dynamic>> _studentForms = [];
  bool _isLoadingForms = false;

  static const String apiBaseUrl = 'http://10.0.2.2:8080';



  @override
  void initState() {
    super.initState();
    _currentUser = widget.userData;
    _fetchAllNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FormSettingsProvider>(context, listen: false).fetchFormSettings();
    });
    _fetchStudentForms();
  }

  String _usernameInitial() {
    try {
      final username = _currentUser?['username'];
      if (username is String && username.isNotEmpty) {
        return username.substring(0, 1).toUpperCase();
      }
    } catch (_) {}
    return 'S';
  }

  int _parseUserIdSafe() {
    final raw = _currentUser?['id'];
    if (raw is int) return raw;
    if (raw is String) {
      return int.tryParse(raw) ?? 0;
    }
    return 0;
  }

  String _parseStudentIdSafe() {
    final s = _currentUser?['student_id'];
    if (s == null) {
      // fallback to id
      return _parseUserIdSafe().toString();
    }
    return s.toString();
  }

  String _parseFullNameSafe() {
    final fn = _currentUser?['full_name'] ?? _currentUser?['name'] ?? _currentUser?['username'];
    return fn?.toString() ?? '';
  }

  String _parseProgramSafe() {
    return _currentUser?['program']?.toString() ?? '';
  }

  String _parseMajorSafe() {
    return _currentUser?['major']?.toString() ?? '';
  }

  Future<void> _fetchAppointmentNotifications() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final userId = _parseUserIdSafe();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/appointments/notifications?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _appointmentNotifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _appointmentNotifications = [];
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      setState(() {
        _appointmentNotifications = [];
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _fetchGoodMoralNotifications() async {
    if (_currentUser == null) return;

    try {
      final userId = _parseUserIdSafe();
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/good-moral-requests/notifications?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _goodMoralNotifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
        });
      } else {
        setState(() {
          _goodMoralNotifications = [];
        });
      }
    } catch (e) {
      setState(() {
        _goodMoralNotifications = [];
      });
    }
  }

  Future<void> _fetchAllNotifications() async {
    await Future.wait([
      _fetchAppointmentNotifications(),
      _fetchGoodMoralNotifications(),
    ]);

    // Combine and sort notifications by creation date (most recent first)
    final allNotifications = [..._appointmentNotifications, ..._goodMoralNotifications];
    allNotifications.sort((a, b) {
      final aDate = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
      final bDate = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
      return bDate.compareTo(aDate); // Most recent first
    });

    setState(() {
      _allNotifications = allNotifications;
    });
  }



  Future<void> _fetchStudentForms() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoadingForms = true;
    });

    try {
      final studentId = _parseUserIdSafe(); // backend uses user id; adjust if your API expects student_id instead
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/student/forms?student_id=$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _studentForms = List<Map<String, dynamic>>.from(data['forms'] ?? []);
          _isLoadingForms = false;
        });
      } else {
        setState(() {
          _studentForms = [];
          _isLoadingForms = false;
        });
      }
    } catch (e) {
      setState(() {
        _studentForms = [];
        _isLoadingForms = false;
      });
    }
  }

  bool _hasActiveForm(String formType) {
    return _studentForms.any((form) => form['form_type'] == formType && form['active'] == true);
  }

  bool _shouldShowAnswerableFormsCard() {
    // Always show the Answerable Forms card
    return true;
  }

  bool _hasCompletedForm(String formType) {
    return _studentForms.any((form) =>
      form['form_type'] == formType &&
      form['active'] == true &&
      form['status'] == 'completed'
    );
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
              // Clear AuthProvider
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.logout();

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

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Notifications'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingNotifications
                ? const Center(child: CircularProgressIndicator())
                : _allNotifications.isEmpty
                    ? const Text('No notifications.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _allNotifications.length,
                        itemBuilder: (context, index) {
                          final notification = _allNotifications[index];
                          final notificationType = notification['notification_type'] ?? 'general';
                          final isAppointment = notification.containsKey('appointment_date');

                          IconData icon;
                          Color iconColor;
                          String title;

                          if (isAppointment) {
                            // Appointment notifications
                            switch (notificationType) {
                              case 'approved':
                                icon = Icons.check_circle;
                                iconColor = Colors.green;
                                title = 'Appointment Approved';
                                break;
                              case 'cancelled':
                                icon = Icons.cancel;
                                iconColor = Colors.red;
                                title = 'Appointment Cancelled';
                                break;
                              case 'scheduled':
                                icon = Icons.schedule;
                                iconColor = Colors.blue;
                                title = 'Appointment Scheduled';
                                break;
                              default:
                                icon = Icons.notifications;
                                iconColor = Colors.grey;
                                title = 'Appointment Update';
                            }
                          } else {
                            // Good Moral notifications
                            switch (notificationType) {
                              case 'approved':
                                icon = Icons.description;
                                iconColor = Colors.green;
                                title = 'Good Moral Approved';
                                break;
                              case 'rejected':
                                icon = Icons.description;
                                iconColor = Colors.red;
                                title = 'Good Moral Rejected';
                                break;
                              default:
                                icon = Icons.description;
                                iconColor = Colors.grey;
                                title = 'Good Moral Update';
                            }
                          }

                          return ListTile(
                            leading: Icon(icon, color: iconColor),
                            title: Text(title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(notification['message'] ?? ''),
                                if (isAppointment && notification['appointment_date'] != null)
                                  Text(
                                    'Date: ${DateTime.tryParse(notification['appointment_date'])?.toLocal().toString().split(' ')[0] ?? 'N/A'}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                Text(
                                  'Date: ${notification['created_at'] != null ? DateTime.tryParse(notification['created_at'])?.toLocal().toString().split(' ')[0] ?? 'N/A' : 'N/A'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
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

  void _refreshNotifications() {
    _fetchAllNotifications();
  }

  void _navigateToAnswerableFormsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnswerableForms(userData: _currentUser),
      ),
    );
  }

  void _navigateToGuidanceSchedulingPage() {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context, listen: false);
    if (formSettingsProvider.formSettings['guidance_scheduling_enabled'] == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GuidanceSchedulingPage(
            status: _schedulingStatus,
            userData: _currentUser,
            onStatusUpdate: (SchedulingStatus newStatus) {
              setState(() {
                _schedulingStatus = newStatus;
              });
            },
            onAppointmentApproved: () {
              _fetchAllNotifications();
            },
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Feature Disabled'),
          content: const Text('Guidance Scheduling is currently disabled by the administrator. Please contact your guidance counselor for more information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToGoodMoralRequestPage() {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context, listen: false);
    if (formSettingsProvider.formSettings['good_moral_request_enabled'] == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GoodMoralRequest(),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Feature Disabled'),
          content: const Text('Good Moral Request is currently disabled by the administrator. Please contact your guidance counselor for more information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _navigateToDASS21Page() {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context, listen: false);
    if (formSettingsProvider.formSettings['dass21_enabled'] != true) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Feature Disabled'),
          content: const Text('DASS-21 Form is currently disabled by the administrator. Please contact your guidance counselor for more information.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (_currentUser == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Missing user data'),
          content: const Text('User data is not available. Please login again.'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final int userId = _parseUserIdSafe();
    final String studentId = _parseStudentIdSafe();
    final String fullName = _parseFullNameSafe();
    final String program = _parseProgramSafe();
    final String major = _parseMajorSafe();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PsychExxam(
          userId: userId,
          studentId: studentId,
          fullName: fullName,
          program: program,
          major: major,
        ),
      ),
    );
  }

  List<NavigationRailDestination> _buildNavigationDestinations() {
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.home),
        label: Text('Home'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];
  }

  void _handleNavigation(int index) {
    if (index == 0) { // Home
      setState(() => _selectedIndex = 0);
    } else if (index == 1) { // Settings
      setState(() => _selectedIndex = 1);
    } else if (index == 2) { // Logout
      _handleLogout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context);
    final formSettings = formSettingsProvider.formSettings;
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar
          Container(
            color: const Color.fromARGB(255, 30, 182, 88),
            padding: const EdgeInsets.only(top: 45, bottom: 5, left: 16, right: 16),
            child: Row(
              children: [
                // Menu icon and Logo section
                IconButton(
                  icon: Icon(
                    _isSidebarVisible ? Icons.close : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSidebarVisible = !_isSidebarVisible;
                    });
                  },
                  tooltip: _isSidebarVisible ? 'Close sidebar' : 'Open sidebar',
                ),
                const SizedBox(width: 10),
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
                // Notifications
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: _showNotificationsDialog,
                      tooltip: 'Notifications',
                    ),
                    if (_allNotifications.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: Text(
                            '${_allNotifications.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Profile Circle
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
                                    _usernameInitial(),
                                    style: const TextStyle(fontSize: 32, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Username: ${_currentUser!['username'] ?? 'N/A'}'),
                              Text('Email: ${_currentUser!['email'] ?? 'N/A'}'),
                              Text('Role: ${_currentUser!['role'] ?? 'Student'}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                            TextButton(
                              onPressed: _handleLogout,
                              child: const Text('Logout',
                                style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      child: Text(
                        _usernameInitial(),
                        style: const TextStyle(
                          color: Color.fromARGB(255, 30, 182, 88),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      'assets/images/s_logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Smooth animated NavigationRail - Show/hide completely
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                      child: _isSidebarVisible
                          ? Container(
                              width: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.green.shade700, Colors.green.shade900],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(2, 0),
                                  ),
                                ],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Close button at top of sidebar
                                  // Removed as per user request
                                  Expanded(
                                    child: NavigationRail(
                                      extended: false,
                                      selectedIndex: _selectedIndex,
                                      onDestinationSelected: (int index) {
                                        _handleNavigation(index);
                                      },
                                      labelType: NavigationRailLabelType.none,
                                      backgroundColor: Colors.transparent,
                                      selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
                                      unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 24),
                                      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      unselectedLabelTextStyle: const TextStyle(color: Colors.white70),
                                      destinations: _buildNavigationDestinations(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_isSidebarVisible) const VerticalDivider(thickness: 1, width: 1, color: Colors.greenAccent),
                    // Main content area always visible
                    Expanded(
                      child: Stack(
                        children: [
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
                                        Colors.green.shade900.withOpacity(1.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: _selectedIndex == 0
                                ? SingleChildScrollView(
                                    child: Padding(
                                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02), // 1-inch equivalent padding
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Logo section
                                          Container(
                                            width: MediaQuery.of(context).size.width * 0.3,
                                            height: MediaQuery.of(context).size.width * 0.3,
                                            margin: const EdgeInsets.only(bottom: 32),
                                            constraints: const BoxConstraints(maxWidth: 250, maxHeight: 250),
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0),
                                                  blurRadius: 20,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ],
                                            ),
                                            clipBehavior: Clip.hardEdge,
                                            child: Image.asset(
                                              'assets/images/logonbg.png',
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Cards Column - Ladder layout
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width * 0.02), // 1-inch horizontal padding
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                // Answerable Forms Card - Only show if student has active forms
                                                if (_shouldShowAnswerableFormsCard())
                                                  Padding(
                                                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.blue.shade200.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Card(
                                                        margin: EdgeInsets.zero,
                                                        elevation: 0,
                                                        color: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(16),
                                                          onTap: _navigateToAnswerableFormsPage,
                                                          child: Container(
                                                            width: double.infinity,
                                                            padding: const EdgeInsets.all(24),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.assignment, size: 64, color: Colors.blue.shade700),
                                                                const SizedBox(height: 20),
                                                                const Text(
                                                                  'Answerable Forms',
                                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // Guidance Scheduling Card
                                                Padding(
                                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [Colors.green.shade50, Colors.green.shade100],
                                                        begin: Alignment.topLeft,
                                                        end: Alignment.bottomRight,
                                                      ),
                                                      borderRadius: BorderRadius.circular(16),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.green.shade200.withOpacity(0.3),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Card(
                                                      margin: EdgeInsets.zero,
                                                      elevation: 0,
                                                      color: Colors.transparent,
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: InkWell(
                                                        borderRadius: BorderRadius.circular(16),
                                                        onTap: _navigateToGuidanceSchedulingPage,
                                                        child: Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.all(24),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              Icon(Icons.calendar_month, size: 64, color: Colors.green.shade700),
                                                              const SizedBox(height: 20),
                                                              Text(
                                                                _schedulingStatus == SchedulingStatus.none
                                                                    ? 'Guidance Scheduling'
                                                                    : _schedulingStatus == SchedulingStatus.processing
                                                                        ? 'Request: Processing'
                                                                        : 'Request: Approved',
                                                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                                                textAlign: TextAlign.center,
                                                              ),
                                                              if (_schedulingStatus == SchedulingStatus.processing)
                                                                const Padding(
                                                                  padding: EdgeInsets.only(top: 8.0),
                                                                  child: CircularProgressIndicator(),
                                                                ),
                                                              if (_schedulingStatus == SchedulingStatus.approved)
                                                                const Padding(
                                                                  padding: EdgeInsets.only(top: 8.0),
                                                                  child: Icon(Icons.check_circle, color: Colors.green),
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Good Moral Request Card
                                                if (formSettings['good_moral_request_enabled'] == true)
                                                  Padding(
                                                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.orange.shade50, Colors.orange.shade100],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.orange.shade200.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Card(
                                                        margin: EdgeInsets.zero,
                                                        elevation: 0,
                                                        color: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(16),
                                                          onTap: _navigateToGoodMoralRequestPage,
                                                          child: Container(
                                                            width: double.infinity,
                                                            padding: const EdgeInsets.all(24),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.description, size: 64, color: Colors.orange.shade700),
                                                                const SizedBox(height: 20),
                                                                Text(
                                                                  'Request Good Moral',
                                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                // DASS-21 Card
                                                if (formSettings['dass21_enabled'] == true)
                                                  Padding(
                                                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        gradient: LinearGradient(
                                                          colors: [Colors.purple.shade50, Colors.purple.shade100],
                                                          begin: Alignment.topLeft,
                                                          end: Alignment.bottomRight,
                                                        ),
                                                        borderRadius: BorderRadius.circular(16),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.purple.shade200.withOpacity(0.3),
                                                            blurRadius: 8,
                                                            offset: const Offset(0, 4),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Card(
                                                        margin: EdgeInsets.zero,
                                                        elevation: 0,
                                                        color: Colors.transparent,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        child: InkWell(
                                                          borderRadius: BorderRadius.circular(16),
                                                          onTap: _navigateToDASS21Page,
                                                          child: Container(
                                                            width: double.infinity,
                                                            padding: const EdgeInsets.all(24),
                                                            child: Column(
                                                              mainAxisAlignment: MainAxisAlignment.center,
                                                              children: [
                                                                Icon(Icons.psychology, size: 64, color: Colors.purple.shade700),
                                                                const SizedBox(height: 20),
                                                                Text(
                                                                  'Psychological Examination',
                                                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                                                  textAlign: TextAlign.center,
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _selectedIndex == 1
                                    ? SettingsPage(userData: _currentUser)
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text('Settings Page'),
                                          const SizedBox(height: 20),
                                          if (_schedulingStatus == SchedulingStatus.processing)
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _schedulingStatus = SchedulingStatus.approved;
                                                });
                                              },
                                              child: const Text('Approve Request (Demo)'),
                                            ),
                                          if (_schedulingStatus == SchedulingStatus.approved)
                                            ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _schedulingStatus = SchedulingStatus.none;
                                                });
                                              },
                                              child: const Text('Reset Scheduling Status'),
                                            ),
                                        ],
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Help icon at bottom right
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.blueAccent,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Help'),
                          content: const Text('This is a demo app for PLSP Guidance Counseling. '
                              'Use the cards to navigate through different functionalities.'), 
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Help',
                    child: const Icon(Icons.help_outline, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
