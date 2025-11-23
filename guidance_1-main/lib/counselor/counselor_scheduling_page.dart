import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class CounselorSchedulingPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Map<String, dynamic>? selectedStudent;

  const CounselorSchedulingPage({
    super.key,
    this.userData,
    this.selectedStudent,
  });

  @override
  State<CounselorSchedulingPage> createState() => _CounselorSchedulingPageState();
}

class _CounselorSchedulingPageState extends State<CounselorSchedulingPage> {
  final _formKey = GlobalKey<FormState>();
  String studentName = '';
  String reason = '';
  String course = '';
  TimeOfDay? time;
  DateTime? date;
  bool _isSubmitting = false;
  String _errorMessage = '';
  List<Map<String, dynamic>> _courses = [];
  bool _isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    // Pre-populate student name from selected student
    if (widget.selectedStudent != null) {
      studentName = '${widget.selectedStudent!['first_name']} ${widget.selectedStudent!['last_name']}';
    }
    _fetchCourses();
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

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _isSubmitting = true;
        _errorMessage = '';
      });

      try {
        final appointmentDate = DateTime(date!.year, date!.month, date!.day, time!.hour, time!.minute);

        final requestBody = {
          'user_id': widget.selectedStudent?['user_id'] ?? widget.selectedStudent?['id'],
          'counselor_id': widget.userData?['id'],
          'appointment_date': appointmentDate.toIso8601String(),
          'purpose': reason,
          'course': course,
          'apt_status': 'pending',
          'approval_status': 'approved', // Counselor-scheduled appointments are auto-approved
        };

        final baseUrl = await AppConfig.apiBaseUrl;
        final response = await http.post(
          Uri.parse('$baseUrl/api/appointments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment scheduled successfully!')),
          );
          Navigator.of(context).pop(); // Go back to students page
        } else {
          final error = jsonDecode(response.body);
          setState(() {
            _errorMessage = error['error'] ?? 'Failed to schedule appointment';
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && picked != time) {
      setState(() {
        time = picked;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Appointment'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Schedule Counseling Session',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 30, 182, 88),
                ),
              ),
              const SizedBox(height: 24),

              // Student Name (read-only)
              TextFormField(
                initialValue: studentName,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Student Name',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 16),

              // Course Selection
              _isLoadingCourses
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Course/Subject',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      value: course.isNotEmpty ? course : null,
                      items: _courses.map((courseItem) {
                        final courseName = courseItem['name'] ?? courseItem['course_name'] ?? 'Unknown Course';
                        return DropdownMenuItem<String>(
                          value: courseName,
                          child: Text(courseName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          course = value ?? '';
                        });
                      },
                      validator: (value) => value == null || value.isEmpty ? 'Please select a course' : null,
                      onSaved: (value) => course = value ?? '',
                    ),
              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(date != null ? '${date!.month}/${date!.day}/${date!.year}' : 'Select Date'),
                ),
              ),
              const SizedBox(height: 16),

              // Time Selection
              InkWell(
                onTap: () => _selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(time != null ? time!.format(context) : 'Select Time'),
                ),
              ),
              const SizedBox(height: 16),

              // Reason for Counseling
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Purpose/Reason for Counseling',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit_note),
                ),
                maxLines: 3,
                validator: (value) => value == null || value.isEmpty ? 'Please enter the purpose' : null,
                onSaved: (value) => reason = value ?? '',
              ),
              const SizedBox(height: 24),

              if (_errorMessage.isNotEmpty) ...[
                Text(
                  _errorMessage,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 30, 182, 88),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Schedule Appointment',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
