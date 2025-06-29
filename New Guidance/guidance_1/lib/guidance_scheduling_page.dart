import 'package:flutter/material.dart';
import 'navigation_rail_example.dart';
import 'answerable_forms.dart';

class GuidanceSchedulingPage extends StatefulWidget {
  final SchedulingStatus status;

  const GuidanceSchedulingPage({
    super.key,
    required this.status,
  });

  @override
  State<GuidanceSchedulingPage> createState() => _GuidanceSchedulingPageState();
}

class _GuidanceSchedulingPageState extends State<GuidanceSchedulingPage> {
  final _formKey = GlobalKey<FormState>();
  String studentName = '';
  String reason = '';
  String course = '';
  TimeOfDay? time;
  DateTime? date;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      // Handle form submission logic here
      // For example, update status or send data to backend
      setState(() {
        // Example: change status to processing after submission
        // You can customize this as needed
      });
      Navigator.of(context).pop();
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
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != date) {
      setState(() {
        date = picked;
      });
    }
  }

  Widget _buildViewAppointment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'View Appointment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (widget.status == SchedulingStatus.none)
            const Text('No current appointment.'),
          if (widget.status == SchedulingStatus.processing)
            Column(
              children: const [
                Text('Request: Processing'),
                SizedBox(height: 10),
                CircularProgressIndicator(),
              ],
            ),
          if (widget.status == SchedulingStatus.approved)
            Column(
              children: const [
                Text('Request: Approved'),
                SizedBox(height: 10),
                Icon(Icons.check_circle, color: Colors.green, size: 48),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildScheduleAppointment() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Schedule Appointment',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Student Name'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your name' : null,
                  onSaved: (value) => studentName = value ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Course'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter your course' : null,
                  onSaved: (value) => course = value ?? '',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(time != null ? time!.format(context) : 'Select Time'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(date != null ? '${date!.month}/${date!.day}/${date!.year}' : 'Select Date'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Reason for Counseling'),
                  validator: (value) => value == null || value.isEmpty ? 'Enter a reason' : null,
                  onSaved: (value) => reason = value ?? '',
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Submit'),
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
        title: const Text('Schedule Appointment'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Side by side layout for wider screens
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 400,
                          child: _buildViewAppointment(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SizedBox(
                          height: 400,
                          child: _buildScheduleAppointment(),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Stacked layout for narrow screens
                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 400,
                          child: _buildViewAppointment(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 400,
                          child: _buildScheduleAppointment(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
