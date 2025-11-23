import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'student/guidance_scheduling_page.dart';
import 'student/answerable_forms.dart';
import 'student/good_moral_request.dart';
import 'login_page.dart';
import 'settings.dart';
import 'shared_enums.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_users_page.dart';
import 'admin/admin_appointments_page.dart';
import 'admin/admin_analytics_page.dart';
import 'admin/admin_re_admission_page.dart';
import 'admin/admin_discipline_page.dart';
import 'admin/admin_exit_interviews_page.dart';
import 'admin/admin_forms_page.dart';


class NavigationRailExample extends StatefulWidget {
  final Map<String, dynamic>? userData;
  
  const NavigationRailExample({super.key, this.userData});

  @override
  State<NavigationRailExample> createState() => _NavigationRailExampleState();
}

class _NavigationRailExampleState extends State<NavigationRailExample> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExtended = false; // For collapsible NavigationRail, set to false for default collapsed sidebar
  SchedulingStatus _schedulingStatus = SchedulingStatus.none;
  Map<String, dynamic>? _currentUser ;
  List<Map<String, dynamic>> _approvedAppointments = [];
  bool _isLoadingNotifications = false;

  static const String apiBaseUrl = 'http://192.168.1.10:8080';

  @override
  void initState() {
    super.initState();
    _currentUser  = widget.userData;
    _fetchApprovedAppointments();
  }

  Future<void> _fetchApprovedAppointments() async {
    if (_currentUser  == null) return;

    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      final userId = _currentUser !['id'];
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/appointments/approved?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _approvedAppointments = List<Map<String, dynamic>>.from(data['appointments'] ?? []);
          _isLoadingNotifications = false;
        });
      } else {
        setState(() {
          _approvedAppointments = [];
          _isLoadingNotifications = false;
        });
      }
    } catch (e) {
      setState(() {
        _approvedAppointments = [];
        _isLoadingNotifications = false;
      });
    }
  }

  void _handleLogout() {
    // Clear user data and navigate to login page
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
                (route) => false, // Remove all routes from stack
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
          title: const Text('Approved Requests'),
          content: SizedBox(
            width: double.maxFinite,
            child: _isLoadingNotifications
                ? const Center(child: CircularProgressIndicator())
                : _approvedAppointments.isEmpty
                    ? const Text('No approved requests.')
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _approvedAppointments.length,
                        itemBuilder: (context, index) {
                          final appointment = _approvedAppointments[index];
                          return ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text('Request ID: ${appointment['id']}'),
                            subtitle: Text('Student: ${appointment['student_name'] ?? 'N/A'}'),
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
    _fetchApprovedAppointments();
  }

  void _navigateToAnswerableFormsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnswerableForms(userData: _currentUser ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar
          Container(
            color: const Color.fromARGB(255, 30, 182, 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Menu icon and Logo section
                IconButton(
                  icon: Icon(
                    _isExtended ? Icons.menu_open : Icons.menu,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExtended = !_isExtended;
                    });
                  },
                  tooltip: _isExtended ? 'Collapse sidebar' : 'Expand sidebar',
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
                    if (_approvedAppointments.isNotEmpty)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade400, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade900.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          child: AnimatedScale(
                            scale: 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              '${_approvedAppointments.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Profile Circle
                if (_currentUser  != null)
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('User  Profile'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    _currentUser !['username']?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: const TextStyle(fontSize: 32, color: Colors.white),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Username: ${_currentUser !['username']}'),
                              Text('Email: ${_currentUser !['email'] ?? 'N/A'}'),
                              Text('Role: ${_currentUser !['role'] ?? 'Student'}'),
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
                        _currentUser !['username']?.substring(0, 1).toUpperCase() ?? 'U',
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
                          offset: Offset(0, 4),
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
                    // Smooth animated NavigationRail - Fixed to always show (collapsed or extended)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                      child: _isExtended
                          ? Container(
                              width: 260,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade400,
                                    Colors.teal.shade600,
                                    Colors.teal.shade800,
                                    Colors.teal.shade900,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.3, 0.7, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.shade900.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(4, 0),
                                  ),
                                  BoxShadow(
                                    color: Colors.teal.shade300.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                    spreadRadius: 2,
                                  ),
                                ],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                border: Border.all(
                                  color: Colors.teal.shade200.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  if (_currentUser?['role'] == 'admin')
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.admin_panel_settings, color: Colors.white),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Admin Panel',
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Expanded(
                                    child: NavigationRail(
                                      extended: true,
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
                                      indicatorColor: Colors.white.withOpacity(0.3),
                                      indicatorShape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.teal.shade200.withOpacity(0.5),
                                          width: 1,
                                        ),
                                      ),
                                      destinations: _buildAnimatedNavigationDestinations(),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              width: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.teal.shade400,
                                    Colors.teal.shade600,
                                    Colors.teal.shade800,
                                    Colors.teal.shade900,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: [0.0, 0.3, 0.7, 1.0],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.teal.shade900.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(4, 0),
                                  ),
                                  BoxShadow(
                                    color: Colors.teal.shade300.withOpacity(0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 0),
                                    spreadRadius: 2,
                                  ),
                                ],
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                                border: Border.all(
                                  color: Colors.teal.shade200.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                                child: NavigationRail(
                                extended: false,
                                selectedIndex: _selectedIndex,
                                onDestinationSelected: (int index) {
                                  _handleNavigation(index);
                                  setState(() => _isExtended = true);
                                },
                                labelType: NavigationRailLabelType.none,
                                backgroundColor: Colors.transparent,
                                selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
                                unselectedIconTheme: const IconThemeData(color: Colors.white70, size: 24),
                                indicatorColor: Colors.white.withOpacity(0.3),
                                indicatorShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: Colors.teal.shade200.withOpacity(0.5),
                                    width: 1,
                                  ),
                                ),
                                destinations: _buildAnimatedNavigationDestinations(),
                              ),
                            ),
                    ),
                    if (_isExtended) const VerticalDivider(thickness: 1, width: 1, color: Colors.greenAccent),
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
                                                  offset: Offset(0, 4),
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
                                                // Answerable Forms Card
                                                Padding(
                                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                  child: Card(
                                                    elevation: 4,
                                                    child: InkWell(
                                                      onTap: _navigateToAnswerableFormsPage,
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.all(24),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: const [
                                                            Icon(Icons.assignment, size: 64, color: Colors.blue),
                                                            SizedBox(height: 20),
                                                            Text(
                                                              'Answerable Forms',
                                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Guidance Scheduling Card - Only for students
                                                if (_currentUser ?['role'] == 'student')
                                                  Padding(
                                                    padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                    child: Card(
                                                      elevation: 4,
                                                      child: InkWell(
                                                        onTap: _navigateToGuidanceSchedulingPage,
                                                        child: Container(
                                                          width: double.infinity,
                                                          padding: const EdgeInsets.all(24),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Icon(Icons.calendar_month, size: 64, color: Colors.green),
                                                              const SizedBox(height: 20),
                                                              Text(
                                                                _schedulingStatus == SchedulingStatus.none
                                                                    ? 'Guidance Scheduling'
                                                                    : _schedulingStatus == SchedulingStatus.processing
                                                                        ? 'Request: Processing'
                                                                        : 'Request: Approved',
                                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                                                // Good Moral Request Card
                                                Padding(
                                                  padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01), // 0.5-inch padding between cards
                                                  child: Card(
                                                    elevation: 4,
                                                    child: InkWell(
                                                      onTap: _navigateToGoodMoralRequestPage,
                                                      child: Container(
                                                        width: double.infinity,
                                                        padding: const EdgeInsets.all(24),
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: const [
                                                            Icon(Icons.description, size: 64, color: Colors.orange),
                                                            SizedBox(height: 20),
                                                            Text(
                                                              'Good Moral Request',
                                                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                              textAlign: TextAlign.center,
                                                            ),
                                                          ],
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
                                    ? SettingsPage(userData: _currentUser )
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

  void _navigateToGuidanceSchedulingPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuidanceSchedulingPage(
          status: _schedulingStatus,
          userData: _currentUser ,
          onStatusUpdate: (SchedulingStatus newStatus) {
            setState(() {
              _schedulingStatus = newStatus;
            });
          },
          onAppointmentApproved: _refreshNotifications,
        ),
      ),
    );
  }
  
  void _navigateToGoodMoralRequestPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoodMoralRequest(),
      ),
    );
  }

  List<NavigationRailDestination> _buildNavigationDestinations() {
    final isAdmin = _currentUser ?['role'] == 'admin';
    final isCounselor = _currentUser ?['role'] == 'counselor';

    List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.home),
        label: Text('Home'),
      ),
    ];

    if (isAdmin) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Admin Dashboard'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Users'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.calendar_today),
          label: Text('Appointments'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assignment_return),
          label: Text('Re-admission'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.gavel),
          label: Text('Discipline'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.exit_to_app),
          label: Text('Exit Interviews'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assignment),
          label: Text('Forms & Records'),
        ),
      ]);
    }

    destinations.addAll([
      const NavigationRailDestination(
        icon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ]);

    // Debug print to verify item count
    print('User  role: ${_currentUser ?['role']}, Destinations count: ${destinations.length}');

    return destinations;
  }

  List<NavigationRailDestination> _buildNavigationDestinationsWithDividers() {
    final isAdmin = _currentUser ?['role'] == 'admin';

    List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.home),
        label: Text('Home'),
      ),
    ];

    if (isAdmin) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard),
          label: Text('Admin Dashboard'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.people),
          label: Text('Users'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.calendar_today),
          label: Text('Appointments'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assignment_return),
          label: Text('Re-admission'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.gavel),
          label: Text('Discipline'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.exit_to_app),
          label: Text('Exit Interviews'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.assignment),
          label: Text('Forms & Records'),
        ),
      ]);
    }

    // Add a divider
    destinations.add(
      NavigationRailDestination(
        icon: Container(
          height: 1,
          color: Colors.white.withOpacity(0.3),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        label: const SizedBox.shrink(),
      ),
    );

    destinations.addAll([
      const NavigationRailDestination(
        icon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ]);

    return destinations;
  }

  List<NavigationRailDestination> _buildAnimatedNavigationDestinations() {
    final isAdmin = _currentUser ?['role'] == 'admin';

    List<NavigationRailDestination> destinations = [
      NavigationRailDestination(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.home,
            color: _selectedIndex == 0 ? Colors.white : Colors.white70,
          ),
        ),
        label: Text('Home'),
      ),
    ];

    if (isAdmin) {
      destinations.addAll([
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.dashboard,
              color: _selectedIndex == 1 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Admin Dashboard'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.people,
              color: _selectedIndex == 2 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Users'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.calendar_today,
              color: _selectedIndex == 3 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Appointments'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.analytics,
              color: _selectedIndex == 4 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.assignment_return,
              color: _selectedIndex == 5 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Re-admission'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.gavel,
              color: _selectedIndex == 6 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Discipline'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.exit_to_app,
              color: _selectedIndex == 7 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Exit Interviews'),
        ),
        NavigationRailDestination(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.assignment,
              color: _selectedIndex == 8 ? Colors.white : Colors.white70,
            ),
          ),
          label: Text('Forms & Records'),
        ),
      ]);
    }

    // Add a divider
    destinations.add(
      NavigationRailDestination(
        icon: Container(
          height: 1,
          color: Colors.white.withOpacity(0.3),
          margin: const EdgeInsets.symmetric(horizontal: 16),
        ),
        label: const SizedBox.shrink(),
      ),
    );

    destinations.addAll([
      NavigationRailDestination(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.settings,
            color: _selectedIndex == (isAdmin ? 9 : 1) ? Colors.white : Colors.white70,
          ),
        ),
        label: Text('Settings'),
      ),
      NavigationRailDestination(
        icon: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            Icons.logout,
            color: _selectedIndex == (isAdmin ? 10 : 2) ? Colors.white : Colors.white70,
          ),
        ),
        label: Text('Logout'),
      ),
    ]);

    return destinations;
  }

  void _handleNavigation(int index) {
    final isAdmin = _currentUser ?['role'] == 'admin';
    final isCounselor = _currentUser ?['role'] == 'counselor';

    if (isAdmin) {
      switch (index) {
        case 0: // Home
          setState(() => _selectedIndex = 0);
          break;
        case 1: // Admin Dashboard
          _navigateToAdminDashboard();
          break;
        case 2: // Users
          _navigateToAdminUsers();
          break;
        case 3: // Appointments
          _navigateToAdminAppointments();
          break;
        case 4: // Analytics
          _navigateToAdminAnalytics();
          break;
        case 5: // Re-admission Cases
          _navigateToAdminReAdmission();
          break;
        case 6: // Discipline Cases
          _navigateToAdminDiscipline();
          break;
        case 7: // Exit Interviews
          _navigateToAdminExitInterviews();
          break;
        case 8: // Forms & Records
          _navigateToAdminForms();
          break;
        case 9: // Settings
          setState(() => _selectedIndex = 1);
          break;
        case 10: // Logout
          _handleLogout();
          break;
      }
    } else {
      if (index == 0) { // Home
        setState(() => _selectedIndex = 0);
      } else if (index == 1) { // Settings
        setState(() => _selectedIndex = 1);
      } else if (index == 2) { // Logout
        _handleLogout();
      }
    }

    // Optional: Collapse after selection (uncomment if desired)
     setState(() => _isExtended = false);
  }

  void _navigateToAdminDashboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminDashboardPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminUsers() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminUsersPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminAppointments() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminAppointmentsPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminAnalytics() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminAnalyticsPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminReAdmission() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminReAdmissionPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminDiscipline() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminDisciplinePage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminExitInterviews() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminExitInterviewsPage(userData: _currentUser ),
      ),
    );
  }

  void _navigateToAdminForms() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdminFormsPage(userData: _currentUser ),
      ),
    );
  }
}