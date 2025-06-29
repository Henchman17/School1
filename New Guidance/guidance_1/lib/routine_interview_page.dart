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
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.green[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green,
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
        title: const Text('Routine Interview Form'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Name'),
              _buildTextField('Name', nameController),
              _buildSectionTitle('Date'),
              _buildTextField('Date', dateController),
              _buildSectionTitle('Grade/Course/Year/Section'),
              _buildTextField('Grade/Course/Year/Section', gradeController),
              _buildSectionTitle('Nickname'),
              _buildTextField('Nickname', nicknameController),
              _buildSectionTitle('Ordinal Position'),
              _buildTextField('Ordinal Position', ordinalPositionController),
              _buildSectionTitle('Student Description'),
              _buildTextField('Student Description', studentDescriptionController, maxLines: 3),
              _buildSectionTitle('Familial Description'),
              _buildTextField('Familial Description', familialDescriptionController, maxLines: 3),
              _buildSectionTitle('Strengths'),
              _buildTextField('Strengths', strengthsController, maxLines: 3),
              _buildSectionTitle('Weaknesses'),
              _buildTextField('Weaknesses', weaknessesController, maxLines: 3),
              _buildSectionTitle('Achievements'),
              _buildTextField('Achievements', achievementsController, maxLines: 3),
              _buildSectionTitle('Best Work Person'),
              _buildTextField('Best Work Person', bestWorkPersonController, maxLines: 3),
              _buildSectionTitle('First Choice'),
              _buildTextField('First Choice', firstChoiceController, maxLines: 3),
              _buildSectionTitle('Goals'),
              _buildTextField('Goals', goalsController, maxLines: 3),
              _buildSectionTitle('Contribution'),
              _buildTextField('Contribution', contributionController, maxLines: 3),
              _buildSectionTitle('Talents/Skills'),
              _buildTextField('Talents/Skills', talentsController, maxLines: 3),
              _buildSectionTitle('Home Problems'),
              _buildTextField('Home Problems', homeProblemsController, maxLines: 3),
              _buildSectionTitle('School Problems'),
              _buildTextField('School Problems', schoolProblemsController, maxLines: 3),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _showConsentDialog,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'CONSENT',
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('Applicant Signature'),
              _buildTextField('Applicant Signature', applicantSignatureController),
              _buildSectionTitle('Signature Date'),
              _buildTextField('Signature Date', signatureDateController),
              const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }