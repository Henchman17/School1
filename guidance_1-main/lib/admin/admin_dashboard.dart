import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';
import 'admin_users_page.dart';
import 'admin_appointments_page.dart';
import 'admin_analytics_page.dart';
import 'admin_re_admission_page.dart';
import 'admin_discipline_page.dart';
import 'admin_exit_interviews_page.dart';
import 'admin_forms_page.dart';
import 'admin_good_moral_requests_page.dart';

class AdminDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminDashboardPage({super.key, this.userData});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String errorMessage = '';
  int _selectedIndex = 0;
  Map<String, dynamic>? _currentUser;
  List<dynamic> credentialChangeRequests = [];
  bool isLoadingRequests = false;
  String _searchQuery = '';
  List<dynamic> recentActivities = [];
  bool isLoadingActivities = false;
  String activitiesErrorMessage = '';

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userData;
    fetchDashboardData();
    fetchCredentialChangeRequests();
    fetchRecentActivities();
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

  List<NavigationRailDestination> _buildNavigationDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people),
        label: Text('Users'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.calendar_today),
        label: Text('Counseling'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.analytics),
        label: Text('Analytics'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assignment_return),
        label: Text('Re-admission'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.gavel),
        label: Text('Discipline'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.exit_to_app),
        label: Text('Exit Interviews'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.assignment),
        label: Text('Forms & Records'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.verified_user),
        label: Text('Good Moral Requests'),
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
      case 1: // Users
        setState(() => _selectedIndex = 1);
        break;
      case 2: // Counseling
        setState(() => _selectedIndex = 2);
        break;
      case 3: // Analytics
        setState(() => _selectedIndex = 3);
        break;
      case 4: // Re-admission Cases
        setState(() => _selectedIndex = 4);
        break;
      case 5: // Discipline Cases
        setState(() => _selectedIndex = 5);
        break;
      case 6: // Exit Interviews
        setState(() => _selectedIndex = 6);
        break;
      case 7: // Forms & Records
        setState(() => _selectedIndex = 7);
        break;
      case 8: // Good Moral Requests
        setState(() => _selectedIndex = 8);
        break;
      case 9: // Logout
        _handleLogout();
        break;
    }
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/dashboard?user_id=$userId'),
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

  Future<void> fetchCredentialChangeRequests() async {
    setState(() {
      isLoadingRequests = true;
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/credential-change-requests?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          credentialChangeRequests = data['requests'] ?? [];
          isLoadingRequests = false;
        });
      } else {
        setState(() {
          isLoadingRequests = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoadingRequests = false;
      });
    }
  }

  Future<void> approveRequest(int requestId) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/credential-change-requests/$requestId/approve?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchCredentialChangeRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve request'),
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

  Future<void> rejectRequest(int requestId, String reason) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/credential-change-requests/$requestId?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': 'rejected', 'admin_notes': reason}),
      );

      if (response.statusCode == 200) {
        fetchCredentialChangeRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject request'),
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

  Future<void> fetchRecentActivities() async {
    setState(() {
      isLoadingActivities = true;
      activitiesErrorMessage = '';
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/recent-activities?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          recentActivities = data['activities'] ?? [];
          isLoadingActivities = false;
        });
      } else {
        setState(() {
          activitiesErrorMessage = 'Failed to load recent activities';
          isLoadingActivities = false;
        });
      }
    } catch (e) {
      setState(() {
        activitiesErrorMessage = 'Error: $e';
        isLoadingActivities = false;
      });
    }
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 1),
      ),
      child: Container(
        height: 300, // Added fixed height to make cards taller
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: color.withOpacity(0.05),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
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

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconString) {
    switch (iconString) {
      case 'person_add':
        return Icons.person_add;
      case 'calendar_today':
        return Icons.calendar_today;
      case 'edit':
        return Icons.edit;
      default:
        return Icons.info;
    }
  }

  Color _getColorFromString(String colorString) {
    switch (colorString) {
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildRecentActivity() {
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
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoadingActivities)
              const Center(child: CircularProgressIndicator())
            else if (activitiesErrorMessage.isNotEmpty)
              Center(child: Text(activitiesErrorMessage))
            else if (recentActivities.isEmpty)
              const Center(child: Text('No recent activities'))
            else
              Column(
                children: recentActivities.map((activity) {
                  IconData icon = _getIconFromString(activity['icon'] ?? 'info');
                  Color color = _getColorFromString(activity['color'] ?? 'grey');
                  return _buildActivityItem(
                    activity['title'] ?? 'Activity',
                    activity['description'] ?? '',
                    activity['time'] ?? '',
                    icon,
                    color,
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }



  Widget _buildCredentialChangeRequestsSection() {
    if (isLoadingRequests) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading requests...',
                    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (credentialChangeRequests.isEmpty) {
      return AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 500),
        child: Card(
          elevation: 6,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [Colors.grey.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No pending credential change requests',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Card(
        elevation: 8,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.assignment_turned_in,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Credential Change Requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: fetchCredentialChangeRequests,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Search bar
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by student name or request type...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              // Filtered requests
              Builder(
                builder: (context) {
                  final filteredRequests = credentialChangeRequests.where((request) {
                    final firstName = request['first_name']?.toString().toLowerCase() ?? '';
                    final lastName = request['last_name']?.toString().toLowerCase() ?? '';
                    final studentName = '$firstName $lastName'.trim();
                    final requestType = request['request_type']?.toString().toLowerCase() ?? '';
                    return studentName.contains(_searchQuery) || requestType.contains(_searchQuery);
                  }).toList();

                  if (filteredRequests.length > 10) {
                    return Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: filteredRequests.map((request) {
                            final requestId = request['id'];
                            final firstName = request['first_name'] ?? '';
                            final lastName = request['last_name'] ?? '';
                            final studentName = '$firstName $lastName'.trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();
                            final requestType = request['request_type'] ?? 'N/A';
                            final currentValue = request['current_value'] ?? '';
                            final newValue = request['new_value'] ?? '';
                            final requestedChange = '$requestType: $currentValue → $newValue';
                            final status = request['status'] ?? 'pending';
                            final createdAt = request['created_at'] ?? '';

                            // Determine icon and color based on request type
                            IconData requestIcon;
                            Color requestColor;
                            switch (requestType) {
                              case 'username':
                                requestIcon = Icons.person;
                                requestColor = Colors.blue;
                                break;
                              case 'email':
                                requestIcon = Icons.email;
                                requestColor = Colors.green;
                                break;
                              case 'password':
                                requestIcon = Icons.lock;
                                requestColor = Colors.red;
                                break;
                              case 'student_id':
                                requestIcon = Icons.badge;
                                requestColor = Colors.purple;
                                break;
                              default:
                                requestIcon = Icons.help;
                                requestColor = Colors.grey;
                            }

                            // Status color
                            Color statusColor;
                            switch (status) {
                              case 'pending':
                                statusColor = Colors.orange;
                                break;
                              case 'approved':
                                statusColor = Colors.green;
                                break;
                              case 'rejected':
                                statusColor = Colors.red;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }

                            return AnimatedOpacity(
                              opacity: 1.0,
                              duration: const Duration(milliseconds: 300),
                              child: Card(
                                elevation: 4,
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      colors: [Colors.white, requestColor.withOpacity(0.05)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: requestColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Icon(requestIcon, color: requestColor, size: 20),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                'Request #$requestId',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Chip(
                                            label: Text(
                                              status.toUpperCase(),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                            backgroundColor: statusColor,
                                            elevation: 2,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Student: $studentName',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(requestIcon, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Change: $requestedChange',
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Submitted: $createdAt',
                                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      if (status == 'pending')
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            OutlinedButton.icon(
                                              onPressed: () async {
                                                final reasonController = TextEditingController();
                                                final reason = await showDialog<String>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text('Reject Request'),
                                                    content: TextField(
                                                      controller: reasonController,
                                                      decoration: const InputDecoration(
                                                        hintText: 'Reason for rejection',
                                                      ),
                                                      maxLines: 3,
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text('Cancel'),
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () => Navigator.of(context).pop(reasonController.text),
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                        child: const Text('Reject'),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                                if (reason != null && reason.isNotEmpty) {
                                                  rejectRequest(requestId, reason);
                                                }
                                              },
                                              icon: const Icon(Icons.close, size: 16),
                                              label: const Text('Reject'),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.red),
                                                foregroundColor: Colors.red,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: () => approveRequest(requestId),
                                              icon: const Icon(Icons.check, size: 16),
                                              label: const Text('Approve'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                elevation: 4,
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  } else {
                    return Column(
                      children: filteredRequests.map((request) {
                        final requestId = request['id'];
                        final firstName = request['first_name'] ?? '';
                        final lastName = request['last_name'] ?? '';
                        final studentName = '$firstName $lastName'.trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();
                        final requestType = request['request_type'] ?? 'N/A';
                        final currentValue = request['current_value'] ?? '';
                        final newValue = request['new_value'] ?? '';
                        final requestedChange = '$requestType: $currentValue → $newValue';
                        final status = request['status'] ?? 'pending';
                        final createdAt = request['created_at'] ?? '';

                        // Determine icon and color based on request type
                        IconData requestIcon;
                        Color requestColor;
                        switch (requestType) {
                          case 'username':
                            requestIcon = Icons.person;
                            requestColor = Colors.blue;
                            break;
                          case 'email':
                            requestIcon = Icons.email;
                            requestColor = Colors.green;
                            break;
                          case 'password':
                            requestIcon = Icons.lock;
                            requestColor = Colors.red;
                            break;
                          case 'student_id':
                            requestIcon = Icons.badge;
                            requestColor = Colors.purple;
                            break;
                          default:
                            requestIcon = Icons.help;
                            requestColor = Colors.grey;
                        }

                        // Status color
                        Color statusColor;
                        switch (status) {
                          case 'pending':
                            statusColor = Colors.orange;
                            break;
                          case 'approved':
                            statusColor = Colors.green;
                            break;
                          case 'rejected':
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.grey;
                        }

                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: LinearGradient(
                                  colors: [Colors.white, requestColor.withOpacity(0.05)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: requestColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(requestIcon, color: requestColor, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Request #$requestId',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Chip(
                                        label: Text(
                                          status.toUpperCase(),
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                        backgroundColor: statusColor,
                                        elevation: 2,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Student: $studentName',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(requestIcon, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Change: $requestedChange',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Submitted: $createdAt',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  if (status == 'pending')
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () async {
                                            final reasonController = TextEditingController();
                                            final reason = await showDialog<String>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Reject Request'),
                                                content: TextField(
                                                  controller: reasonController,
                                                  decoration: const InputDecoration(
                                                    hintText: 'Reason for rejection',
                                                  ),
                                                  maxLines: 3,
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.of(context).pop(reasonController.text),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                                    child: const Text('Reject'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (reason != null && reason.isNotEmpty) {
                                              rejectRequest(requestId, reason);
                                            }
                                          },
                                          icon: const Icon(Icons.close, size: 16),
                                          label: const Text('Reject'),
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(color: Colors.red),
                                            foregroundColor: Colors.red,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        ElevatedButton.icon(
                                          onPressed: () => approveRequest(requestId),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 4,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
            ],
          ),
        ),
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

    // Mock data for demonstration
    final userStats = dashboardData?['user_statistics'] ?? {'total_users': '156', 'new_users_today': '0'};
    final appointmentStats = dashboardData?['appointment_statistics'] ?? {'total_appointments': '89', 'scheduled': '45', 'completed': '32', 'cancelled': '12'};

    return Column(
      children: [
        Container(
          color: Colors.lightBlue.shade100,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PLSP Admin Dashboard',
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
                              'Total Users',
                              userStats['total_users']?.toString() ?? 'N/A',
                              Icons.people_alt_rounded,
                              [Colors.blue.shade400, Colors.blue.shade600, Colors.blue.shade800],
                              Icons.group_add,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'New Today',
                              userStats['new_users_today']?.toString() ?? 'N/A',
                              Icons.trending_up,
                              [Colors.orange.shade400, Colors.orange.shade600, Colors.orange.shade800],
                              Icons.person_add,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Total Appointments',
                              appointmentStats['total_appointments']?.toString() ?? 'N/A',
                              Icons.calendar_month_rounded,
                              [Colors.purple.shade400, Colors.purple.shade600, Colors.purple.shade800],
                              Icons.schedule,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Exit Interviews',
                              dashboardData?['exit_interview_statistics']?['total_exit_interviews']?.toString() ?? 'N/A',
                              Icons.exit_to_app,
                              [Colors.teal.shade400, Colors.teal.shade600, Colors.teal.shade800],
                              Icons.assignment_turned_in,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Recent Activity
                    _buildRecentActivity(),

                    // Credential Change Requests
                    _buildCredentialChangeRequestsSection(),

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
                  "PLSP Guidance Admin",
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
                            ? AdminUsersPage(userData: _currentUser)
                            : _selectedIndex == 2
                                ? AdminAppointmentsPage(userData: _currentUser)
                                : _selectedIndex == 3
                                    ? AdminAnalyticsPage(userData: _currentUser)
                                    : _selectedIndex == 4
                                        ? AdminReAdmissionPage(userData: _currentUser)
                                        : _selectedIndex == 5
                                            ? AdminDisciplinePage(userData: _currentUser)
                                            : _selectedIndex == 6
                                                ? AdminExitInterviewsPage(userData: _currentUser)
                                                : _selectedIndex == 7
                                                    ? AdminFormsPage(userData: _currentUser)
                                                    : AdminGoodMoralRequestsPage(userData: _currentUser),
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
