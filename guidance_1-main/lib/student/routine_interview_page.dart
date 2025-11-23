import 'package:flutter/material.dart';

class RoutineInterviewPage extends StatefulWidget {
  const RoutineInterviewPage({super.key});

  @override
  RoutineInterviewPageState createState() => RoutineInterviewPageState();
}

class RoutineInterviewPageState extends State<RoutineInterviewPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSex;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController gradeController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController ordinalPositionController = TextEditingController();
  final TextEditingController studentDescriptionController = TextEditingController();
  final TextEditingController familialDescriptionController = TextEditingController();
  final TextEditingController strengthsController = TextEditingController();
  final TextEditingController weaknessesController = TextEditingController();
  final TextEditingController achievementsController = TextEditingController();
  final TextEditingController bestWorkPersonController = TextEditingController();
  final TextEditingController firstChoiceController = TextEditingController();
  final TextEditingController goalsController = TextEditingController();
  final TextEditingController contributionController = TextEditingController();
  final TextEditingController talentsController = TextEditingController();
  final TextEditingController homeProblemsController = TextEditingController();
  final TextEditingController schoolProblemsController = TextEditingController();
  final TextEditingController applicantSignatureController = TextEditingController();
  final TextEditingController signatureDateController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    dateController.dispose();
    gradeController.dispose();
    nicknameController.dispose();
    ordinalPositionController.dispose();
    studentDescriptionController.dispose();
    familialDescriptionController.dispose();
    strengthsController.dispose();
    weaknessesController.dispose();
    achievementsController.dispose();
    bestWorkPersonController.dispose();
    firstChoiceController.dispose();
    goalsController.dispose();
    contributionController.dispose();
    talentsController.dispose();
    homeProblemsController.dispose();
    schoolProblemsController.dispose();
    applicantSignatureController.dispose();
    signatureDateController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Process the form data here or send to backend
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Routine Interview Form Submitted')),
      );
      Navigator.of(context).pop();
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.green.shade600, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Colors.green.shade700),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade300, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionDivider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      height: 2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, Colors.green.shade300, Colors.transparent],
        ),
      ),
    );
  }


  void _showConsentDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('CONSENT'),
          content: SingleChildScrollView(
            child: Text(
              'I am fully aware that the Pamantasan ng Lungsod ng San Pablo (PLSP) or its designated representative is duty bound and obligated under the Data Privacy Act of 2012 and its Implementing Rules and Regulations (IRR) effective since September 8, 2016, to protect all my personal and sensitive information that it collects, processes, and retains upon this Routine Interview Form.\n\n'
              'Likewise, I am fully aware that PLSP may share such information to affiliated or partner organizations as part of its contractual obligations, or with government agencies pursuant to law or legal processes. In this regard, I hereby allow PLSP to collect, process, use and share my personal data in the pursuit of its legitimate academic, research, and employment purposes and/or interests as an educational institution.\n\n'
              'I hereby certify that all information supplied in this Routine Interview Form is complete and accurate. I also understand that any false information will disqualify me from the issuance of the said form.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text(
          "Routine Interview",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: Stack(
        children: [
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
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Personal Information'),
                        _buildTextField('Name', nameController),
                        _buildTextField('Date', dateController),
                        _buildTextField('Grade/Course/Year/Section', gradeController),
                        _buildTextField('Nickname', nicknameController),
                        _buildTextField('Ordinal Position', ordinalPositionController),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Background Information'),
                        _buildTextField('Student Description', studentDescriptionController, maxLines: 3),
                        _buildTextField('Familial Description', familialDescriptionController, maxLines: 3),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Strengths & Weaknesses'),
                        _buildTextField('Strengths', strengthsController, maxLines: 3),
                        _buildTextField('Weaknesses', weaknessesController, maxLines: 3),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Achievements & Aspirations'),
                        _buildTextField('Achievements', achievementsController, maxLines: 3),
                        _buildTextField('Best Work Person', bestWorkPersonController, maxLines: 3),
                        _buildTextField('First Choice', firstChoiceController, maxLines: 3),
                        _buildTextField('Goals', goalsController, maxLines: 3),
                        _buildTextField('Contribution', contributionController, maxLines: 3),
                        _buildTextField('Talents/Skills', talentsController, maxLines: 3),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade50, Colors.red.shade100, Colors.red.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.shade400, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade300.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Challenges'),
                        _buildTextField('Home Problems', homeProblemsController, maxLines: 3),
                        _buildTextField('School Problems', schoolProblemsController, maxLines: 3),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade50, Colors.teal.shade100, Colors.teal.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.teal.shade400, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.shade300.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Consent & Signature'),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _showConsentDialog,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade300),
                            ),
                            child: const Text(
                              '📋 View CONSENT Agreement',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildTextField('Applicant Signature', applicantSignatureController),
                        _buildTextField('Signature Date', signatureDateController),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 6,
                            shadowColor: Colors.green.shade300,
                          ),
                          child: const Text(
                            'Submit Form',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
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
