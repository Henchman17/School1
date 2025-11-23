import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';
import '../settings.dart';
import 'counselor_dashboard.dart';
import 'counselor_students_page.dart';
import 'counselor_appointments_page.dart';

class CounselorSessionsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CounselorSessionsPage({super.key, this.userData});

  @override
  State<CounselorSessionsPage> createState() => _CounselorSessionsPageState();
}

class _CounselorSessionsPageState extends State<CounselorSessionsPage> {
  List<Map<String, dynamic>> sessions = [];
  bool isLoading = true;
  String errorMessage = '';
  String selectedFilter = 'All';
  int _selectedIndex = 3;

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/sessions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sessions = List<Map<String, dynamic>>.from(data['sessions'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load sessions';
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

  List<Map<String, dynamic>> get filteredSessions {
    if (selectedFilter == 'All') {
      return sessions;
    }
    return sessions.where((session) {
      return session['status'] == selectedFilter.toLowerCase();
    }).toList();
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final status = session['status'] ?? 'completed';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session['student_name'] ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        session['type'] ?? 'General Counseling',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  session['date'] ?? 'Date not set',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${session['start_time'] ?? 'Start'} - ${session['end_time'] ?? 'End'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session['notes'] ?? 'No session notes available',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (status == 'in_progress')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _endSession(session),
                      icon: const Icon(Icons.stop),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (status == 'completed')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _viewSessionDetails(session),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (status == 'completed')
                  const SizedBox(width: 8),
                if (status == 'completed')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addFollowUp(session),
                      icon: const Icon(Icons.add),
                      label: const Text('Follow-up'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      case 'scheduled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'in_progress':
        return Icons.play_circle_fill;
      case 'cancelled':
        return Icons.cancel;
      case 'scheduled':
        return Icons.schedule;
      default:
        return Icons.help;
    }
  }

  void _endSession(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: Text('Are you sure you want to end the session with ${session['student_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement session ending
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Session ended with ${session['student_name']}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  void _viewSessionDetails(Map<String, dynamic> session) {
    // TODO: Navigate to session details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing details for session with ${session['student_name']}')),
    );
  }

  void _addFollowUp(Map<String, dynamic> session) {
    // TODO: Navigate to follow-up scheduling page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Scheduling follow-up for ${session['student_name']}')),
    );
  }

  void _onDestinationSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CounselorDashboardPage(userData: widget.userData),
        ),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CounselorStudentsPage(userData: widget.userData),
        ),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CounselorAppointmentsPage(userData: widget.userData),
        ),
      );
    } else if (index == 4) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SettingsPage(userData: widget.userData),
        ),
      );
    } else if (index == 5) {
      _handleLogout();
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
        icon: Icon(Icons.event_note),
        label: Text('Sessions'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counseling Sessions'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => setState(() => selectedFilter = value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Sessions')),
              const PopupMenuItem(value: 'Completed', child: Text('Completed')),
              const PopupMenuItem(value: 'In Progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'Scheduled', child: Text('Scheduled')),
              const PopupMenuItem(value: 'Cancelled', child: Text('Cancelled')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Filter: $selectedFilter',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Icon(Icons.filter_list, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
      body: isLoading
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
                        onPressed: fetchSessions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchSessions,
                  child: ListView.builder(
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) => _buildSessionCard(filteredSessions[index]),
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to start new session page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Start new session functionality coming soon')),
          );
        },
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        child: const Icon(Icons.add),
      ),
    );
  }
}
