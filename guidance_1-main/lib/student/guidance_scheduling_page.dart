import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../shared_enums.dart';
import '../config.dart';

class GuidanceSchedulingPage extends StatefulWidget {
  final SchedulingStatus status;
  final Map<String, dynamic>? userData;
  final Function(SchedulingStatus)? onStatusUpdate;
  final VoidCallback? onAppointmentApproved;

  const GuidanceSchedulingPage({
    super.key,
    required this.status,
    this.userData,
    this.onStatusUpdate,
    this.onAppointmentApproved,
  });

  @override
  State<GuidanceSchedulingPage> createState() => _GuidanceSchedulingPageState();
}

class _GuidanceSchedulingPageState extends State<GuidanceSchedulingPage> {
  final _formKey = GlobalKey<FormState>();
  String studentName = '';
  String reason = '';
  String course = '';
  String? selectedTimeSlot;
  DateTime? date;
  bool _isSubmitting = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _appointments = [];
  bool _isLoadingAppointments = true;
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;
  String _selectedReasonType = '';
  String _customReason = '';

  @override
  void initState() {
    super.initState();
    // Pre-populate student name from user data
    if (widget.userData != null) {
      studentName = widget.userData!['name'] ?? widget.userData!['first_name'] ?? '';
      if (widget.userData!['last_name'] != null && studentName.isNotEmpty) {
        studentName += ' ${widget.userData!['last_name']}';
      }
    }
    _fetchAppointments();
    _fetchCourses();
  }

  Future<void> _fetchAppointments() async {
    print('DEBUG: _fetchAppointments called');
    print('DEBUG: widget.userData = ${widget.userData}');
    print('DEBUG: widget.userData?[\'id\'] = ${widget.userData?['id']}');

    if (widget.userData?['id'] == null) {
      print('DEBUG: userData id is null, returning');
      return;
    }

    setState(() {
      _isLoadingAppointments = true;
    });

    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final url = '$baseUrl/api/appointments?user_id=${widget.userData!['id']}';
      print('DEBUG: Making API call to: $url');

      final response = await http.get(Uri.parse(url));

      print('DEBUG: API Response Status: ${response.statusCode}');
      print('DEBUG: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final appointments = List<Map<String, dynamic>>.from(data['appointments'] ?? []);
        print('DEBUG: Retrieved ${appointments.length} appointments');

        // Print details of each appointment
        for (var i = 0; i < appointments.length; i++) {
          print('DEBUG: Appointment $i: ${appointments[i]}');
        }

        // Sort appointments: pending first, then approved, then others, by date descending
        appointments.sort((a, b) {
          int priorityA = _getAppointmentPriority(a['apt_status']);
          int priorityB = _getAppointmentPriority(b['apt_status']);
          if (priorityA != priorityB) return priorityA.compareTo(priorityB);
          DateTime dateA = DateTime.parse(a['appointment_date']);
          DateTime dateB = DateTime.parse(b['appointment_date']);
          return dateB.compareTo(dateA); // newest first
        });

        setState(() {
          _appointments = appointments;
          _isLoadingAppointments = false;
        });
      } else {
        setState(() {
          _isLoadingAppointments = false;
        });
        print('Failed to fetch appointments: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoadingAppointments = false;
      });
      print('Error fetching appointments: $e');
    }
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoadingCourses = true;
    });

    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$baseUrl/api/courses'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _courses = List<Map<String, dynamic>>.from(data['courses'] ?? []);
          _isLoadingCourses = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load courses';
          _isLoadingCourses = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoadingCourses = false;
      });
    }
  }

  int _getAppointmentPriority(String status) {
    if (status == 'pending') return 1;
    if (status == 'approved') return 2;
    return 3;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      print('Form validated. StudentName: $studentName, Course: $course, Reason: $reason, Date: $date, Time Slot: $selectedTimeSlot');
      print('UserData: ${widget.userData}');

      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      try {
        final timeOfDay = _getTimeOfDayFromSlot(selectedTimeSlot!);
        final appointmentDate = DateTime(date!.year, date!.month, date!.day, timeOfDay.hour, timeOfDay.minute);

        print('Appointment Date: $appointmentDate');
        print('Selected Time Slot: $selectedTimeSlot');

        final requestBody = {
          'user_id': widget.userData?['id'],
          'counselor_id': 2, // Assign counselor later
          'appointment_date': appointmentDate.toIso8601String(),
          'purpose': reason,
          'course': course,
          'apt_status': 'pending',
          'approval_status': 'pending',
        };

        print('Request Body: $requestBody');

        final baseUrl = await AppConfig.apiBaseUrl;
        final response = await http.post(
          Uri.parse('$baseUrl/api/appointments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('Response Status: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 200) {
          // Success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment scheduled successfully!')),
          );
          widget.onStatusUpdate?.call(SchedulingStatus.processing);
          // Refresh appointments list
          await _fetchAppointments();
          // Don't pop the navigator so user can see the new appointment
        } else {
          final error = jsonDecode(response.body);
          setState(() {
            _errorMessage = error['error'] ?? 'Failed to schedule appointment';
          });
        }
      } catch (e) {
        print('Exception: $e');
        setState(() {
          _errorMessage = 'Error: $e';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    } else {
      print('Form validation failed');
    }
  }

  final List<String> availableTimeSlots = [
    '8:00 AM - 9:00 AM',
    '9:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '1:00 PM - 2:00 PM',
    '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM',
    '4:00 PM - 5:00 PM',
  ];

  TimeOfDay _getTimeOfDayFromSlot(String slot) {
    switch (slot) {
      case '8:00 AM - 9:00 AM':
        return const TimeOfDay(hour: 8, minute: 0);
      case '9:00 AM - 10:00 AM':
        return const TimeOfDay(hour: 9, minute: 0);
      case '10:00 AM - 11:00 AM':
        return const TimeOfDay(hour: 10, minute: 0);
      case '11:00 AM - 12:00 PM':
        return const TimeOfDay(hour: 11, minute: 0);
      case '1:00 PM - 2:00 PM':
        return const TimeOfDay(hour: 13, minute: 0);
      case '2:00 PM - 3:00 PM':
        return const TimeOfDay(hour: 14, minute: 0);
      case '3:00 PM - 4:00 PM':
        return const TimeOfDay(hour: 15, minute: 0);
      case '4:00 PM - 5:00 PM':
        return const TimeOfDay(hour: 16, minute: 0);
      default:
        return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String _getTimeSlotFromDateTime(DateTime dateTime) {
    final hour = dateTime.hour;
    switch (hour) {
      case 8:
        return '8:00 AM - 9:00 AM';
      case 9:
        return '9:00 AM - 10:00 AM';
      case 10:
        return '10:00 AM - 11:00 AM';
      case 11:
        return '11:00 AM - 12:00 PM';
      case 13:
        return '1:00 PM - 2:00 PM';
      case 14:
        return '2:00 PM - 3:00 PM';
      case 15:
        return '3:00 PM - 4:00 PM';
      case 16:
        return '4:00 PM - 5:00 PM';
      default:
        return '9:00 AM - 10:00 AM';
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      selectableDayPredicate: (DateTime day) {
        // Only allow Monday to Friday (1 = Monday, 5 = Friday)
        return day.weekday >= 1 && day.weekday <= 5;
      },
    );
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
    }
  }

  void _showEditAppointmentDialog(Map<String, dynamic> appointment) {
    final TextEditingController purposeController = TextEditingController(text: appointment['purpose']);
    final TextEditingController courseController = TextEditingController(text: appointment['course']);
    final TextEditingController notesController = TextEditingController(text: appointment['notes'] ?? '');

    DateTime selectedDate = DateTime.parse(appointment['appointment_date']);
    String selectedTimeSlot = _getTimeSlotFromDateTime(selectedDate);

    String selectedReasonType = '';
    String customReason = '';

    // Initialize reason type based on existing purpose
    if (appointment['purpose'] == 'Psychological Examination' ||
        appointment['purpose'] == 'Discipline Case') {
      selectedReasonType = appointment['purpose'];
    } else {
      selectedReasonType = 'Other';
      customReason = appointment['purpose'] ?? '';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Appointment'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Reason for Counseling'),
                      value: selectedReasonType.isNotEmpty ? selectedReasonType : null,
                      items: const [
                        DropdownMenuItem<String>(
                          value: 'Psychological Examination',
                          child: Text('Psychological Examination'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Discipline Case',
                          child: Text('Discipline Case'),
                        ),
                        DropdownMenuItem<String>(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedReasonType = value ?? '';
                          if (selectedReasonType != 'Other') {
                            customReason = '';
                            purposeController.text = selectedReasonType;
                          } else {
                            purposeController.text = customReason;
                          }
                        });
                      },
                    ),
                    if (selectedReasonType == 'Other') ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: customReason,
                        decoration: const InputDecoration(labelText: 'Specify Reason'),
                        onChanged: (value) {
                          setState(() {
                            customReason = value;
                            purposeController.text = value;
                          });
                        },
                      ),
                    ],
                    TextFormField(
                      controller: courseController,
                      decoration: const InputDecoration(labelText: 'Course'),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 150,
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Time Slot',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedTimeSlot,
                            items: availableTimeSlots.map((slot) {
                              return DropdownMenuItem<String>(
                                value: slot,
                                child: Text(slot),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedTimeSlot = value ?? selectedTimeSlot;
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: InkWell(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2100),
                                selectableDayPredicate: (DateTime day) {
                                  return day.weekday >= 1 && day.weekday <= 5;
                                },
                              );
                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                              ),
                              child: Text('${selectedDate.month}/${selectedDate.day}/${selectedDate.year}'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: 'Notes (Optional)'),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final timeOfDay = _getTimeOfDayFromSlot(selectedTimeSlot);
                    _updateAppointment(
                      appointment['id'],
                      purposeController.text,
                      courseController.text,
                      DateTime(selectedDate.year, selectedDate.month, selectedDate.day, timeOfDay.hour, timeOfDay.minute),
                      notesController.text,
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteAppointmentDialog(Map<String, dynamic> appointment) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Appointment'),
          content: const Text('Are you sure you want to delete this appointment? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _deleteAppointment(appointment['id']),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAppointment(int appointmentId, String purpose, String course, DateTime appointmentDate, String notes) async {
    try {
      final requestBody = {
        'user_id': widget.userData?['id'],
        'appointment_date': appointmentDate.toIso8601String(),
        'purpose': purpose,
        'course': course,
        'notes': notes,
      };

      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/appointments/$appointmentId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment updated successfully!')),
        );
        await _fetchAppointments(); // Refresh the list
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update appointment: ${error['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating appointment: $e')),
      );
    }
  }

  Future<void> _deleteAppointment(int appointmentId) async {
    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.delete(
        Uri.parse('$baseUrl/api/appointments/$appointmentId?user_id=${widget.userData?['id']}'),
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment deleted successfully!')),
        );
        await _fetchAppointments(); // Refresh the list
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete appointment: ${error['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting appointment: $e')),
      );
    }
  }

  Future<void> _approveAppointment(Map<String, dynamic> appointment) async {
    try {
      final baseUrl = await AppConfig.apiBaseUrl;
      final response = await http.put(
        Uri.parse('$baseUrl/api/appointments/${appointment['id']}/approve'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': widget.userData?['id'],
          'counselor_id': widget.userData?['id'], // Assuming counselor is approving
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment approved successfully!')),
        );
        await _fetchAppointments(); // Refresh the list
        widget.onAppointmentApproved?.call();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve appointment: ${error['error']}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving appointment: $e')),
      );
    }
  }

  Widget _buildViewAppointment() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade50, Colors.green.shade100, Colors.green.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade300.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_view_day, color: Colors.green.shade800, size: 32),
              const SizedBox(width: 10),
              Text(
                'My Appointments',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_isLoadingAppointments)
            const CircularProgressIndicator(color: Colors.green)
          else if (_appointments.isEmpty)
            Column(
              children: [
                Icon(Icons.calendar_today, size: 72, color: Colors.green.shade400),
                const SizedBox(height: 24),
                Text(
                  'No appointments scheduled yet.',
                  style: TextStyle(color: Colors.green.shade700, fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(
                  'Schedule your first appointment using the form below.',
                  style: TextStyle(color: Colors.green.shade600, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _appointments.length,
              itemBuilder: (context, index) {
                final appointment = _appointments[index];
                final appointmentDate = DateTime.parse(appointment['appointment_date']);
                final status = appointment['apt_status'] ?? 'pending';
                final purpose = appointment['purpose'];
                final course = appointment['course'] ?? 'N/A';

                Color statusColor;
                IconData statusIcon;
                String statusText;

                switch (status) {
                  case 'scheduled':
                    statusColor = Colors.blue;
                    statusIcon = Icons.schedule;
                    statusText = 'Scheduled';
                    break;
                  case 'completed':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Completed';
                    break;
                  case 'cancelled':
                    statusColor = Colors.red;
                    statusIcon = Icons.cancel;
                    statusText = 'Cancelled';
                    break;
                  case 'pending':
                    statusColor = Colors.orange;
                    statusIcon = Icons.schedule;
                    statusText = 'Pending Approval';
                    break;
                  case 'approved':
                    statusColor = Colors.green;
                    statusIcon = Icons.check_circle;
                    statusText = 'Approved';
                    break;
                  default:
                    statusColor = Colors.grey;
                    statusIcon = Icons.help;
                    statusText = status;
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white, Colors.grey.shade50],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(statusIcon, color: statusColor),
                      ),
                      title: Text(
                        '${appointmentDate.month}/${appointmentDate.day}/${appointmentDate.year} at ${appointmentDate.hour}:${appointmentDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(purpose, style: const TextStyle(fontSize: 14)),
                          Text('Course: $course', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: statusColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (status != 'cancelled' && status != 'approved' && status != 'completed')
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue.shade600),
                              onPressed: () => _showEditAppointmentDialog(appointment),
                              tooltip: 'Edit appointment',
                            ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red.shade600),
                            onPressed: () => _showDeleteAppointmentDialog(appointment),
                            tooltip: 'Delete appointment',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleAppointment() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100, Colors.blue.shade200],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade400, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade300.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.blue.shade800, size: 32),
              const SizedBox(width: 10),
              Text(
                'Schedule Appointment',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  initialValue: studentName,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Student Name',
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.blue.shade50,
                    prefixIcon: Icon(Icons.person, color: Colors.blue.shade600),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
                  onSaved: (value) => studentName = value ?? '',
                ),
                const SizedBox(height: 20),
                _isLoadingCourses
                    ? TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Course',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: Icon(Icons.school, color: Colors.blue.shade600),
                        ),
                        readOnly: true,
                        initialValue: 'Loading courses...',
                      )
                    : DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Course',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.school, color: Colors.blue.shade600),
                        ),
                        value: course.isNotEmpty ? course : null,
                        items: _courses.map((courseItem) {
                          final courseName = courseItem['name'] ?? courseItem['course_name'] ?? 'Unknown Course';
                          return DropdownMenuItem<String>(
                            value: courseName,
                            child: Text(
                              courseName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            course = value ?? '';
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Select your course' : null,
                        onSaved: (value) => course = value ?? '',
                      ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      //width: 500,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Time Slot',
                          labelStyle: TextStyle(color: Colors.blue.shade700),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.access_time, color: Colors.blue.shade600),
                        ),
                        value: selectedTimeSlot,
                        items: availableTimeSlots.map((slot) {
                          return DropdownMenuItem<String>(
                            value: slot,
                            child: Text(slot),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedTimeSlot = value;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty ? 'Select a time slot' : null,
                      ),
                    ),
                    SizedBox(
                      //width: 160,
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade600),
                          ),
                          child: Text(date != null ? '${date!.month}/${date!.day}/${date!.year}' : 'Select Date'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Reason for Counseling',
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: Icon(Icons.edit_note, color: Colors.blue.shade600),
                  ),
                  value: _selectedReasonType.isNotEmpty ? _selectedReasonType : null,
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'Psychological Examination',
                      child: Text('Psychological Examination'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Counseling',
                      child: Text('Counseling'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'Other',
                      child: Text('Other'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedReasonType = value ?? '';
                      if (_selectedReasonType != 'Other') {
                        _customReason = '';
                        reason = _selectedReasonType;
                      } else {
                        reason = _customReason;
                      }
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Select a reason' : null,
                ),
                if (_selectedReasonType == 'Other') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Specify Reason',
                      labelStyle: TextStyle(color: Colors.blue.shade700),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.edit, color: Colors.blue.shade600),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customReason = value;
                        reason = value;
                      });
                    },
                    validator: (value) => value == null || value.isEmpty ? 'Enter a reason' : null,
                  ),
                ],
                const SizedBox(height: 28),
                if (_errorMessage.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                    shadowColor: Colors.blue.shade300,
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_month, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Guidance Scheduling",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        elevation: 4,
        shadowColor: Colors.green.shade900.withOpacity(0.3),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/download.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
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
          ),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight - MediaQuery.of(context).padding.top,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Side by side layout for wider screens
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          flex: 1,
                          child: _buildViewAppointment(),
                        ),
                        const SizedBox(width: 24),
                        Flexible(
                          flex: 1,
                          child: _buildScheduleAppointment(),
                        ),
                      ],
                    );
                    } else {
                      // Stacked layout for narrow screens
                      return Column(
                        children: [
                          _buildViewAppointment(),
                          const SizedBox(height: 24),
                          _buildScheduleAppointment(),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
