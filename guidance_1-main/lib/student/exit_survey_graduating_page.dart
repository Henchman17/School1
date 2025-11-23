import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart' as config;

class ExitSurveyGraduatingPage extends StatefulWidget {
  final int studentId;
  final String studentName;
  final String studentNumber;

  const ExitSurveyGraduatingPage({
    Key? key,
    required this.studentId,
    required this.studentName,
    required this.studentNumber,
  }) : super(key: key);

  @override
  _ExitSurveyGraduatingPageState createState() => _ExitSurveyGraduatingPageState();
}

class _ExitSurveyGraduatingPageState extends State<ExitSurveyGraduatingPage> {
  final _formKey = GlobalKey<FormState>();
  bool _consentGiven = false;

  // Student Information
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  String? _selectedProgram;
  final List<String> _selectedColleges = [];

  // Career Plans
  final List<String> _careerPlans = [];
  final TextEditingController _careerAspirationsController = TextEditingController();
  final TextEditingController _achievingPlansController = TextEditingController();
  final TextEditingController _communityContributionController = TextEditingController();
  int _preparednessRating = 3;
  String? _needCounseling;

  // Academic Services Ratings (1-5)
  int _lessonsRating = 3;
  int _teachersRating = 3;
  int _knowledgeRating = 3;
  int _skillsRating = 3;
  int _valuesRating = 3;
  int _practicalExperiencesRating = 3;

  // Satisfaction Ratings (1-5)
  int _guidanceRating = 3;
  int _facultyRating = 3;
  int _deansRating = 3;
  int _emisoRating = 3;
  int _libraryRating = 3;
  int _laboratoriesRating = 3;
  int _externalLinkagesRating = 3;
  int _financeRating = 3;
  int _registrarRating = 3;
  int _cafeteriaRating = 3;
  int _healthClinicRating = 3;
  int _admissionRating = 3;
  int _researchRating = 3;

  // Recommendations
  final TextEditingController _suggestionsController = TextEditingController();

  // Alumni
  String? _alumniSurvey;

  final List<String> _collegeOptions = [
    'CTHM', 'CCST', 'COA', 'COE', 'CTE', 'CHK', 'CBA', 'CAS', 'CNAHS', 'GRADUATE STUDIES'
  ];

  final List<String> _careerPlanOptions = [
    'Take masteral studies', 'Take short remedial courses', 'Work', 'Start own business',
    'Take board examination', 'Take a short break/vacation', 'Others'
  ];

  Widget _buildRatingScale(String label, int value, Function(int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Radio<int>(
                value: index + 1,
                groupValue: value,
                onChanged: (val) => onChanged(val),
              ),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Very Poor', '', '', '', 'Excellent'].map((text) => Text(text, style: TextStyle(fontSize: 12))).toList(),
        ),
      ],
    );
  }

  Widget _buildSatisfactionScale(String label, int value, Function(int?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          children: List.generate(5, (index) {
            return Expanded(
              child: Radio<int>(
                value: index + 1,
                groupValue: value,
                onChanged: (val) => onChanged(val),
              ),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['Not Satisfied', '', '', '', 'Very Satisfied'].map((text) => Text(text, style: TextStyle(fontSize: 12))).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exit Survey for Graduating Students'),
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
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Informed Consent
                    Text('Informed Consent', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('I am fully aware that Pamantasan ng Lungsod ng San Pablo or its designated representative is duty bound and obligated under the Data Privacy Act of 2012 and its Implementing Rules and Regulations (IRR) effective since September 8, 2016, to protect all my personal and sensitive information that it collects, processes, and retains upon my application for Counseling Services Form.\n\nLikewise, I am fully aware that PLSP-Guidance and Counseling Office may share such information to affiliated or partner organizations as part of its contractual obligations, or with government agencies pursuant to law or legal processes. In this regard, I hereby allow PLSP-Guidance and Counseling Office to collect, process, use and share my personal data in the pursuit of its legitimate academic, research, and employment purposes and/or interests as an educational institution.\n\nI hereby certify that all information supplied in this Counseling Services Form is complete and accurate. *'),
                    CheckboxListTile(
                      title: Text('I agree'),
                      value: _consentGiven,
                      onChanged: (val) => setState(() => _consentGiven = val!),
                    ),

                    // Student Information
                    Text('Student Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: 'Email*'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: 'Last Name*'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(labelText: 'First Name*'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _middleNameController,
                      decoration: InputDecoration(labelText: 'Middle Name*'),
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedProgram,
                      items: ['Bachelor', 'Master', 'Doctorate'].map((prog) => DropdownMenuItem(value: prog, child: Text(prog))).toList(),
                      onChanged: (val) => setState(() => _selectedProgram = val),
                      decoration: InputDecoration(labelText: 'Program*'),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    Text('College* (Check all that apply)'),
                    ..._collegeOptions.map((college) => CheckboxListTile(
                      title: Text(college),
                      value: _selectedColleges.contains(college),
                      onChanged: (val) {
                        setState(() {
                          if (val!) _selectedColleges.add(college);
                          else _selectedColleges.remove(college);
                        });
                      },
                    )),

                    // Career Plans and Readiness
                    Text('Career Plans and Readiness', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('What are your plans after graduation? Check all that apply. *'),
                    ..._careerPlanOptions.map((plan) => CheckboxListTile(
                      title: Text(plan),
                      value: _careerPlans.contains(plan),
                      onChanged: (val) {
                        setState(() {
                          if (val!) _careerPlans.add(plan);
                          else _careerPlans.remove(plan);
                        });
                      },
                    )),
                    TextFormField(
                      controller: _careerAspirationsController,
                      decoration: InputDecoration(labelText: 'What are your career aspirations or long-term employment goals? *'),
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _achievingPlansController,
                      decoration: InputDecoration(labelText: 'How do you plan on achieving them? *'),
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _communityContributionController,
                      decoration: InputDecoration(labelText: 'In what way will your career aspirations contribute to the community? *'),
                      maxLines: 3,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),
                    _buildRatingScale('How do you rate your overall preparedness to work? *', _preparednessRating, (val) => setState(() => _preparednessRating = val!)),
                    Text('Do you feel the need to go to the counseling office to have an in-depth interview about your career plans and readiness? *'),
                    RadioListTile<String>(
                      title: Text('Yes'),
                      value: 'Yes',
                      groupValue: _needCounseling,
                      onChanged: (val) => setState(() => _needCounseling = val),
                    ),
                    RadioListTile<String>(
                      title: Text('No'),
                      value: 'No',
                      groupValue: _needCounseling,
                      onChanged: (val) => setState(() => _needCounseling = val),
                    ),

                    // Academic Services
                    Text('Academic Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildRatingScale('How would you rate the lessons that the teachers taught you? *', _lessonsRating, (val) => setState(() => _lessonsRating = val!)),
                    _buildRatingScale('How would you rate the teachers in how well they taught the lessons? *', _teachersRating, (val) => setState(() => _teachersRating = val!)),
                    _buildRatingScale('How would you rate the knowledge you earned from the program? *', _knowledgeRating, (val) => setState(() => _knowledgeRating = val!)),
                    _buildRatingScale('How would you rate the skills you earned from the program? *', _skillsRating, (val) => setState(() => _skillsRating = val!)),
                    _buildRatingScale('How would you rate the values you earned from the program? *', _valuesRating, (val) => setState(() => _valuesRating = val!)),
                    _buildRatingScale('How sufficient were the practical experiences provided during your classes? (Hands-on activities and internship) *', _practicalExperiencesRating, (val) => setState(() => _practicalExperiencesRating = val!)),

                    // Satisfaction to Academic Support Services
                    Text('Satisfaction to Academic Support Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildSatisfactionScale('Guidance and Counseling Office *', _guidanceRating, (val) => setState(() => _guidanceRating = val!)),
                    _buildSatisfactionScale('Faculty Members (Teachers are knowledgeable, have good teaching methods, are approachable) *', _facultyRating, (val) => setState(() => _facultyRating = val!)),
                    _buildSatisfactionScale('Dean\'s Office *', _deansRating, (val) => setState(() => _deansRating = val!)),
                    _buildSatisfactionScale('EMISO (Educational Management Information System Office) *', _emisoRating, (val) => setState(() => _emisoRating = val!)),
                    _buildSatisfactionScale('Library *', _libraryRating, (val) => setState(() => _libraryRating = val!)),
                    _buildSatisfactionScale('Laboratories *', _laboratoriesRating, (val) => setState(() => _laboratoriesRating = val!)),

                    // PLSP Offices
                    Text('PLSP Offices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    _buildSatisfactionScale('Office of External Linkages (Able to assist during internship) *', _externalLinkagesRating, (val) => setState(() => _externalLinkagesRating = val!)),
                    _buildSatisfactionScale('Finance (Staff are approachable and provide excellent service) *', _financeRating, (val) => setState(() => _financeRating = val!)),
                    _buildSatisfactionScale('Registrar (Staff are approachable and provide for student needs) *', _registrarRating, (val) => setState(() => _registrarRating = val!)),
                    _buildSatisfactionScale('Cafeteria/Canteen (Has complete and sufficient food and supplies needed) *', _cafeteriaRating, (val) => setState(() => _cafeteriaRating = val!)),
                    _buildSatisfactionScale('Health Clinic (Able to attend health needs and provides effective service) *', _healthClinicRating, (val) => setState(() => _healthClinicRating = val!)),
                    _buildSatisfactionScale('Admission Office (Able to assist during enrollment) *', _admissionRating, (val) => setState(() => _admissionRating = val!)),
                    _buildSatisfactionScale('Research & Development Office (Staff approachable and answers research inquiries) *', _researchRating, (val) => setState(() => _researchRating = val!)),

                    // Recommendations
                    Text('Recommendations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: _suggestionsController,
                      decoration: InputDecoration(labelText: 'What suggestions do you have for improving the academic services of future students? *'),
                      maxLines: 5,
                      validator: (val) => val!.isEmpty ? 'Required' : null,
                    ),

                    // Alumni
                    Text('Alumni', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('As part of the PLSP alumni, would you be open to us reaching out with a survey to catch up on your journey after graduation? *'),
                    RadioListTile<String>(
                      title: Text('Yes'),
                      value: 'Yes',
                      groupValue: _alumniSurvey,
                      onChanged: (val) => setState(() => _alumniSurvey = val),
                    ),
                    RadioListTile<String>(
                      title: Text('No'),
                      value: 'No',
                      groupValue: _alumniSurvey,
                      onChanged: (val) => setState(() => _alumniSurvey = val),
                    ),

                    ElevatedButton(
                      onPressed: _submitForm,
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate() || !_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields and give consent')));
      return;
    }

    // Prepare data for submission
    // Note: This form has more fields than the current backend endpoint supports.
    // You may need to create a new endpoint or adjust the backend to handle this detailed survey.
    final data = {
      'student_id': widget.studentId,
      'student_name': '${_firstNameController.text} ${_middleNameController.text} ${_lastNameController.text}',
      'student_number': widget.studentNumber,
      'interview_type': 'graduating',
      'interview_date': DateTime.now().toIso8601String().split('T')[0],
      'reason_for_leaving': 'Graduation',
      'satisfaction_rating': _preparednessRating, // Using preparedness as overall satisfaction
      'academic_experience': 'Lessons: $_lessonsRating, Teachers: $_teachersRating, Knowledge: $_knowledgeRating, Skills: $_skillsRating, Values: $_valuesRating, Practical: $_practicalExperiencesRating',
      'support_services_experience': 'Guidance: $_guidanceRating, Faculty: $_facultyRating, Dean: $_deansRating, EMISO: $_emisoRating, Library: $_libraryRating, Labs: $_laboratoriesRating',
      'facilities_experience': 'External Linkages: $_externalLinkagesRating, Finance: $_financeRating, Registrar: $_registrarRating, Cafeteria: $_cafeteriaRating, Health: $_healthClinicRating, Admission: $_admissionRating, Research: $_researchRating',
      'overall_improvements': _suggestionsController.text,
      'future_plans': _careerPlans.join(', '),
      'contact_info': _emailController.text,
    };

    try {
      final baseUrl = await config.AppConfig.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$baseUrl/students/exit-interview'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Survey submitted successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit survey')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
