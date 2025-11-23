import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminDisciplinePage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminDisciplinePage({super.key, this.userData});

  @override
  State<AdminDisciplinePage> createState() => _AdminDisciplinePageState();
}

class _AdminDisciplinePageState extends State<AdminDisciplinePage> {
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterStatus = 'all';
  String _filterSeverity = 'all';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  static const String apiBaseUrl = 'http://localhost:8080';

  // Offense lists
  static final List<String> lightOffenses = [
    'Loitering and/or making noise within the College premises disturbing classes, programs, or activities.',
    'Non-wearing of ID card or failure to present ID/Registration Form when asked.',
    'Non-wearing of prescribed dress code or inappropriate uniform/accessories.',
    'Littering, unhygienic use of DLSP facilities, or unhygienic excretion.',
    'Cross-dressing during uniform days and wash days.',
    'Staying or loitering on stairs and corridors except during bad weather.',
    'Shouting on stairs and corridors.',
    'Habitual absence and tardiness.',
    'Failure to present admission slip from Guidance Office after an absence.',
    'Disturbing classes (loquacity, signaling, etc.) without permission.',
    'Littering or scattering paper, chewing gum on premises.',
    'Improper hair grooming as determined by College officials.',
    'Unauthorized solicitation of money or sale of tickets within premises.',
    'Leaving class without instructor\'s permission.',
    'Using cellular phones or IT devices in class without permission.',
    'Entering ladies\' comfort rooms (for male students).',
    'Wearing earrings for male students or multiple earrings for females within premises or during activities.',
    'Wearing caps or hats inside classrooms or covered facilities.',
    'Irresponsible use of water and/or electricity within the premises.',
  ];

  static final List<String> lessGraveOffenses = [
    'Cheating in examinations or reports (including possession of materials, allowing copying, copying, talking during exam, exam leakage, soliciting or preparing for others, and related acts).',
    'Possession, carrying, or bringing gambling cards/devices; engaging in betting/gambling.',
    'Unauthorized passage/entry through prohibited areas.',
    'Lending or using another\'s ID; misrepresentation of identity.',
    'Posting or removing posters/materials without approval of OSAS.',
    'Any form of vandalism on College property.',
    'Damaging personal property of others within or outside the College.',
    'Unauthorized use of DLPS logo or seal, or imitation thereof.',
    'Bullying or violations of the Anti-Bullying Act (RA 10627) for under-18 students.',
    'Smoking within College premises.',
    'Committing immoral acts involving offensive materials or indecent acts on premises.',
    'Unauthorized use or tampering with College properties.',
    'Providing means for outsiders to gain entry without consent.',
    'Violating conditions set by approving authority.',
    'Evading service of penalties.',
    'Public and indecent display of physical intimacy within premises or during activities.',
    'Removing or tearing pages from library books or materials.',
    'Giving talks or campaigning to students in classrooms without approval.',
    'Organizing or requesting unapproved student organizations.',
    'Disrespect toward national symbols (flag, anthem, etc.).',
    'Disrespect toward College flag, hymn, or logo.',
  ];

  static final List<String> graveOffenses = [
    'Fourth (4th) and subsequent commission of the same less grave offense (up to 15 days for 3rd offense) can lead to longer suspensions or non-readmission/exclusion.',
    'Intentional or reckless damage or destruction to College properties.',
    'Obtaining money or property through deceit or fraud.',
    'Unauthorized use of funds or property; failure to account for funds.',
    'Libelous/slanderous language or acts against DLSP community or affiliates.',
    'Submitting false or misleading statements in official documents.',
    'Submitting plagiarized academic work.',
    'Misappropriation of funds or property of student organizations; misusing funds.',
    'Illegal association or membership in unlawful organizations.',
    'Engaging in fights or duels, with or without weapons.',
    'Participating in mob/riot/tumult within premises.',
    'Preventing or threatening others from attending classes or activities.',
    'Manipulation of data affecting research integrity.',
    'Carrying or possessing dangerous weapons on premises.',
    'Forgery of signatures or documents; tampering with records.',
    'Intentionally inflicting physical injuries.',
    'Assaulting students or staff.',
    'Attacking or threatening faculty or staff during duties.',
    'Discharge of firearms or explosives on premises.',
    'Any act of lasciviousness toward another person.',
    'Preventing entry/exit or restricting movement within premises.',
    'Falsely representing oneself as an officer or official.',
    'Unauthorized burning of property or attempted burning.',
    'Abusive verbal harassment or coercion to force action.',
    'Instigating absence or disruption of official activities.',
    'Possession of alcoholic drinks or prohibited drugs or entering premises under the influence.',
    'Illegal demonstrations or concerted activities disrupting classes.',
    'Gross discourtesy to school officials, faculty, or security.',
    'Assaulting any student or school personnel.',
    'Stealing on school premises.',
    'Hazing or initiation rites for unrecognized/unaccredited organizations.',
    'Hooliganism or riotous conduct near/school vicinity.',
    'Acts that malign the College via online content (cybercrime-related defamation).',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCases();
  }

  Future<void> _fetchCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/discipline-cases?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _cases = List<Map<String, dynamic>>.from(data['cases']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load discipline cases';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateCaseStatus(int caseId, String status, String? actionTaken, String? notes) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/discipline-cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': adminId,
          'status': status,
          'action_taken': actionTaken,
          'admin_notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case updated successfully')),
        );
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update case')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating case: $e')),
      );
    }
  }

  Future<void> _updateDisciplineCase(int caseId, Map<String, dynamic> caseData) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/discipline-cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': adminId,
          ...caseData,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discipline case updated successfully')),
        );
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update discipline case')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating discipline case: $e')),
      );
    }
  }

  void _showCaseDetails(Map<String, dynamic> caseData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discipline Case: ${caseData['student_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Case #', caseData['id']?.toString()),
              _buildDetailRow('Student Name', caseData['student_name']),
              _buildDetailRow('Student Number', caseData['student_number']),
              _buildDetailRow('Grade Level', caseData['grade_level']),
              _buildDetailRow('Program', caseData['program']),
              _buildDetailRow('Section', caseData['section']),
              _buildDetailRow('Incident Date', caseData['incident_date']?.toString().split('T')[0]),
              _buildDetailRow('Location', caseData['incident_location']),
              _buildDetailRow('Severity', caseData['severity']),
              _buildDetailRow('Assigned Admin', caseData['counselor_name'] ?? 'Unknown Admin'),
              _buildDetailRow('Status', caseData['status']),
              const Divider(),
              const Text('Incident Description:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(caseData['incident_description'] ?? 'N/A'),
              ),
              if (caseData['witnesses'] != null && caseData['witnesses'].isNotEmpty) ...[
                const Text('Witnesses:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(caseData['witnesses']),
                ),
              ],
              if (caseData['action_taken'] != null && caseData['action_taken'].isNotEmpty) ...[
                const Text('Action Taken:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(caseData['action_taken']),
                ),
              ],
              if (caseData['admin_notes'] != null && caseData['admin_notes'].isNotEmpty) ...[
                const Text('Admin Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(caseData['admin_notes']),
                ),
              ],
              _buildDetailRow('Created', caseData['created_at']?.toString().split('T')[0]),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(Map<String, dynamic> caseData) {
    String selectedStatus = caseData['status'];
    String selectedSeverity = caseData['severity'];
    // Map invalid severity values to valid ones
    if (selectedSeverity == 'moderate') {
      selectedSeverity = 'less_grave_offenses';
    } else if (!['light_offenses', 'less_grave_offenses', 'grave_offenses'].contains(selectedSeverity)) {
      selectedSeverity = 'light_offenses';
    }
    final studentNameController = TextEditingController(text: caseData['student_name']);
    final studentNumberController = TextEditingController(text: caseData['student_number']);
    final gradeController = TextEditingController(text: caseData['grade_level']);
    final courseController = TextEditingController(text: caseData['program']);
    final sectionController = TextEditingController(text: caseData['section']);
    final incidentDateController = TextEditingController(text: caseData['incident_date']?.toString().split('T')[0]);
    final incidentLocationController = TextEditingController(text: caseData['incident_location']);
    final incidentDescriptionController = TextEditingController(text: caseData['incident_description']);
    final witnessesController = TextEditingController(text: caseData['witnesses']);
    final counselorController = TextEditingController(text: caseData['counselor']);
    final actionController = TextEditingController(text: caseData['action_taken']);
    final notesController = TextEditingController(text: caseData['admin_notes']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Discipline Case'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: studentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: studentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Student Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(
                    labelText: 'Grade Level',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(
                    labelText: 'Program',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: sectionController,
                  decoration: const InputDecoration(
                    labelText: 'Section',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: incidentDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Incident Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                      incidentDateController.text = formattedDate;
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedSeverity,
                  items: const [
                    DropdownMenuItem(value: 'light_offenses', child: Text('Light Offenses')),
                    DropdownMenuItem(value: 'less_grave_offenses', child: Text('Less Grave Offenses')),
                    DropdownMenuItem(value: 'grave_offenses', child: Text('Grave Offenses')),
                  ],
                  onChanged: (value) => setState(() => selectedSeverity = value!),
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: incidentLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Incident Location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: incidentDescriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Incident Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: witnessesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Witnesses',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: counselorController,
                  decoration: const InputDecoration(
                    labelText: 'Counselor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(value: 'under_investigation', child: Text('Under Investigation')),
                    DropdownMenuItem(value: 'resolved', child: Text('Resolved')),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                  ],
                  onChanged: (value) => setState(() => selectedStatus = value!),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: actionController,
                  decoration: const InputDecoration(
                    labelText: 'Action Taken',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Notes',
                    border: OutlineInputBorder(),
                  ),
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
                if (studentNameController.text.isEmpty ||
                    studentNumberController.text.isEmpty ||
                    incidentDateController.text.isEmpty ||
                    incidentDescriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                _updateDisciplineCase(caseData['id'], {
                  'student_name': studentNameController.text,
                  'student_number': studentNumberController.text,
                  'grade_level': gradeController.text,
                  'program': courseController.text,
                  'section': sectionController.text,
                  'incident_date': incidentDateController.text,
                  'severity': selectedSeverity,
                  'incident_location': incidentLocationController.text,
                  'incident_description': incidentDescriptionController.text,
                  'witnesses': witnessesController.text,
                  'counselor': counselorController.text,
                  'status': selectedStatus,
                  'action_taken': actionController.text,
                  'admin_notes': notesController.text,
                });
                Navigator.of(context).pop();
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int caseId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Discipline Case'),
        content: const Text('Are you sure you want to delete this discipline case? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteDisciplineCase(caseId);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredCases {
    var cases = _cases;

    // Apply status filter
    if (_filterStatus != 'all') {
      cases = cases.where((c) => c['status'] == _filterStatus).toList();
    }

    // Apply severity filter
    if (_filterSeverity != 'all') {
      cases = cases.where((c) => c['severity'] == _filterSeverity).toList();
    }

    // Apply search filter across multiple fields
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      cases = cases.where((c) {
        final studentNumber = c['student_number']?.toString().toLowerCase() ?? '';
        final studentName = c['student_name']?.toString().toLowerCase() ?? '';
        final gradeLevel = c['grade_level']?.toString().toLowerCase() ?? '';
        final program = c['program']?.toString().toLowerCase() ?? '';
        final section = c['section']?.toString().toLowerCase() ?? '';
        final incidentDescription = c['incident_description']?.toString().toLowerCase() ?? '';
        final counselor = c['counselor']?.toString().toLowerCase() ?? '';

        return studentNumber.contains(searchTerm) ||
               studentName.contains(searchTerm) ||
               gradeLevel.contains(searchTerm) ||
               program.contains(searchTerm) ||
               section.contains(searchTerm) ||
               incidentDescription.contains(searchTerm) ||
               counselor.contains(searchTerm);
      }).toList();
    }

    return cases;
  }

  Future<void> _createDisciplineCase(Map<String, dynamic> caseData) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/admin/discipline-cases'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': adminId,
          'status': 'open',
          ...caseData,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Discipline case created successfully')),
        );
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create discipline case')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating discipline case: $e')),
      );
    }
  }

  Future<void> _deleteDisciplineCase(int caseId) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.delete(
        Uri.parse('$apiBaseUrl/api/admin/discipline-cases/$caseId?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Case deleted successfully')),
        );
        _fetchCases();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete case')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting case: $e')),
      );
    }
  }

  void _showCreateDialog() {
    final studentNameController = TextEditingController();
    final studentNumberController = TextEditingController();
    final gradeController = TextEditingController();
    final courseController = TextEditingController();
    final sectionController = TextEditingController();
    final incidentDateController = TextEditingController();
    final incidentLocationController = TextEditingController();
    final incidentDescriptionController = TextEditingController();
    final witnessesController = TextEditingController();
    final counselorController = TextEditingController();
    String selectedSeverity = 'light_offenses';
    String selectedOffense = '';
    DateTime? selectedIncidentDate;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  const Text(
                    'Create New Discipline Case',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: studentNameController,
                            decoration: const InputDecoration(
                              labelText: 'Student Name *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: studentNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Student Number *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: gradeController,
                            decoration: const InputDecoration(
                              labelText: 'Grade Level',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: courseController,
                            decoration: const InputDecoration(
                              labelText: 'Program',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: sectionController,
                            decoration: const InputDecoration(
                              labelText: 'Section',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: incidentDateController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Incident Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                                incidentDateController.text = formattedDate;
                              }
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedSeverity,
                            items: const [
                              DropdownMenuItem(value: 'light_offenses', child: Text('Light Offenses')),
                              DropdownMenuItem(value: 'less_grave_offenses', child: Text('Less Grave Offenses')),
                              DropdownMenuItem(value: 'grave_offenses', child: Text('Grave Offenses')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedSeverity = value!;
                                selectedOffense = '';
                                incidentDescriptionController.text = '';
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Severity *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: selectedOffense.isEmpty ? null : selectedOffense,
                            items: _getOffenseList(selectedSeverity).map((offense) => DropdownMenuItem(value: offense, child: Text(offense))).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedOffense = value!;
                                incidentDescriptionController.text = selectedOffense;
                              });
                            },
                            decoration: const InputDecoration(
                              labelText: 'Offense Type',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: incidentLocationController,
                            decoration: const InputDecoration(
                              labelText: 'Incident Location',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: incidentDescriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Incident Description *',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: witnessesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Witnesses',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: counselorController,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Counselor (Optional)',
                              border: OutlineInputBorder(),
                              hintText: 'Leave empty to assign to current admin',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (studentNameController.text.isEmpty ||
                              studentNumberController.text.isEmpty ||
                              incidentDateController.text.isEmpty ||
                              incidentDescriptionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please fill in all required fields')),
                            );
                            return;
                          }

                          // Validate incident date format
                          try {
                            DateTime.parse(incidentDateController.text);
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invalid incident date format. Use YYYY-MM-DD')),
                            );
                            return;
                          }

                          int? counselorId;
                          if (counselorController.text.isNotEmpty) {
                            counselorId = int.tryParse(counselorController.text);
                            if (counselorId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Invalid counselor ID. Please enter a valid number.')),
                              );
                              return;
                            }
                          } else {
                            counselorId = widget.userData?['id'];
                          }

                          _createDisciplineCase({
                            'student_name': studentNameController.text,
                            'student_number': studentNumberController.text,
                            'grade_level': gradeController.text,
                            'program': courseController.text,
                            'section': sectionController.text,
                            'incident_date': incidentDateController.text,
                            'severity': selectedSeverity,
                            'offense_type': selectedOffense,
                            'incident_location': incidentLocationController.text,
                            'incident_description': incidentDescriptionController.text,
                            'witnesses': witnessesController.text,
                            'counselor_id': counselorId,
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _getOffenseList(String severity) {
    switch (severity) {
      case 'light_offenses':
        return lightOffenses;
      case 'less_grave_offenses':
        return lessGraveOffenses;
      case 'grave_offenses':
        return graveOffenses;
      default:
        return [];
    }
  }

  Widget _buildFilterChip(String label, String value, Color color, bool isStatus) {
    return FilterChip(
      label: Text(label),
      selected: isStatus ? _filterStatus == value : _filterSeverity == value,
      onSelected: (selected) => setState(() {
        if (isStatus) {
          _filterStatus = value;
        } else {
          _filterSeverity = value;
        }
      }),
      backgroundColor: color.withOpacity(0.1),
      selectedColor: color,
      checkmarkColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Discipline Cases',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCases,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Add section
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade100.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by student name, number, program, or any field...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear, color: Colors.grey.shade500),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text('Add New Case', style: TextStyle(color: Colors.white)),
                          onPressed: _showCreateDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filter buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Filter by Status & Severity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Status', 'all', Colors.grey.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Open', 'open', Colors.orange.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Under Investigation', 'under_investigation', Colors.blue.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Resolved', 'resolved', Colors.green.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Closed', 'closed', Colors.grey.shade600, true),
                      const SizedBox(width: 16),
                      _buildFilterChip('All Severity', 'all', Colors.grey.shade600, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Light Offenses', 'light_offenses', Colors.yellow.shade700, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Less Grave Offenses', 'less_grave_offenses', Colors.orange.shade600, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Grave Offenses', 'grave_offenses', Colors.red.shade900, false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cases list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 64, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(_errorMessage),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchCases,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredCases.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.gavel, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No discipline cases found'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: _filteredCases.length,
                            itemBuilder: (context, index) {
                              final caseData = _filteredCases[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E88E5).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(
                                              Icons.gavel,
                                              color: Color(0xFF1E88E5),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Discipline Case #${caseData['id']}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF1E88E5),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(caseData['status']).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: _getStatusColor(caseData['status']).withOpacity(0.3),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  caseData['status'] == 'open' ? Icons.warning :
                                                  caseData['status'] == 'under_investigation' ? Icons.search :
                                                  caseData['status'] == 'resolved' ? Icons.check_circle :
                                                  caseData['status'] == 'closed' ? Icons.close :
                                                  Icons.help_outline,
                                                  color: _getStatusColor(caseData['status']),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (caseData['status'] ?? 'open').toString().toUpperCase(),
                                                  style: TextStyle(
                                                    color: _getStatusColor(caseData['status']),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          children: [
                                            _buildInfoRow(Icons.person, 'Student', '${caseData['student_name']} (${caseData['student_number']})'),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.school, 'Grade & Program', 'Grade ${caseData['grade_level']} | ${caseData['program']}'),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.location_on, 'Incident Location', caseData['incident_location'] ?? 'N/A'),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.date_range, 'Incident Date', caseData['incident_date']?.toString().split('T')[0] ?? 'N/A'),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.person_outline, 'Assigned Admin', caseData['counselor_name'] ?? 'Unknown Admin'),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getSeverityColor(caseData['severity']),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    caseData['severity'] ?? 'Unknown',
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () => _showCaseDetails(caseData),
                                            icon: const Icon(Icons.visibility, size: 16),
                                            label: const Text('View Details'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFF1E88E5),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _showUpdateDialog(caseData),
                                            icon: const Icon(Icons.edit, size: 16),
                                            label: const Text('Update'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          TextButton.icon(
                                            onPressed: () => _showDeleteConfirmation(caseData['id']),
                                            icon: const Icon(Icons.delete, size: 16),
                                            label: const Text('Delete'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'open':
        return Colors.orange;
      case 'under_investigation':
        return const Color.fromARGB(255, 4, 137, 245);
      case 'resolved':
        return const Color.fromARGB(255, 36, 160, 40);
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Color _getSeverityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'light_offenses':
        return Colors.yellow[700]!;
      case 'less_grave_offenses':
        return Colors.orange;
      case 'grave_offenses':
        return Colors.red[900]!;
      default:
        return const Color.fromARGB(255, 10, 160, 30);
    }
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
