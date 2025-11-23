import 'package:flutter/material.dart';
import '../config.dart';

class AdminFormsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminFormsPage({super.key, this.userData});

  @override
  State<AdminFormsPage> createState() => _AdminFormsPageState();
}

class _AdminFormsPageState extends State<AdminFormsPage> {
  List<Map<String, dynamic>> _forms = [];
  bool _isLoading = true;
  String _errorMessage = '';



  @override
  void initState() {
    super.initState();
    _fetchForms();
  }

  Future<void> _fetchForms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await AppConfig.supabase
          .from('forms')
          .select('*, students(first_name, last_name)')
          .neq('form_type', 'good_moral_request')
          .order('submitted_at', ascending: false);

      setState(() {
        _forms = List<Map<String, dynamic>>.from(data.map((form) {
          final student = form['students'] as Map<String, dynamic>?;
          return {
            ...form,
            'student_name': student != null ? '${student['first_name']} ${student['last_name']}' : 'Unknown Student',
          };
        }));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _showFormDetails(Map<String, dynamic> formData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Form Details: ${_getFormDisplayName(formData['form_type'])}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Form Type', formData['form_type']),
              _buildDetailRow('Student', formData['student_name']),
              _buildDetailRow('Student Number', formData['student_number']),
              _buildDetailRow('Status', formData['status']),
              _buildDetailRow('Submitted', formData['submitted_at']?.toString().split('T')[0]),
              if (formData['reviewed_at'] != null)
                _buildDetailRow('Reviewed', formData['reviewed_at']?.toString().split('T')[0]),
              if (formData['reviewer_name'] != null)
                _buildDetailRow('Reviewed By', formData['reviewer_name']),
              if (formData['admin_notes'] != null && formData['admin_notes'].isNotEmpty)
                _buildDetailRow('Admin Notes', formData['admin_notes']),
              // Show additional details for good moral requests
              if (formData['form_type'] == 'good_moral_request') ...[
                if (formData['program_enrolled'] != null)
                  _buildDetailRow('Course', formData['program_enrolled']),
                if (formData['purpose'] != null)
                  _buildDetailRow('Purpose', formData['purpose']),
              ],
            ],
          ),
        ),
        actions: [
          // Show approve/reject buttons only for pending good moral requests
          if (formData['form_type'] == 'good_moral_request' && formData['status'] == 'pending') ...[
            TextButton(
              onPressed: () => _rejectGoodMoralRequest(formData),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () => _approveGoodMoralRequest(formData),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Approve'),
            ),
          ],
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getFormDisplayName(String? formType) {
    switch (formType) {
      case 'scrf':
        return 'Student Cumulative Record Form';
      case 'routine_interview':
        return 'Routine Interview';
      case 'good_moral_request':
        return 'Good Moral Request';
      default:
        return 'Unknown Form';
    }
  }

  Future<void> _approveGoodMoralRequest(Map<String, dynamic> formData) async {
    final formId = formData['id'];

    try {
      await AppConfig.supabase
          .from('forms')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', formId);

      Navigator.of(context).pop(); // Close the dialog
      _fetchForms(); // Refresh the forms list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Good Moral Request approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Future<void> _rejectGoodMoralRequest(Map<String, dynamic> formData) async {
    final formId = formData['id'];

    try {
      await AppConfig.supabase
          .from('forms')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', formId);

      Navigator.of(context).pop(); // Close the dialog
      _fetchForms(); // Refresh the forms list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Good Moral Request rejected successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: $e')),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Forms Management',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchForms,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Forms list
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
                              onPressed: _fetchForms,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _forms.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No forms found'),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _forms.length,
                            itemBuilder: (context, index) {
                              final formData = _forms[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    _getFormDisplayName(formData['form_type']),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Student: ${formData['student_name'] ?? 'N/A'}'),
                                      Text('Type: ${formData['form_type'] ?? 'N/A'}'),
                                      Text('Status: ${formData['status'] ?? 'N/A'}'),
                                      Text('Submitted: ${formData['submitted_at']?.toString().split('T')[0] ?? 'N/A'}'),
                                    ],
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(formData['status']),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      formData['status'] ?? 'Unknown',
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                  onTap: () => _showFormDetails(formData),
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
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'under_review':
        return Colors.blue;
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
