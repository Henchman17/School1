import 'package:flutter/material.dart';
import '../config.dart';
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
  String selectedFilter = 'All';
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
      final response = await AppConfig.supabase
          .from('appointments')
          .select('*, students(first_name, last_name)')
          .eq('counselor_id', userId);

      setState(() {
        appointments = List<Map<String, dynamic>>.from(response.map((appointment) {
          final student = appointment['students'] as Map<String, dynamic>?;
          return {
            ...appointment,
            'student_name': student != null ? '${student['first_name']} ${student['last_name']}' : 'Unknown Student',
          };
        }));
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get filteredAppointments {
    List<Map<String, dynamic>> filtered = selectedFilter == 'All'
        ? appointments
        : appointments.where((appointment) {
            return appointment['apt_status'] == selectedFilter.toLowerCase();
          }).toList();

    // Sort by status priority: pending (1), confirmed/scheduled (2), cancelled (3), completed (4)
    filtered.sort((a, b) {
      int getPriority(String status) {
        switch (status) {
          case 'pending':
            return 1;
          case 'confirmed':
          case 'scheduled':
            return 2;
          case 'cancelled':
            return 3;
          case 'completed':
            return 4;
          default:
            return 5;
        }
      }

      int priorityA = getPriority(a['apt_status'] ?? '');
      int priorityB = getPriority(b['apt_status'] ?? '');

      return priorityA.compareTo(priorityB);
    });

    return filtered;
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final status = appointment['apt_status'] ?? 'pending';
    final approvalStatus = appointment['approval_status'] ?? 'approved';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final approvalColor = _getApprovalStatusColor(approvalStatus);

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
                        appointment['student_name'] ?? 'Unknown Student',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        appointment['type'] ?? 'General Counseling',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
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
                    if (approvalStatus != 'approved')
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: approvalColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          approvalStatus.toUpperCase(),
                          style: TextStyle(
                            color: approvalColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _editAppointment(appointment),
                  tooltip: 'Edit Appointment',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointment['date'] ?? 'Date not set',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  appointment['time'] ?? 'Time not set',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              appointment['notes'] ?? 'No additional notes',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
              ),
            ),
            if (appointment['rejection_reason'] != null && appointment['rejection_reason'].isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: ${appointment['rejection_reason']}',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (appointment['cancellation_reason'] != null && appointment['cancellation_reason'].isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancellation Reason: ${appointment['cancellation_reason']}',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (approvalStatus == 'pending') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveAppointment(appointment),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectAppointment(appointment),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status == 'pending' && approvalStatus == 'approved') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmAppointment(appointment),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status == 'confirmed') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeAppointment(appointment),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status == 'scheduled') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _completeAppointment(appointment),
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark as Completed'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status == 'cancelled') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _deleteAppointment(appointment),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ] else if (status != 'cancelled' && status != 'completed') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _cancelAppointment(appointment),
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeAppointment(Map<String, dynamic> appointment) async {
    try {
      await AppConfig.supabase
          .from('appointments')
          .update({'apt_status': 'completed'})
          .eq('id', appointment['id'])
          .eq('counselor_id', widget.userData?['id']);

      setState(() {
        appointment['apt_status'] = 'completed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment with ${appointment['student_name']} marked as completed')),
      );
      fetchAppointments(); // Refresh the list
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
      await AppConfig.supabase
          .from('appointments')
          .update({'apt_status': 'confirmed'})
          .eq('id', appointment['id'])
          .eq('counselor_id', widget.userData?['id']);

      setState(() {
        appointment['apt_status'] = 'confirmed';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment with ${appointment['student_name']} has been confirmed')),
      );
      fetchAppointments(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming appointment: $e')),
      );
    }
  }

  Future<void> _approveAppointment(Map<String, dynamic> appointment) async {
    try {
      await AppConfig.supabase
          .from('appointments')
          .update({'approval_status': 'approved'})
          .eq('id', appointment['id'])
          .eq('counselor_id', widget.userData?['id']);

      setState(() {
        appointment['approval_status'] = 'approved';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment with ${appointment['student_name']} has been approved')),
      );
      fetchAppointments(); // Refresh the list
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
                await AppConfig.supabase
                    .from('appointments')
                    .update({
                      'approval_status': 'rejected',
                      'rejection_reason': rejectionReason,
                    })
                    .eq('id', appointment['id'])
                    .eq('counselor_id', widget.userData?['id']);

                setState(() {
                  appointment['approval_status'] = 'rejected';
                  appointment['rejection_reason'] = rejectionReason;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment with ${appointment['student_name']} has been rejected')),
                );
                fetchAppointments(); // Refresh the list
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
                await AppConfig.supabase
                    .from('appointments')
                    .update({
                      'date': dateController.text,
                      'time': timeController.text,
                      'notes': notesController.text,
                    })
                    .eq('id', appointment['id'])
                    .eq('counselor_id', widget.userData?['id']);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment updated successfully')),
                );
                fetchAppointments(); // Refresh the list
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
                await AppConfig.supabase
                    .from('appointments')
                    .update({
                      'apt_status': 'cancelled',
                      'cancellation_reason': cancellationReason,
                    })
                    .eq('id', appointment['id'])
                    .eq('counselor_id', widget.userData?['id']);

                setState(() {
                  appointment['apt_status'] = 'cancelled';
                  appointment['cancellation_reason'] = cancellationReason;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment with ${appointment['student_name']} has been cancelled')),
                );
                fetchAppointments(); // Refresh the list
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
                await AppConfig.supabase
                    .from('appointments')
                    .delete()
                    .eq('id', appointment['id'])
                    .eq('counselor_id', widget.userData?['id']);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Appointment with ${appointment['student_name']} has been deleted')),
                );
                fetchAppointments(); // Refresh the list
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
