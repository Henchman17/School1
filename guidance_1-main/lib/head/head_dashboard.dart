import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';
import 'head_good_moral_page.dart';
import '../config.dart';

class HeadDashboardPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HeadDashboardPage({super.key, this.userData});

  @override
  State<HeadDashboardPage> createState() => _HeadDashboardPageState();
}

class _HeadDashboardPageState extends State<HeadDashboardPage> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  String errorMessage = '';
  int _selectedIndex = 0;
  Map<String, dynamic>? _currentUser;
  List<dynamic> goodMoralRequests = [];
  bool isLoadingRequests = false;
  String _searchQuery = '';

  static const String apiBaseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _currentUser = widget.userData;
    fetchDashboardData();
    fetchGoodMoralRequests();
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
      case 1: // Good Moral Requests
        setState(() => _selectedIndex = 1);
        break;
      case 2: // Logout
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
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/head/dashboard?head_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server is not responding. Please check your internet connection and try again.');
        },
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

  Future<void> fetchGoodMoralRequests() async {
    setState(() {
      isLoadingRequests = true;
    });

    try {
      final headId = widget.userData?['id'] ?? 0;
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/head/good-moral-requests?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server is not responding. Please check your internet connection and try again.');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          goodMoralRequests = data['requests'] ?? [];
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
      final headId = widget.userData?['id'] ?? 0;
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/head/good-moral-requests/$requestId/approve?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server is not responding. Please check your internet connection and try again.');
        },
      );
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        final message = (body is Map && body['message'] != null) ? body['message'] : 'Request approved successfully';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = (body is Map && body['error'] != null) ? body['error'] : 'Failed to approve request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
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

  Future<void> rejectRequest(int requestId) async {
    try {
      final headId = widget.userData?['id'] ?? 0;
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/head/good-moral-requests/$requestId/reject?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server is not responding. Please check your internet connection and try again.');
        },
      );
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        final message = (body is Map && body['message'] != null) ? body['message'] : 'Request rejected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final error = (body is Map && body['error'] != null) ? body['error'] : 'Failed to reject request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
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

  Widget _buildGoodMoralRequestsSection() {
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
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading requests...',
                    style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (goodMoralRequests.isEmpty) {
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
                    'No good moral requests',
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
              colors: [Colors.white, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade100.withOpacity(0.5),
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
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.verified_user,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Good Moral Requests',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: fetchGoodMoralRequests,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
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
                  hintText: 'Search by student name...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              // Filtered requests
              Builder(
                builder: (context) {
                  final filteredRequests = goodMoralRequests.where((request) {
                    final studentName = request['student_name']?.toString().toLowerCase() ?? '';
                    return studentName.contains(_searchQuery);
                  }).toList();

                  return Column(
                    children: filteredRequests.map((request) {
                      final requestId = request['id'];
                      final studentName = request['student_name'] ?? 'Unknown';
                      final course = request['course'] ?? 'N/A';
                      final purpose = request['purpose'] ?? 'N/A';
                      final status = request['approval_status'] ?? 'pending';
                      final currentStep = request['current_approval_step'] ?? 1;
                      final approvalsReceived = request['approvals_received'] ?? 0;
                      final createdAt = request['created_at'] ?? '';
                      final headRoleName = request['head_role_name'] ?? 'Unknown';
                      final headRoleDescription = request['head_role_description'] ?? '';

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
                                colors: [Colors.white, Colors.green.withOpacity(0.05)],
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
                                            color: Colors.green.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
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
                                    const Icon(Icons.description, size: 16, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Purpose: $purpose',
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
                                        onPressed: () => rejectRequest(requestId),
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

    // Use real data from API
    final totalRequests = dashboardData?['total_requests']?.toString() ?? '0';
    final pendingRequests = dashboardData?['pending_for_head']?.toString() ?? '0';
    final approvedRequests = dashboardData?['approved_requests']?.toString() ?? '0';
    final rejectedRequests = dashboardData?['rejected_requests']?.toString() ?? '0';
    final headRole = dashboardData?['head_role'] as Map<String, dynamic>?;
    final roleName = headRole?['name']?.toString() ?? 'Unknown';
    final roleDescription = headRole?['description']?.toString() ?? '';

    return Column(
      children: [
        Container(
          color: Colors.lightGreen.shade100,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'PLSP Head Dashboard',
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
                              'Total Requests',
                              totalRequests.toString(),
                              Icons.assignment,
                              [Colors.blue.shade400, Colors.blue.shade600, Colors.blue.shade800],
                              Icons.list,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Pending',
                              pendingRequests.toString(),
                              Icons.pending,
                              [Colors.orange.shade400, Colors.orange.shade600, Colors.orange.shade800],
                              Icons.hourglass_empty,
                            ),
                          ),
                          Expanded(
                            child: _buildAnimatedMetricCard(
                              'Approved',
                              approvedRequests.toString(),
                              Icons.check_circle,
                              [Colors.green.shade400, Colors.green.shade600, Colors.green.shade800],
                              Icons.verified,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Good Moral Requests
                    _buildGoodMoralRequestsSection(),

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
                  "PLSP Guidance Head",
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
                        : HeadGoodMoralPage(userData: _currentUser),
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
