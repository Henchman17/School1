import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'routine_interview_page.dart';
import 'scrf_page.dart';import 'exit_interview_page.dart';
import 'exit_survey_graduating_page.dart';
import '../config.dart';
import '../providers/form_settings_provider.dart';

class AnswerableForms extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const AnswerableForms({super.key, this.userData});

  @override
  State<AnswerableForms> createState() => _AnswerableFormsState();
}

class _AnswerableFormsState extends State<AnswerableForms> {
  List<Map<String, dynamic>> _studentForms = [];
  bool _isLoadingForms = false;

  @override
  void initState() {
    super.initState();
    _fetchStudentForms();
  }

  Future<void> _fetchStudentForms() async {
    setState(() {
      _isLoadingForms = true;
    });

    try {
      final studentId = widget.userData?['id'] ?? 0;
      final apiUrl = await AppConfig.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/api/student/forms?student_id=$studentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _studentForms = List<Map<String, dynamic>>.from(data['forms'] ?? []);
          _isLoadingForms = false;
        });
      } else {
        setState(() {
          _studentForms = [];
          _isLoadingForms = false;
        });
      }
    } catch (e) {
      setState(() {
        _studentForms = [];
        _isLoadingForms = false;
      });
    }
  }

  bool _hasForm(String formType) {
    return _studentForms.any((form) => form['form_type'] == formType);
  }

  bool _hasCompletedForm(String formType) {
    return _studentForms.any((form) =>
      form['form_type'] == formType &&
      form['status'] == 'completed'
    );
  }

  @override
  Widget build(BuildContext context) {
    final formSettingsProvider = Provider.of<FormSettingsProvider>(context);
    final formSettings = formSettingsProvider.formSettings;
    final textStyle = Theme.of(context).textTheme.titleLarge;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment, color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text(
              "Answerable Forms",
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
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                Column(
                  children: [
                    // SCRF Form
                    Container(
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
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ScrfPage(userData: widget.userData)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Icon(Icons.assignment, size: 56, color: Colors.blue.shade800),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Text(
                                  'Student Cumulative Form',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.blue.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (formSettings['routine_interview_enabled'] == true) const SizedBox(height: 24),
                    // Routine Interview Form
                    if (formSettings['routine_interview_enabled'] == true)
                      Container(
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
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RoutineInterviewPage()),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Row(
                              children: [
                                Icon(Icons.forum, size: 56, color: Colors.green.shade800),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Text(
                                    'Routine Interview',
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                                  ),
                                ),
                                Icon(Icons.arrow_forward_ios, color: Colors.green.shade600),
                              ],
                            ),
                          ),
                        ),
                      ),
                    if (formSettings['routine_interview_enabled'] == true) const SizedBox(height: 24),
                    // Exit interview for transferring students
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade50, Colors.purple.shade100, Colors.purple.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.purple.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.shade300.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExitInterviewPage(userData: widget.userData)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Icon(Icons.transfer_within_a_station, size: 56, color: Colors.purple.shade800),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Text(
                                  'Exit Interview for Transferring Students',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.purple.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Exit survey for graduating students
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade50, Colors.orange.shade100, Colors.orange.shade200],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade400, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade300.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ExitSurveyGraduatingPage(
                              studentId: widget.userData?['id'] ?? 0,
                              studentName: widget.userData?['name'] ?? '',
                              studentNumber: widget.userData?['student_number'] ?? '',
                            )),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Row(
                            children: [
                              Icon(Icons.assignment_turned_in, size: 56, color: Colors.orange.shade800),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Text(
                                  'Exit Survey for Graduating Students',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.orange.shade600),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
