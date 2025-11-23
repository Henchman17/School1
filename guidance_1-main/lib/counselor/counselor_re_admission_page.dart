import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CounselorReAdmissionPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CounselorReAdmissionPage({super.key, this.userData});

  @override
  State<CounselorReAdmissionPage> createState() => _CounselorReAdmissionPageState();
}

class _CounselorReAdmissionPageState extends State<CounselorReAdmissionPage> {
  List<Map<String, dynamic>> _cases = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterStatus = 'all';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  DateTime? _selectedDate;

  static const String apiBaseUrl = 'http://localhost:8080';

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
      final counselorId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/counselor/re-admission-cases?counselor_id=$counselorId'),
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
          _errorMessage = 'Failed to load re-admission cases';
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

  Future<void> _updateCaseStatus(int caseId, String status, String? notes) async {
    try {
      final counselorId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/counselor/re-admission-cases/$caseId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'counselor_id': counselorId,
          'status': status,
          'notes': notes,
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

  void _showCaseDetails(Map<String, dynamic> caseData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Re-admission Case: ${caseData['student_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student Number', caseData['student_number']),
              _buildDetailRow('Reason of Absence', caseData['reason_of_absence']),
              _buildDetailRow('Status', caseData['status']),
              if (caseData['notes'] != null && caseData['notes'].isNotEmpty)
                _buildDetailRow('Notes', caseData['notes']),
              _buildDetailRow('Counselor ID', caseData['counselor_id']?.toString()),
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

  Widget _buildInfoRow(IconData icon, String label, String? value) {
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
                  text: value ?? 'N/A',
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

  void _showUpdateDialog(Map<String, dynamic> caseData) {
    String selectedStatus = caseData['status'];
    final notesController = TextEditingController(text: caseData['notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Case Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Pending')),
                DropdownMenuItem(value: 'under_review', child: Text('Under Review')),
                DropdownMenuItem(value: 'approved', child: Text('Approved')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejected')),
              ],
              onChanged: (value) => selectedStatus = value!,
              decoration: const InputDecoration(labelText: 'Status'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateCaseStatus(caseData['id'], selectedStatus, notesController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
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

    // Apply search filter across multiple fields
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      cases = cases.where((c) {
        final studentNumber = c['student_number']?.toString().toLowerCase() ?? '';
        final studentName = c['student_name']?.toString().toLowerCase() ?? '';
        final reasonOfAbsence = c['reason_of_absence']?.toString().toLowerCase() ?? '';
        final notes = c['notes']?.toString().toLowerCase() ?? '';
        final counselorId = c['counselor_id']?.toString().toLowerCase() ?? '';

        return studentNumber.contains(searchTerm) ||
               studentName.contains(searchTerm) ||
               reasonOfAbsence.contains(searchTerm) ||
               notes.contains(searchTerm) ||
               counselorId.contains(searchTerm);
      }).toList();
    }

    return cases;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Re-Admission Cases',
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
                          onPressed: _showAddDialog,
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
                      'Filter by Status',
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
                      _buildFilterChip('All', 'all', Colors.grey.shade600),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending', Colors.orange.shade600),
                      const SizedBox(width: 8),
                      _buildFilterChip('Under Review', 'under_review', Colors.blue.shade600),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved', Colors.green.shade600),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected', Colors.red.shade600),
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
                                Icon(Icons.folder_open, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No re-admission cases found'),
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
                                              Icons.person_add,
                                              color: Color(0xFF1E88E5),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Re-admission Case #${caseData['id']}',
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
                                                  caseData['status'] == 'pending' ? Icons.schedule :
                                                  caseData['status'] == 'under_review' ? Icons.search :
                                                  caseData['status'] == 'approved' ? Icons.check_circle :
                                                  caseData['status'] == 'rejected' ? Icons.cancel :
                                                  Icons.help_outline,
                                                  color: _getStatusColor(caseData['status']),
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  (caseData['status'] ?? 'pending').toString().toUpperCase(),
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
                                            _buildInfoRow(Icons.description, 'Reason of Absence', caseData['reason_of_absence']),
                                            const SizedBox(height: 8),
                                            _buildInfoRow(Icons.date_range, 'Created', caseData['created_at']?.toString().split('T')[0]),
                                            if (caseData['notes'] != null && caseData['notes'].isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              _buildInfoRow(Icons.note, 'Notes', caseData['notes']),
                                            ],
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

  void _showAddDialog() {
    final TextEditingController studentNumberController = TextEditingController();
    final TextEditingController nameController = TextEditingController();
    final TextEditingController reasonOfAbsenceController = TextEditingController();
    final TextEditingController notesController = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Re-Admission Case'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: studentNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Student Number',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: reasonOfAbsenceController,
                  decoration: const InputDecoration(
                    labelText: 'Reason of Absence',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Date',
                        hintText: selectedDate != null
                            ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                            : 'Select Date',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
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
              onPressed: () async {
                // Validation
                if (studentNumberController.text.isEmpty ||
                    nameController.text.isEmpty ||
                    reasonOfAbsenceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all required fields')),
                  );
                  return;
                }

                final newRecord = {
                  'student_number': studentNumberController.text,
                  'student_name': nameController.text,
                  'reason_of_absence': reasonOfAbsenceController.text,
                  'notes': notesController.text,
                  'status': 'pending',
                  'date': selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : null,
                };

                try {
                  final counselorId = widget.userData?['id'] ?? 0;
                  final response = await http.post(
                    Uri.parse('$apiBaseUrl/api/counselor/re-admission-cases'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'student_name': newRecord['student_name'],
                      'student_number': newRecord['student_number'],
                      'reason_of_absence': newRecord['reason_of_absence'],
                      'notes': newRecord['notes'],
                      'status': newRecord['status'],
                      'date': newRecord['date'],
                      'counselor_id': counselorId,
                    }),
                  );

                  if (response.statusCode == 201) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-admission case added successfully')),
                    );
                    Navigator.of(context).pop();
                    _fetchCases();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to add re-admission case')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding re-admission case: $e')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterChip(String label, String value, Color color) {
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: _filterStatus == value ? Colors.white : color)),
      selected: _filterStatus == value,
      selectedColor: color,
      backgroundColor: color.withOpacity(0.15),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterStatus = value;
          });
        }
      },
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelPadding: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
