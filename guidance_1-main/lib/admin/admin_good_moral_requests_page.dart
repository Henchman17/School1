import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminGoodMoralRequestsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminGoodMoralRequestsPage({super.key, this.userData});

  @override
  State<AdminGoodMoralRequestsPage> createState() => _AdminGoodMoralRequestsPageState();
}

class _AdminGoodMoralRequestsPageState extends State<AdminGoodMoralRequestsPage> with SingleTickerProviderStateMixin {
  List<dynamic> goodMoralRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  String _searchQuery = '';
  late TabController _tabController;

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchGoodMoralRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchGoodMoralRequests() async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/good-moral-requests?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            goodMoralRequests = data['requests'] ?? [];
            isLoading = false;
            errorMessage = '';
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load good moral requests';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> approveRequest(int requestId) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/good-moral-requests/$requestId/approve?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> rejectRequest(int requestId, String reason) async {
    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/good-moral-requests/$requestId/reject?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'admin_notes': reason}),
      );

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to reject request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> downloadDocument(String documentPath, int requestId) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading document for request #$requestId...'),
          backgroundColor: Colors.blue,
        ),
      );
      // TODO: Implement actual download functionality
      // You may need to use packages like url_launcher or dio for downloading
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRequestDetails(dynamic request) {
    final requestId = request['id'];
    final firstName = request['first_name'] ?? '';
    final lastName = request['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();
    final email = request['email'] ?? 'N/A';
    final course = request['course'] ?? 'N/A';
    final schoolYear = request['school_year'] ?? 'N/A';
    final purpose = request['purpose'] ?? 'N/A';
    final address = request['address'] ?? 'N/A';
    final status = request['status'] ?? 'pending';
    final createdAt = request['created_at'] ?? '';
    final reviewedAt = request['reviewed_at'] ?? 'N/A';
    final adminNotes = request['admin_notes'] ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.verified_user, color: Colors.blue),
            const SizedBox(width: 8),
            Text('Request #$requestId Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Student Name', studentName),
              _buildDetailRow('Email', email),
              _buildDetailRow('Course', course),
              _buildDetailRow('School Year', schoolYear),
              _buildDetailRow('Address', address),
              _buildDetailRow('Purpose', purpose),
              _buildDetailRow('Status', status.toUpperCase()),
              _buildDetailRow('Submitted At', createdAt),
              if (status != 'pending') ...[
                _buildDetailRow('Reviewed At', reviewedAt),
                if (status == 'rejected')
                  _buildDetailRow('Admin Notes', adminNotes),
              ],
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildRequestCard(dynamic request, bool isApproved) {
    final requestId = request['id'];
    final firstName = request['first_name'] ?? '';
    final lastName = request['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();
    final studentId = request['user_student_id'] ?? 'N/A';
    final purpose = request['purpose'] ?? 'N/A';
    final status = request['status'] ?? 'pending';
    final createdAt = request['created_at'] ?? '';
    final documentPath = request['document_path'];

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'approved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [Colors.white, Colors.blue.shade50.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user, color: Colors.blue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Request #$requestId',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: statusColor,
                    elevation: 2,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Student: $studentName',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.badge, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Student ID: $studentId',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Purpose: $purpose',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Submitted: $createdAt',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isApproved)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRequestDetails(request),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: documentPath != null 
                        ? () => downloadDocument(documentPath, requestId)
                        : null,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showRequestDetails(request),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.blue),
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final reasonController = TextEditingController();
                        final reason = await showDialog<String>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Reject Request'),
                            content: TextField(
                              controller: reasonController,
                              decoration: const InputDecoration(
                                hintText: 'Reason for rejection',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(reasonController.text),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                child: const Text('Reject'),
                              ),
                            ],
                          ),
                        );
                        if (reason != null && reason.isNotEmpty) {
                          rejectRequest(requestId, reason);
                        }
                      },
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        foregroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => approveRequest(requestId),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<dynamic> requests, bool isApproved) {
    final filteredRequests = requests.where((request) {
      final firstName = request['first_name']?.toString().toLowerCase() ?? '';
      final lastName = request['last_name']?.toString().toLowerCase() ?? '';
      final studentName = '$firstName $lastName'.trim();
      final studentId = request['user_student_id']?.toString().toLowerCase() ?? '';
      return studentName.contains(_searchQuery.toLowerCase()) || 
             studentId.contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isApproved ? Icons.check_circle_outline : Icons.pending_actions,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isApproved 
                ? 'No approved requests found' 
                : 'No pending requests found',
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredRequests.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildRequestCard(filteredRequests[index], isApproved),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Good Moral Requests'),
          backgroundColor: const Color(0xFF1E88E5),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading requests...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Good Moral Requests'),
          backgroundColor: const Color(0xFF1E88E5),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchGoodMoralRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final pendingRequests = goodMoralRequests.where((r) => r['status'] == 'pending').toList();
    final approvedRequests = goodMoralRequests.where((r) => r['status'] == 'approved').toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Good Moral Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchGoodMoralRequests,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.pending_actions),
                  const SizedBox(width: 8),
                  Text('For Approval (${pendingRequests.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle),
                  const SizedBox(width: 8),
                  Text('Approved (${approvedRequests.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
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
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by student name or ID...',
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTabContent(pendingRequests, false),
                _buildTabContent(approvedRequests, true),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
