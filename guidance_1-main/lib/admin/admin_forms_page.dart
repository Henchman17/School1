import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../providers/form_settings_provider.dart';
import 'package:provider/provider.dart';
import '../providers/form_settings_provider.dart';
import 'package:provider/provider.dart';
import '../providers/form_settings_provider.dart';

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

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _fetchForms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FormSettingsProvider>(context, listen: false).fetchFormSettings();
    });
  }

  Future<void> _fetchForms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/forms?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _forms = List<Map<String, dynamic>>.from(data['forms']).where((form) => form['form_type'] == 'scrf' || form['form_type'] == 'routine_interview').toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load forms';
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
    final formId = formData['form_id'];
    final adminId = widget.userData?['id'] ?? 0;

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/good-moral-requests/$formId/approve?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        _fetchForms(); // Refresh the forms list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Good Moral Request approved successfully')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to approve request');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: $e')),
      );
    }
  }

  Future<void> _rejectGoodMoralRequest(Map<String, dynamic> formData) async {
    final formId = formData['form_id'];
    final adminId = widget.userData?['id'] ?? 0;

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/good-moral-requests/$formId/reject?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        _fetchForms(); // Refresh the forms list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Good Moral Request rejected successfully')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to reject request');
      }
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
            onPressed: () {
              _fetchForms();
              Provider.of<FormSettingsProvider>(context, listen: false).fetchFormSettings();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Form Settings Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Form Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Consumer<FormSettingsProvider>(
                  builder: (context, formSettingsProvider, child) {
                    return formSettingsProvider.isLoading
                        ? const CircularProgressIndicator()
                        : Wrap(
                            spacing: 16,
                            runSpacing: 8,
                            children: [
                              _buildSettingToggle('SCRF Enabled', 'scrf_enabled'),
                              _buildSettingToggle('Routine Interview Enabled', 'routine_interview_enabled'),
                              _buildSettingToggle('Good Moral Request Enabled', 'good_moral_request_enabled'),
                              _buildSettingToggle('Guidance Scheduling Enabled', 'guidance_scheduling_enabled'),
                              _buildSettingToggle('DASS-21 Enabled', 'dass21_enabled'),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
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
                                      Row(
                                        children: [
                                          const Text('Active: '),
                                          Switch(
                                            value: formData['active'] ?? true,
                                            onChanged: (value) async {
                                              await _toggleFormActiveStatus(formData, value);
                                            },
                                          ),
                                        ],
                                      ),
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

  Widget _buildSettingToggle(String label, String settingKey) {
    return Consumer<FormSettingsProvider>(
      builder: (context, formSettingsProvider, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label),
            const SizedBox(width: 8),
            Switch(
              value: formSettingsProvider.formSettings[settingKey] ?? true,
              onChanged: (value) {
                final updatedSettings = Map<String, bool>.from(formSettingsProvider.formSettings);
                updatedSettings[settingKey] = value;
                formSettingsProvider.updateFormSettings(updatedSettings);
              },
            ),
          ],
        );
      },
    );
  }



  Future<void> _toggleFormActiveStatus(Map<String, dynamic> formData, bool isActive) async {
    final formType = formData['form_type'];
    final formId = formData['form_id'];
    final adminId = widget.userData?['id'] ?? 0;

    try {
      final endpoint = isActive ? 'activate' : 'deactivate';
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/forms/$formType/$formId/$endpoint?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          formData['active'] = isActive;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form ${isActive ? 'activated' : 'deactivated'} successfully')),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Failed to toggle form status');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling form status: $e')),
      );
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
