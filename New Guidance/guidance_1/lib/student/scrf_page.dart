import 'package:flutter/material.dart';
import 'dart:convert';
import '../config.dart';

class ScrfPage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  const ScrfPage({super.key, this.userData});

  @override
  _ScrfPageState createState() => _ScrfPageState();
}

class _ScrfPageState extends State<ScrfPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSex;
  final List<TextEditingController> _siblingControllers = [];
  final List<String> _siblingLabels = [];
  Map<String, dynamic>? _existingData;
  bool _isLoading = true;
  bool _livingWithParents = true;
  bool _hasPhysicalDefect = false;

  // Controllers for all fields
  final _programEnrolledController = TextEditingController();

  List<Map<String, dynamic>> _programs = [];
  String? _selectedProgram;

  Future<void> _fetchPrograms() async {
    try {
      final response = await AppConfig.supabase.from('courses').select();
      setState(() {
        _programs = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Handle error or ignore
    }
  }

  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _civilStatusController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  final _lrnController = TextEditingController();
  final _cellphoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _fatherAgeController = TextEditingController();
  final _fatherOccupationController = TextEditingController();
  final _motherNameController = TextEditingController();
  final _motherAgeController = TextEditingController();
  final _motherOccupationController = TextEditingController();
  final _livingWithParentsController = TextEditingController();
  final _guardianNameController = TextEditingController();
  final _guardianRelationshipController = TextEditingController();
  final _awardsReceivedController = TextEditingController();
  final _transfereeCollegeController = TextEditingController();
  final _transfereeProgramController = TextEditingController();
  final _physicalDefectController = TextEditingController();
  final _natureOfDefectController = TextEditingController();
  final _allergiesFoodController = TextEditingController();
  final _allergiesMedicineController = TextEditingController();
  final _examTakenController = TextEditingController();
  final _examDateController = TextEditingController();
  final _rawScoreController = TextEditingController();
  final _percentileController = TextEditingController();
  final _adjectivalRatingController = TextEditingController();

  // Educational background controllers
  final _grade7SchoolController = TextEditingController();
  final _grade7YearController = TextEditingController();
  final _grade8SchoolController = TextEditingController();
  final _grade8YearController = TextEditingController();
  final _grade9SchoolController = TextEditingController();
  final _grade9YearController = TextEditingController();
  final _grade10SchoolController = TextEditingController();
  final _grade10YearController = TextEditingController();
  final _grade11SchoolController = TextEditingController();
  final _grade11YearController = TextEditingController();
  final _grade12SchoolController = TextEditingController();
  final _grade12YearController = TextEditingController();

  bool _hasAdmissionOfficerAccess() {
    final role = widget.userData?['role']?.toString().toLowerCase();
    return role == 'admin' || role == 'counselor' || role == 'admission officer';
  }

  @override
  void initState() {
    super.initState();
    _fetchPrograms();
    _fetchExistingData();
  }

  Future<void> _fetchExistingData() async {
    final userId = widget.userData?['id'];
    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    try {
      final response = await AppConfig.supabase
          .from('student_cumulative_records')
          .select()
          .eq('user_id', userId)
          .single();
      setState(() {
        _existingData = response;
        _populateFieldsWithExistingData();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFieldsWithExistingData() {
    if (_existingData == null) return;

    _programEnrolledController.text = _existingData!['program_enrolled'] ?? '';
    _selectedSex = _existingData!['sex'];
    _fullNameController.text = _existingData!['full_name'] ?? '';

    // Set selected program from existing data if available
    if (_existingData!['program_enrolled'] != null) {
      _selectedProgram = _existingData!['program_enrolled'];
    }
    _addressController.text = _existingData!['address'] ?? '';
    _ageController.text = _existingData!['age']?.toString() ?? '';
    _civilStatusController.text = _existingData!['civil_status'] ?? '';
    _dateOfBirthController.text = _existingData!['date_of_birth'] ?? '';
    _placeOfBirthController.text = _existingData!['place_of_birth'] ?? '';
    _lrnController.text = _existingData!['lrn'] ?? '';
    _cellphoneController.text = _existingData!['cellphone'] ?? '';
    _emailController.text = _existingData!['email_address'] ?? '';
    _fatherNameController.text = _existingData!['father_name'] ?? '';
    _fatherAgeController.text = _existingData!['father_age']?.toString() ?? '';
    _fatherOccupationController.text = _existingData!['father_occupation'] ?? '';
    _motherNameController.text = _existingData!['mother_name'] ?? '';
    _motherAgeController.text = _existingData!['mother_age']?.toString() ?? '';
    _motherOccupationController.text = _existingData!['mother_occupation'] ?? '';
    _livingWithParents = _existingData!['living_with_parents'] ?? true;
    _guardianNameController.text = _existingData!['guardian_name'] ?? '';
    _guardianRelationshipController.text = _existingData!['guardian_relationship'] ?? '';
    _awardsReceivedController.text = _existingData!['awards_received'] ?? '';
    _transfereeCollegeController.text = _existingData!['transferee_college_name'] ?? '';
    _transfereeProgramController.text = _existingData!['transferee_program'] ?? '';
    _hasPhysicalDefect = _existingData!['physical_defect']?.toLowerCase() == 'yes';
    _natureOfDefectController.text = _existingData!['physical_defect'] ?? '';
    _allergiesFoodController.text = _existingData!['allergies_food'] ?? '';
    _allergiesMedicineController.text = _existingData!['allergies_medicine'] ?? '';
    _examTakenController.text = _existingData!['exam_taken'] ?? '';
    _examDateController.text = _existingData!['exam_date'] ?? '';
    _rawScoreController.text = _existingData!['raw_score']?.toString() ?? '';
    _percentileController.text = _existingData!['percentile']?.toString() ?? '';
    _adjectivalRatingController.text = _existingData!['adjectival_rating'] ?? '';

    // Populate siblings
    _siblingControllers.clear();
    _siblingLabels.clear();
    if (_existingData!['siblings'] != null) {
      List<dynamic> siblings = [];
      try {
        siblings = jsonDecode(_existingData!['siblings']);
      } catch (_) {
        siblings = [];
      }
      for (var i = 0; i < siblings.length; i++) {
        final controller = TextEditingController(text: siblings[i].toString());
        _siblingControllers.add(controller);
        _siblingLabels.add('Sibling ${i + 1}');
      }
    }

    // Populate educational background
    if (_existingData!['educational_background'] != null) {
      List<dynamic> eduBackground = [];
      try {
        eduBackground = jsonDecode(_existingData!['educational_background']);
      } catch (_) {
        eduBackground = [];
      }
      if (eduBackground.isNotEmpty) {
        _grade7SchoolController.text = eduBackground.isNotEmpty ? eduBackground[0]['school'] ?? '' : '';
        _grade7YearController.text = eduBackground.isNotEmpty ? eduBackground[0]['year_completed'] ?? '' : '';
        _grade8SchoolController.text = eduBackground.length > 1 ? eduBackground[1]['school'] ?? '' : '';
        _grade8YearController.text = eduBackground.length > 1 ? eduBackground[1]['year_completed'] ?? '' : '';
        _grade9SchoolController.text = eduBackground.length > 2 ? eduBackground[2]['school'] ?? '' : '';
        _grade9YearController.text = eduBackground.length > 2 ? eduBackground[2]['year_completed'] ?? '' : '';
        _grade10SchoolController.text = eduBackground.length > 3 ? eduBackground[3]['school'] ?? '' : '';
        _grade10YearController.text = eduBackground.length > 3 ? eduBackground[3]['year_completed'] ?? '' : '';
        _grade11SchoolController.text = eduBackground.length > 4 ? eduBackground[4]['school'] ?? '' : '';
        _grade11YearController.text = eduBackground.length > 4 ? eduBackground[4]['year_completed'] ?? '' : '';
        _grade12SchoolController.text = eduBackground.length > 5 ? eduBackground[5]['school'] ?? '' : '';
        _grade12YearController.text = eduBackground.length > 5 ? eduBackground[5]['year_completed'] ?? '' : '';
      }
    }
  }

  void _addSibling() {
    setState(() {
      _siblingControllers.add(TextEditingController());
      _siblingLabels.add('Sibling ${_siblingControllers.length}');
    });
  }

  void _removeSibling(int index) {
    setState(() {
      _siblingControllers[index].dispose();
      _siblingControllers.removeAt(index);
      _siblingLabels.removeAt(index);
      // Update labels
      for (int i = 0; i < _siblingLabels.length; i++) {
        _siblingLabels[i] = 'Sibling ${i + 1}';
      }
    });
  }

  Future<void> _submitForm() async {
    final userId = widget.userData?['id'];
    if (userId == null) return;

    // Prepare siblings data
    List<Map<String, String>> siblings = [];
    for (var controller in _siblingControllers) {
      if (controller.text.isNotEmpty) {
        siblings.add({'name': controller.text, 'civil_status': '', 'occupation': ''});
      }
    }

    // Prepare educational background data
    List<Map<String, String>> educationalBackground = [
      {'grade': '7', 'school': _grade7SchoolController.text, 'year_completed': _grade7YearController.text},
      {'grade': '8', 'school': _grade8SchoolController.text, 'year_completed': _grade8YearController.text},
      {'grade': '9', 'school': _grade9SchoolController.text, 'year_completed': _grade9YearController.text},
      {'grade': '10', 'school': _grade10SchoolController.text, 'year_completed': _grade10YearController.text},
      {'grade': '11', 'school': _grade11SchoolController.text, 'year_completed': _grade11YearController.text},
      {'grade': '12', 'school': _grade12SchoolController.text, 'year_completed': _grade12YearController.text},
    ];

    final data = {
      'user_id': userId,
      'student_id': widget.userData?['student_id'] ?? '',
      'program_enrolled': _programEnrolledController.text,
      'sex': _selectedSex,
      'full_name': _fullNameController.text,
      'address': _addressController.text,
      'age': int.tryParse(_ageController.text),
      'civil_status': _civilStatusController.text,
      'date_of_birth': _dateOfBirthController.text,
      'place_of_birth': _placeOfBirthController.text,
      'lrn': _lrnController.text,
      'cellphone': _cellphoneController.text,
      'email_address': _emailController.text,
      'father_name': _fatherNameController.text,
      'father_age': int.tryParse(_fatherAgeController.text),
      'father_occupation': _fatherOccupationController.text,
      'mother_name': _motherNameController.text,
      'mother_age': int.tryParse(_motherAgeController.text),
      'mother_occupation': _motherOccupationController.text,
      'living_with_parents': _livingWithParents,
      'guardian_name': _guardianNameController.text,
      'guardian_relationship': _guardianRelationshipController.text,
      'siblings': siblings,
      'educational_background': educationalBackground,
      'awards_received': _awardsReceivedController.text,
      'transferee_college_name': _transfereeCollegeController.text,
      'transferee_program': _transfereeProgramController.text,
      'physical_defect': _hasPhysicalDefect ? 'YES' : 'NO',
      'allergies_food': _allergiesFoodController.text,
      'allergies_medicine': _allergiesMedicineController.text,
      'exam_taken': _examTakenController.text,
      'exam_date': _examDateController.text,
      'raw_score': double.tryParse(_rawScoreController.text),
      'percentile': double.tryParse(_percentileController.text),
      'adjectival_rating': _adjectivalRatingController.text,
    };

    try {
      if (_existingData != null) {
        await AppConfig.supabase
            .from('student_cumulative_records')
            .update(data)
            .eq('user_id', userId);
      } else {
        await AppConfig.supabase
            .from('student_cumulative_records')
            .insert(data);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student Cumulative Record Form Submitted Successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error submitting form')),
      );
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(color: Colors.blue.shade700),
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
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.shade300, width: 1),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
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
          colors: [Colors.transparent, Colors.blue.shade300, Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildRadioOption(String title, String value) {
    return Expanded(
      child: ListTile(
        title: Text(title),
        leading: Radio<String>(
          value: value,
          groupValue: _selectedSex,
          onChanged: (String? value) {
            setState(() {
              _selectedSex = value;
            });
          },
          activeColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildYesNoRadio(String title, bool groupValue, Function(bool) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade700,
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('Yes'),
                leading: Radio<bool>(
                  value: true,
                  groupValue: groupValue,
                  onChanged: (bool? value) {
                    if (value != null) onChanged(value);
                  },
                  activeColor: Colors.blue,
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('No'),
                leading: Radio<bool>(
                  value: false,
                  groupValue: groupValue,
                  onChanged: (bool? value) {
                    if (value != null) onChanged(value);
                  },
                  activeColor: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            "Student Cumulative Record Form",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 30, 182, 88),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
 
    return Scaffold(
       appBar: AppBar(
        title: const Text(
          "Student Cumulative Record Form",
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
                    Colors.lightBlue.withOpacity(0.3),
                    Colors.blue.shade900.withOpacity(1.0),
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        _buildSectionTitle('Program Enrolled'),
                        DropdownButtonFormField<String>(
                          value: _selectedProgram,
                          isDense: true,
                          menuMaxHeight: 200.0,
                          items: _programs.map((program) {
                            return DropdownMenuItem<String>(
                              value: program['course_name'],
                              child: Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6),
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  program['course_name'],
                                  style: const TextStyle(fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedProgram = value;
                              _programEnrolledController.text = value ?? '';
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'Program Enrolled',
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            labelStyle: TextStyle(color: Colors.blue.shade700),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Select a program';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Sex'),
                        Row(
                          children: [
                            _buildRadioOption('Male', 'Male'),
                            _buildRadioOption('Female', 'Female'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        _buildSectionTitle('A. PERSONAL AND FAMILY INFORMATION'),
                        _buildTextField('NAME (LAST NAME, FIRST NAME, MIDDLE NAME)', _fullNameController),
                        _buildTextField('ADDRESS', _addressController),
                        _buildTextField('AGE', _ageController),
                        _buildTextField('CIVIL STATUS', _civilStatusController),
                        _buildTextField('DATE OF BIRTH', _dateOfBirthController),
                        _buildTextField('PLACE OF BIRTH', _placeOfBirthController),
                        _buildTextField('LRN#', _lrnController),
                        _buildTextField('CELLPHONE#', _cellphoneController),
                        _buildTextField('EMAIL ADDRESS', _emailController),
                        const SizedBox(height: 16),
                        _buildSectionTitle('FATHER - NAME, AGE, OCCUPATION'),
                        _buildTextField('Father\'s Name', _fatherNameController),
                        _buildTextField('Father\'s Age', _fatherAgeController),
                        _buildTextField('Father\'s Occupation', _fatherOccupationController),
                        const SizedBox(height: 16),
                        _buildSectionTitle('MOTHER - NAME, AGE, OCCUPATION'),
                        _buildTextField('Mother\'s Name', _motherNameController),
                        _buildTextField('Mother\'s Age', _motherAgeController),
                        _buildTextField('Mother\'s Occupation', _motherOccupationController),
                        const SizedBox(height: 16),
                        _buildYesNoRadio('Are you living with your Parents?', _livingWithParents, (value) {
                          setState(() {
                            _livingWithParents = value;
                          });
                        }),
                        if (!_livingWithParents) ...[
                          _buildTextField('If NO, who is your Guardian here? Name', _guardianNameController),
                          _buildTextField('RELATIONSHIP', _guardianRelationshipController),
                        ],
                        const SizedBox(height: 16),
                        _buildSectionTitle('NAME OF BROTHERS/SISTERS, CIVIL STATUS, OCCUPATION'),
                        Column(
                          children: [
                            ..._siblingControllers.asMap().entries.map((entry) {
                              int index = entry.key;
                              TextEditingController controller = entry.value;
                              return Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                                      child: TextFormField(
                                        controller: controller,
                                        decoration: InputDecoration(
                                          labelText: _siblingLabels[index],
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
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                          labelStyle: TextStyle(color: Colors.blue.shade700),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter ${_siblingLabels[index]}';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove, color: Colors.red),
                                    onPressed: () => _removeSibling(index),
                                  ),
                                ],
                              );
                            }),
                            const SizedBox(height: 8),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _addSibling,
                                icon: const Icon(Icons.add),
                                label: const Text('Add Sibling'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        _buildSectionTitle('B. EDUCATIONAL BACKGROUND'),
                        _buildTextField('7th - NAME OF SCHOOL', _grade7SchoolController),
                        _buildTextField('7th - YEAR COMPLETED', _grade7YearController),
                        _buildTextField('8th - NAME OF SCHOOL', _grade8SchoolController),
                        _buildTextField('8th - YEAR COMPLETED', _grade8YearController),
                        _buildTextField('9th - NAME OF SCHOOL', _grade9SchoolController),
                        _buildTextField('9th - YEAR COMPLETED', _grade9YearController),
                        _buildTextField('10th - NAME OF SCHOOL', _grade10SchoolController),
                        _buildTextField('10th - YEAR COMPLETED', _grade10YearController),
                        _buildTextField('11th - NAME OF SCHOOL', _grade11SchoolController),
                        _buildTextField('11th - YEAR COMPLETED', _grade11YearController),
                        _buildTextField('12th - NAME OF SCHOOL', _grade12SchoolController),
                        _buildTextField('12th - YEAR COMPLETED', _grade12YearController),
                        const SizedBox(height: 16),
                        _buildSectionTitle('Awards Received if any'),
                        _buildTextField('GRADE LEVEL - AWARD/S RECEIVED', _awardsReceivedController, maxLines: 5),
                        const SizedBox(height: 16),
                        const Text(
                          '"Primed to Lead and Serve for Progress"',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),
                        _buildSectionTitle('(For Transferee only): NAME OF SCHOOL - PROGRAM'),
                        _buildTextField('College if any - NAME OF SCHOOL', _transfereeCollegeController),
                        _buildTextField('College if any - PROGRAM', _transfereeProgramController),
                      ],
                    ),
                  ),
                  _buildSectionDivider(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        _buildSectionTitle('C. HEALTH RECORD'),
                        _buildYesNoRadio('Do you have any physical defect or disability which may give you inconveniences or interfere with your studies?', _hasPhysicalDefect, (value) {
                          setState(() {
                            _hasPhysicalDefect = value;
                          });
                        }),
                        if (_hasPhysicalDefect) ...[
                          _buildTextField('If YES, kindly state the nature of the defect', _natureOfDefectController),
                        ],
                        _buildTextField('FOOD/S', _allergiesFoodController),
                        _buildTextField('MEDICINE/S', _allergiesMedicineController),
                      ],
                    ),
                  ),
                  if (_hasAdmissionOfficerAccess()) ...[
                    _buildSectionDivider(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                          _buildSectionTitle('D. FOR ADMISSION OFFICER USE'),
                          _buildTextField('EXAM TAKEN', _examTakenController),
                          _buildTextField('DATE OF EXAM', _examDateController),
                          _buildTextField('RAW SCORE', _rawScoreController),
                          _buildTextField('PERCENTILE', _percentileController),
                          _buildTextField('ADJECTIVAL RATING', _adjectivalRatingController),
                        ],
                      ),
                    ),
                  ],
                  _buildSectionDivider(),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                        const SizedBox(height: 24),
                        Center(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 6,
                              shadowColor: Colors.blue.shade300,
                            ),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await _submitForm();
                              }
                            },
                            child: const Text(
                              'Submit Form',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
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

  @override
  void dispose() {
    for (var controller in _siblingControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
