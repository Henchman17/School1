import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page.dart';
import 'counselor_dashboard.dart';
import 'counselor_students_page.dart';
import 'counselor_sessions_page.dart';

class CounselorAppointmentsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CounselorAppointmentsPage({super.key, this.userData});

  @override
  State<CounselorAppointmentsPage> createState() => _CounselorAppointmentsPageState();
}

class _CounselorAppointmentsPageState extends State<CounselorAppointmentsPage> {
  List<Map<String, dynamic>> appointments = [];
  bool isLoading = true;
  String errorMessage = '';
  String? selectedFilter;
  int _selectedIndex = 2;

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/appointments?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          appointments = List<Map<String, dynamic>>.from(data['appointments'] ?? []);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load appointments';
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

  List<Map<String, dynamic>> get filteredAppointments {
    if (selectedFilter == null || selectedFilter!.isEmpty) {
      return appointments;
    }
    return appointments.where((appointment) {
      return appointment['apt_status']?.toString().toLowerCase() == selectedFilter!.toLowerCase();
    }).toList();
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['apt_status'] ?? 'pending';
    final approvalStatus = appointment['approval_status'] ?? 'approved';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final approvalColor = _getApprovalStatusColor(approvalStatus);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.grey.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200.withOpacity(0.5),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                      Icons.calendar_month,
                      color: Color(0xFF1E88E5),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Appointment #${appointment['id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E88E5),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          appointment['apt_status'] == 'scheduled' ? Icons.schedule :
                          appointment['apt_status'] == 'completed' ? Icons.check_circle :
                          appointment['apt_status'] == 'cancelled' ? Icons.cancel :
                          appointment['apt_status'] == 'overdue' ? Icons.warning :
                          appointment['apt_status'] == 'in_progress' ? Icons.play_circle :
                          Icons.help_outline,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (appointment['apt_status'] ?? 'pending').toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment['student_name'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.date_range, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment['appointment_date'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.description, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      appointment['purpose'] ?? 'N/A',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              if (appointment['course'] != null && appointment['course'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.school, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appointment['course'],
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
              if (appointment['notes'] != null && appointment['notes'].isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        appointment['notes'],
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.class_outlined, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Grade ${appointment['grade_level']} | Section ${appointment['section']}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Approval/Reject buttons for scheduled appointments
              if (appointment['apt_status']?.toString().toLowerCase() == 'scheduled' ||
                  appointment['apt_status']?.toString().toLowerCase() == 'pending')
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approveAppointment(appointment),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectAppointment(appointment),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              // Complete button for approved or confirmed appointments
              if (appointment['apt_status']?.toString().toLowerCase() == 'approved' ||
                  appointment['apt_status']?.toString().toLowerCase() == 'confirmed')
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => _completeAppointment(appointment),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Complete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _completeAppointment(Map<String, dynamic> appointment) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}/complete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'counselor_id': widget.userData?['id']}),
      );

      if (response.statusCode == 200) {
        setState(() {
          appointment['apt_status'] = 'completed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment with ${appointment['student_name']} marked as completed')),
        );
        fetchAppointments(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark appointment as completed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking appointment as completed: $e')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'cancelled':
        return Icons.cancel;
      case 'completed':
        return Icons.done_all;
      default:
        return Icons.help;
    }
  }

  Color _getApprovalStatusColor(String approvalStatus) {
    switch (approvalStatus) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _confirmAppointment(Map<String, dynamic> appointment) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'counselor_id': widget.userData?['id']}),
      );

      if (response.statusCode == 200) {
        setState(() {
          appointment['apt_status'] = 'confirmed';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment with ${appointment['student_name']} has been confirmed')),
        );
        fetchAppointments(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to confirm appointment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming appointment: $e')),
      );
    }
  }

  Future<void> _approveAppointment(Map<String, dynamic> appointment) async {
    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'counselor_id': widget.userData?['id']}),
      );

      if (response.statusCode == 200) {
        setState(() {
          appointment['approval_status'] = 'approved';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Appointment with ${appointment['student_name']} has been approved')),
        );
        fetchAppointments(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to approve appointment')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving appointment: $e')),
      );
    }
  }

  Future<void> _rejectAppointment(Map<String, dynamic> appointment) async {
    final TextEditingController rejectionReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Appointment - ${appointment['student_name']}'),
        content: TextField(
          controller: rejectionReasonController,
          decoration: const InputDecoration(
            labelText: 'Rejection Reason',
            hintText: 'Enter reason for rejection',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final rejectionReason = rejectionReasonController.text.trim();
              if (rejectionReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Rejection reason cannot be empty')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final response = await http.put(
                  Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}/reject'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'counselor_id': widget.userData?['id'],
                    'rejection_reason': rejectionReason,
                  }),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    appointment['approval_status'] = 'rejected';
                    appointment['rejection_reason'] = rejectionReason;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment with ${appointment['student_name']} has been rejected')),
                  );
                  fetchAppointments(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to reject appointment')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error rejecting appointment: $e')),
                );
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
  
  void _editAppointment(Map<String, dynamic> appointment) {
    final TextEditingController dateController = TextEditingController(text: appointment['date'] ?? '');
    final TextEditingController timeController = TextEditingController(text: appointment['time'] ?? '');
    final TextEditingController notesController = TextEditingController(text: appointment['notes'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Appointment - ${appointment['student_name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time',
                  hintText: 'HH:MM',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional notes...',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final response = await http.put(
                  Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'date': dateController.text,
                    'time': timeController.text,
                    'notes': notesController.text,
                    'counselor_id': widget.userData?['id'],
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment updated successfully')),
                  );
                  fetchAppointments(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to update appointment')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating appointment: $e')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(Map<String, dynamic> appointment) async {
    final TextEditingController cancellationReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please write a letter to the student explaining the reason for cancellation of the appointment with ${appointment['student_name']}.'),
            const SizedBox(height: 12),
            TextField(
              controller: cancellationReasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'Enter the reason for cancellation',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cancellationReason = cancellationReasonController.text.trim();
              if (cancellationReason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cancellation reason cannot be empty')),
                );
                return;
              }
              Navigator.pop(context);
              try {
                final response = await http.put(
                  Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}/cancel'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'counselor_id': widget.userData?['id'],
                    'cancellation_reason': cancellationReason,
                  }),
                );

                if (response.statusCode == 200) {
                  setState(() {
                    appointment['apt_status'] = 'cancelled';
                    appointment['cancellation_reason'] = cancellationReason;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment with ${appointment['student_name']} has been cancelled')),
                  );
                  fetchAppointments(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to cancel appointment')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error cancelling appointment: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm Cancellation'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAppointment(Map<String, dynamic> appointment) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to permanently delete the appointment with ${appointment['student_name']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final response = await http.delete(
                  Uri.parse('$apiBaseUrl/api/counselor/appointments/${appointment['id']}'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({'counselor_id': widget.userData?['id']}),
                );

                if (response.statusCode == 200) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Appointment with ${appointment['student_name']} has been deleted')),
                  );
                  fetchAppointments(); // Refresh the list
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to delete appointment')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting appointment: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
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
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CounselorSessionsPage(userData: widget.userData),
        ),
      );
    } else if (index == 4) {
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
        icon: Icon(Icons.logout),
        label: Text('Logout'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          // Top header bar
          Container(
            color: const Color.fromARGB(255, 30, 182, 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  "Appointment Management",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) => setState(() => selectedFilter = value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'All', child: Text('All Appointments')),
                    const PopupMenuItem(value: 'Pending', child: Text('Pending')),
                    const PopupMenuItem(value: 'Scheduled', child: Text('Scheduled')),
                    const PopupMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    const PopupMenuItem(value: 'Completed', child: Text('Completed')),
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
          ),
          Expanded(
          child: Row(
            children: [
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
                                  onPressed: fetchAppointments,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: fetchAppointments,
                            child: ListView.builder(
                              itemCount: filteredAppointments.length,
                              itemBuilder: (context, index) => _buildAppointmentCard(filteredAppointments[index]),
                            ),
                          ),
              ),
            ],
          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to schedule new appointment page
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Schedule new appointment functionality coming soon')),
          );
        },
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        child: const Icon(Icons.add),
      ),
    );
  }
}
