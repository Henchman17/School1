import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminExitInterviewsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminExitInterviewsPage({super.key, this.userData});

  @override
  State<AdminExitInterviewsPage> createState() => _AdminExitInterviewsPageState();
}

class _AdminExitInterviewsPageState extends State<AdminExitInterviewsPage> {
  List<Map<String, dynamic>> _interviews = [];
  bool _isLoading = true;
  String _errorMessage = '';
  String _filterType = 'all';
  String _filterStatus = 'all';

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _fetchInterviews();
  }

  Future<void> _fetchInterviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/exit-interviews?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _interviews = List<Map<String, dynamic>>.from(data['interviews']);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load exit interviews';
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

  Future<void> _updateInterviewStatus(int interviewId, String status, String? notes) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/exit-interviews/$interviewId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'admin_id': adminId,
          'status': status,
          'admin_notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Interview updated successfully')),
        );
        _fetchInterviews();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update interview')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating interview: $e')),
      );
    }
  }

  void _showInterviewDetails(Map<String, dynamic> interviewData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exit Interview: ${interviewData['student_name']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student Number', interviewData['student_number']),
              _buildDetailRow('Interview Type', interviewData['interview_type']),
              _buildDetailRow('Interview Date', interviewData['interview_date']?.toString().split('T')[0]),
              _buildDetailRow('Status', interviewData['status']),
              const Divider(),
              const Text('Reason for Leaving:',
                style: TextStyle(fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                child: Text(interviewData['reason_for_leaving'] ?? 'N/A'),
              ),
              if (interviewData['satisfaction_rating'] != null) ...[
                _buildDetailRow('Satisfaction Rating', '${interviewData['satisfaction_rating']}/5'),
              ],
              if (interviewData['academic_experience'] != null && interviewData['academic_experience'].isNotEmpty) ...[
                const Text('Academic Experience:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['academic_experience']),
                ),
              ],
              if (interviewData['support_services_experience'] != null && interviewData['support_services_experience'].isNotEmpty) ...[
                const Text('Support Services Experience:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['support_services_experience']),
                ),
              ],
              if (interviewData['facilities_experience'] != null && interviewData['facilities_experience'].isNotEmpty) ...[
                const Text('Facilities Experience:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['facilities_experience']),
                ),
              ],
              if (interviewData['overall_improvements'] != null && interviewData['overall_improvements'].isNotEmpty) ...[
                const Text('Suggested Improvements:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['overall_improvements']),
                ),
              ],
              if (interviewData['future_plans'] != null && interviewData['future_plans'].isNotEmpty) ...[
                const Text('Future Plans:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['future_plans']),
                ),
              ],
              if (interviewData['contact_info'] != null && interviewData['contact_info'].isNotEmpty) ...[
                _buildDetailRow('Contact Info', interviewData['contact_info']),
              ],
              if (interviewData['admin_notes'] != null && interviewData['admin_notes'].isNotEmpty) ...[
                const Text('Admin Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(interviewData['admin_notes']),
                ),
              ],
              _buildDetailRow('Created', interviewData['created_at']?.toString().split('T')[0]),
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

  void _showUpdateDialog(Map<String, dynamic> interviewData) {
    String selectedStatus = interviewData['status'];
    final notesController = TextEditingController(text: interviewData['admin_notes']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Interview Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedStatus,
              items: const [
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) => selectedStatus = value!,
              decoration: const InputDecoration(labelText: 'Status'),
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
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _updateInterviewStatus(interviewData['id'], selectedStatus, notesController.text);
              Navigator.of(context).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, Color color, bool isType) {
    final isSelected = isType ? _filterType == value : _filterStatus == value;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (isType) {
            _filterType = selected ? value : 'all';
          } else {
            _filterStatus = selected ? value : 'all';
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      elevation: isSelected ? 4 : 0,
      shadowColor: color.withOpacity(0.3),
    );
  }

  List<Map<String, dynamic>> get _filteredInterviews {
    List<Map<String, dynamic>> filtered = _interviews;

    if (_filterType != 'all') {
      filtered = filtered.where((i) => i['interview_type'] == _filterType).toList();
    }

    if (_filterStatus != 'all') {
      filtered = filtered.where((i) => i['status'] == _filterStatus).toList();
    }

    // Apply search filter across multiple fields
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      filtered = filtered.where((i) {
        final studentNumber = i['student_number']?.toString().toLowerCase() ?? '';
        final studentName = i['student_name']?.toString().toLowerCase() ?? '';
        final interviewType = i['interview_type']?.toString().toLowerCase() ?? '';
        final reasonForLeaving = i['reason_for_leaving']?.toString().toLowerCase() ?? '';
        final status = i['status']?.toString().toLowerCase() ?? '';

        return studentNumber.contains(searchTerm) ||
               studentName.contains(searchTerm) ||
               interviewType.contains(searchTerm) ||
               reasonForLeaving.contains(searchTerm) ||
               status.contains(searchTerm);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Exit Interviews',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchInterviews,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter section
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
                        hintText: 'Search by student name, number, type, reason, or status...',
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
                      'Filter by Type & Status',
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
                      _buildFilterChip('All Types', 'all', Colors.grey.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Graduating', 'graduating', Colors.blue.shade600, true),
                      const SizedBox(width: 8),
                      _buildFilterChip('Transferring', 'transferring', Colors.purple.shade600, true),
                      const SizedBox(width: 16),
                      _buildFilterChip('All Status', 'all', Colors.grey.shade600, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Scheduled', 'scheduled', Colors.orange.shade600, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Completed', 'completed', Colors.green.shade600, false),
                      const SizedBox(width: 8),
                      _buildFilterChip('Cancelled', 'cancelled', Colors.red.shade600, false),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Interviews list
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
                              onPressed: _fetchInterviews,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredInterviews.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.exit_to_app, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No exit interviews found'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredInterviews.length,
                            itemBuilder: (context, index) {
                              final interviewData = _filteredInterviews[index];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.grey.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.shade200.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  color: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      interviewData['student_name'] ?? 'Unknown Student',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Student #: ${interviewData['student_number'] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Type: ${interviewData['interview_type'] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Date: ${interviewData['interview_date']?.toString().split('T')[0] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(Icons.info, size: 16, color: Colors.grey.shade600),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Status: ${interviewData['status'] ?? 'N/A'}',
                                              style: TextStyle(color: Colors.grey.shade700),
                                            ),
                                          ],
                                        ),
                                        if (interviewData['satisfaction_rating'] != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.star, size: 16, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Rating: ${interviewData['satisfaction_rating']}/5',
                                                style: TextStyle(color: Colors.grey.shade700),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          alignment: WrapAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(interviewData['status']),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getStatusColor(interviewData['status']).withOpacity(0.3),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                interviewData['status'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: _getTypeColor(interviewData['interview_type']),
                                                borderRadius: BorderRadius.circular(8),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: _getTypeColor(interviewData['interview_type']).withOpacity(0.3),
                                                    blurRadius: 2,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Text(
                                                interviewData['interview_type'] ?? 'Unknown',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: IconButton(
                                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                            onPressed: () => _showUpdateDialog(interviewData),
                                            tooltip: 'Update Status',
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () => _showInterviewDetails(interviewData),
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
      case 'scheduled':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'graduating':
        return Colors.blue;
      case 'transferring':
        return Colors.purple;
      default:
        return Colors.grey;
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
