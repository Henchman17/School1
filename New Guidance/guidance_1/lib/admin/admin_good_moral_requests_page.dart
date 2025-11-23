import 'package:flutter/material.dart';
import '../config.dart';

class AdminGoodMoralRequestsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminGoodMoralRequestsPage({super.key, this.userData});

  @override
  State<AdminGoodMoralRequestsPage> createState() => _AdminGoodMoralRequestsPageState();
}

class _AdminGoodMoralRequestsPageState extends State<AdminGoodMoralRequestsPage> {
  List<dynamic> goodMoralRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  String _searchQuery = '';



  @override
  void initState() {
    super.initState();
    fetchGoodMoralRequests();
  }

  Future<void> fetchGoodMoralRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await AppConfig.supabase
          .from('forms')
          .select('*, students(first_name, last_name)')
          .eq('form_type', 'good_moral_request')
          .order('submitted_at', ascending: false);

      setState(() {
        goodMoralRequests = data.map((form) {
          final student = form['students'] as Map<String, dynamic>?;
          return {
            ...form,
            'first_name': student?['first_name'] ?? '',
            'last_name': student?['last_name'] ?? '',
            'student_id': form['student_number'] ?? '',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(int requestId) async {
    try {
      await AppConfig.supabase
          .from('forms')
          .update({
            'status': 'approved',
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      fetchGoodMoralRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
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
      await AppConfig.supabase
          .from('forms')
          .update({
            'status': 'rejected',
            'reviewed_at': DateTime.now().toIso8601String(),
            'admin_notes': reason,
          })
          .eq('id', requestId);

      fetchGoodMoralRequests();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRequestCard(dynamic request) {
    final requestId = request['id'];
    final firstName = request['first_name'] ?? '';
    final lastName = request['last_name'] ?? '';
    final studentName = '$firstName $lastName'.trim().isEmpty ? 'Unknown' : '$firstName $lastName'.trim();
    final studentId = request['student_id'] ?? 'N/A';
    final purpose = request['purpose'] ?? 'N/A';
    final status = request['status'] ?? 'pending';
    final createdAt = request['created_at'] ?? '';

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
              if (status == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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

    final filteredRequests = goodMoralRequests.where((request) {
      final firstName = request['first_name']?.toString().toLowerCase() ?? '';
      final lastName = request['last_name']?.toString().toLowerCase() ?? '';
      final studentName = '$firstName $lastName'.trim();
      final studentId = request['student_id']?.toString().toLowerCase() ?? '';
      return studentName.contains(_searchQuery.toLowerCase()) || studentId.contains(_searchQuery.toLowerCase());
    }).toList();

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
            child: filteredRequests.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_user, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No good moral requests found'),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredRequests.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildRequestCard(filteredRequests[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
