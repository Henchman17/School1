import 'package:flutter/material.dart';

class ScrfPage extends StatefulWidget {
  const ScrfPage({Key? key}) : super(key: key);

  @override
  _ScrfPageState createState() => _ScrfPageState();
}

class _ScrfPageState extends State<ScrfPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSex;

  Widget _buildTextField(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
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
          activeColor: Colors.green,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Cumulative Record Form'),
        backgroundColor: Colors.green[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Program Enrolled'),
              _buildTextField('Program Enrolled'),
              _buildSectionTitle('Sex'),
              Row(
                children: [
                  _buildRadioOption('Male', 'Male'),
                  _buildRadioOption('Female', 'Female'),
                ],
              ),
              _buildSectionTitle('A. PERSONAL AND FAMILY INFORMATION'),
              _buildTextField('NAME (LAST NAME, FIRST NAME, MIDDLE NAME)'),
              _buildTextField('ADDRESS'),
              _buildTextField('ZIPCODE'),
              _buildTextField('AGE'),
              _buildTextField('CIVIL STATUS'),
              _buildTextField('DATE OF BIRTH'),
              _buildTextField('PLACE OF BIRTH'),
              _buildTextField('LRN#'),
              _buildTextField('CELLPHONE#'),
              _buildTextField('EMAIL ADDRESS'),
              _buildSectionTitle('FATHER - NAME, AGE, OCCUPATION'),
              _buildTextField('Father\'s Name'),
              _buildTextField('Father\'s Age'),
              _buildTextField('Father\'s Occupation'),
              _buildSectionTitle('MOTHER - NAME, AGE, OCCUPATION'),
              _buildTextField('Mother\'s Name'),
              _buildTextField('Mother\'s Age'),
              _buildTextField('Mother\'s Occupation'),
              _buildTextField('Are you living with your Parents? YES / NO'),
              _buildTextField('If NO, who is your Guardian here? Name'),
              _buildTextField('RELATIONSHIP'),
              _buildSectionTitle('NAME OF BROTHERS/SISTERS, CIVIL STATUS, OCCUPATION'),
              _buildTextField('Eldest'),
              _buildTextField('2nd'),
              _buildTextField('3rd'),
              _buildTextField('4th'),
              _buildTextField('5th'),
              _buildTextField('6th'),
              _buildTextField('7th'),
              _buildTextField('8th'),
              _buildTextField('9th'),
              _buildTextField('10th'),
              _buildSectionTitle('B. EDUCATIONAL BACKGROUND'),
              _buildTextField('7th - NAME OF SCHOOL'),
              _buildTextField('7th - YEAR COMPLETED'),
              _buildTextField('8th - NAME OF SCHOOL'),
              _buildTextField('8th - YEAR COMPLETED'),
              _buildTextField('9th - NAME OF SCHOOL'),
              _buildTextField('9th - YEAR COMPLETED'),
              _buildTextField('10th - NAME OF SCHOOL'),
              _buildTextField('10th - YEAR COMPLETED'),
              _buildTextField('11th - NAME OF SCHOOL'),
              _buildTextField('11th - YEAR COMPLETED'),
              _buildTextField('12th - NAME OF SCHOOL'),
              _buildTextField('12th - YEAR COMPLETED'),
              _buildSectionTitle('Awards Received if any'),
              _buildTextField('GRADE LEVEL - AWARD/S RECEIVED', maxLines: 5),
              const SizedBox(height: 16),
              const Text(
                '"Primed to Lead and Serve for Progress"',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('(For Transferee only): NAME OF SCHOOL - PROGRAM'),
              _buildTextField('College if any - NAME OF SCHOOL'),
              _buildTextField('College if any - PROGRAM'),
              _buildSectionTitle('C. HEALTH RECORD'),
              _buildTextField('Do you have any physical defect or disability which may give you inconveniences or interfere with your studies? YES / NO'),
              _buildTextField('If YES, kindly state the nature of the defect'),
              _buildTextField('Kindly state your allergies in food/s and medicine/s'),
              _buildTextField('FOOD/S'),
              _buildTextField('MEDICINE/S'),
              _buildSectionTitle('D. FOR ADMISSION OFFICER USE'),
              _buildTextField('EXAM TAKEN'),
              _buildTextField('DATE OF EXAM'),
              _buildTextField('RAW SCORE'),
              _buildTextField('PERCENTILE'),
              _buildTextField('ADJECTIVAL RATING'),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Process form submission here
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Student Cumulative Record Form Submitted')),
                      );
                    }
                  },
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 18),
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
