import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart';

class ExitInterviewPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ExitInterviewPage({super.key, this.userData});

  @override
  State<ExitInterviewPage> createState() => _ExitInterviewPageState();
}

class _ExitInterviewPageState extends State<ExitInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime _interviewDate = DateTime.now();

  // Student Information
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _gradeYearController = TextEditingController();
  final TextEditingController _programController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _fatherNameController = TextEditingController();
  final TextEditingController _motherNameController = TextEditingController();

  // Reasons for Leaving (Checkboxes)
  bool _problemFamily = false;
  bool _problemClassmate = false;
  bool _problemAcademic = false;
  bool _seekingFinancial = false;
  bool _problemTeacher = false;
  final TextEditingController _otherReasonsController = TextEditingController();

  // Transfer Plans
  final TextEditingController _transferSchoolController = TextEditingController();
  final TextEditingController _transferProgramController = TextEditingController();

  // Difficulties and Suggestions
  final TextEditingController _difficultiesController = TextEditingController();
  final TextEditingController _suggestionsController = TextEditingController();

  // Consent
  bool _consentGiven = false;

  bool _isSubmitting = false;



  Future<void> _submitExitInterview() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate consent
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the consent form to proceed')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final userId = widget.userData?['id'] ?? 0;
      final studentName = '${widget.userData?['first_name'] ?? ''} ${widget.userData?['last_name'] ?? ''}'.trim();
      final studentNumber = widget.userData?['student_id'] ?? '';

      final apiUrl = await AppConfig.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/api/student/exit-interview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'student_id': userId,
          'student_name': _nameController.text.trim(),
          'student_number': studentNumber,
          'interview_date': _interviewDate.toIso8601String().split('T')[0],
          'grade_year_level': _gradeYearController.text.trim(),
          'present_program': _programController.text.trim(),
          'address': _addressController.text.trim(),
          'father_name': _fatherNameController.text.trim(),
          'mother_name': _motherNameController.text.trim(),

          // Reasons for leaving
          'reason_family': _problemFamily,
          'reason_classmate': _problemClassmate,
          'reason_academic': _problemAcademic,
          'reason_financial': _seekingFinancial,
          'reason_teacher': _problemTeacher,
          'reason_other': _otherReasonsController.text.trim(),

          // Transfer plans
          'transfer_school': _transferSchoolController.text.trim(),
          'transfer_program': _transferProgramController.text.trim(),

          // Difficulties and suggestions
          'difficulties': _difficultiesController.text.trim(),
          'suggestions': _suggestionsController.text.trim(),

          // Consent
          'consent_given': _consentGiven,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exit interview submitted successfully!')),
        );
        Navigator.of(context).pop();
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to submit exit interview';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EXIT INTERVIEW FOR TRANSFER & SHIFTER'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        foregroundColor: Colors.white,
      ),
      body: Stack(
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXIT INTERVIEW FOR TRANSFER & SHIFTER',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _interviewDate.toIso8601String().split('T')[0],
                            decoration: const InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            readOnly: true,
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _interviewDate,
                                firstDate: DateTime.now().subtract(const Duration(days: 30)),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (date != null) {
                                setState(() {
                                  _interviewDate = date;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _gradeYearController,
                            decoration: const InputDecoration(
                              labelText: 'Grade/Year Level',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _programController,
                            decoration: const InputDecoration(
                              labelText: 'Present Program',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: 'Address',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fatherNameController,
                            decoration: const InputDecoration(
                              labelText: 'Father\'s Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _motherNameController,
                            decoration: const InputDecoration(
                              labelText: 'Mother\'s Name',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Kindly Check:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Reason/s for Leaving the University/Program',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          CheckboxListTile(
                            title: const Text('Problem in the Family'),
                            value: _problemFamily,
                            onChanged: (val) => setState(() => _problemFamily = val!),
                          ),
                          CheckboxListTile(
                            title: const Text('Problem with Classmate/Schoolmate'),
                            value: _problemClassmate,
                            onChanged: (val) => setState(() => _problemClassmate = val!),
                          ),
                          CheckboxListTile(
                            title: const Text('Problem in the Academic Performance'),
                            value: _problemAcademic,
                            onChanged: (val) => setState(() => _problemAcademic = val!),
                          ),
                          CheckboxListTile(
                            title: const Text('Seeking Financial Support'),
                            value: _seekingFinancial,
                            onChanged: (val) => setState(() => _seekingFinancial = val!),
                          ),
                          CheckboxListTile(
                            title: const Text('Problem with Student – Teacher Relationship'),
                            value: _problemTeacher,
                            onChanged: (val) => setState(() => _problemTeacher = val!),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Others: (Kindly state your reason/s)',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: _otherReasonsController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'The School/Program you are planning to transfer/enroll?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: _transferSchoolController,
                            decoration: const InputDecoration(
                              labelText: 'School/Program',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          TextFormField(
                            controller: _transferProgramController,
                            decoration: const InputDecoration(
                              labelText: 'Program',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Difficulties/Problem/s encountered during your stay in the University/Program?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: _difficultiesController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Any suggestion/s that you can give which will help us improve our services in the University/Program?',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          TextFormField(
                            controller: _suggestionsController,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 4,
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Signature over printed name of Interviewee',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Signature over printed name of Interviewer',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          Container(
                            height: 50,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'C O N S E N T',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'I am fully aware that the Pamantasan ng Lungsod ng San Pablo (PLSP) or its designated representative is duty bound and obligated under the Data Privacy Act of 2012 and its Implementing Rules and Regulations (IRR) effective since September 8, 2016, to protect all my personal and sensitive information that it collects, processes, and retains upon this Routine Interview Form.\n\nLikewise, I am fully aware that PLSP may share such information to affiliated or partner organizations as part of its contractual obligations, or with government agencies pursuant to law or legal processes. In this regard, I hereby allow PLSP to collect, process, use and share my personal data in the pursuit of its legitimate academic, research, and employment purposes and/or interests as an educational institution.\n\nI hereby certify that all information supplied in this Routine Interview Form is complete and accurate. I also understand that any false information will disqualify me from the issuance of the said form.',
                            style: TextStyle(fontSize: 12),
                          ),
                          CheckboxListTile(
                            title: const Text('I agree'),
                            value: _consentGiven,
                            onChanged: (val) => setState(() => _consentGiven = val!),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitExitInterview,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 30, 182, 88),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isSubmitting
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text('Submit Exit Interview', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
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
