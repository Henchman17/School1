import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HeadGoodMoralPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const HeadGoodMoralPage({super.key, this.userData});

  @override
  State<HeadGoodMoralPage> createState() => _HeadGoodMoralPageState();
}

class _HeadGoodMoralPageState extends State<HeadGoodMoralPage> {
  List<dynamic> goodMoralRequests = [];
  bool isLoading = true;
  String errorMessage = '';
  String _searchQuery = '';

  static const String apiBaseUrl = 'http://10.0.2.2:8080';

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
      final headId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/head/good-moral-requests?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          goodMoralRequests = data['requests'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load good moral requests';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> approveRequest(int requestId) async {
    try {
      final headId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/head/good-moral-requests/$requestId/approve?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        final certificatePath = body is Map && body['certificate_path'] != null ? body['certificate_path'] : null;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(certificatePath != null
                ? 'Request approved. Certificate: $certificatePath'
                : 'Request approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final error = (body is Map && body['error'] != null) ? body['error'] : 'Failed to approve request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
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

  Future<void> rejectRequest(int requestId) async {
    try {
      final headId = widget.userData?['id'] ?? 0;
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/head/good-moral-requests/$requestId/reject?head_id=$headId'),
        headers: {'Content-Type': 'application/json'},
      );
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        fetchGoodMoralRequests();
        final message = (body is Map && body['message'] != null) ? body['message'] : 'Request rejected';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final error = (body is Map && body['error'] != null) ? body['error'] : 'Failed to reject request';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
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

  Widget _buildRequestCard(dynamic request) {
    final requestId = request['id'];
    final studentName = request['student_name'] ?? 'Unknown';
    final studentNumber = request['student_number'] ?? 'N/A';
    final course = request['course'] ?? 'N/A';
    final yearLevel = request['school_year'] ?? 'N/A';
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
              colors: [Colors.white, Colors.green.shade50.withOpacity(0.05)],
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
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.verified_user, color: Colors.green, size: 20),
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
                    'Student Number: $studentNumber',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.school, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Course: $course, Year: $yearLevel',
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
                      onPressed: () => rejectRequest(requestId),
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
          backgroundColor: const Color(0xFF4CAF50),
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
          backgroundColor: const Color(0xFF4CAF50),
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
      final studentName = request['student_name']?.toString().toLowerCase() ?? '';
      final studentNumber = request['student_number']?.toString().toLowerCase() ?? '';
      return studentName.contains(_searchQuery.toLowerCase()) || studentNumber.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Good Moral Requests',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF4CAF50),
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
                colors: [Colors.green.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.shade100.withOpacity(0.3),
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
                  hintText: 'Search by student name or number...',
                  prefixIcon: const Icon(Icons.search, color: Colors.green),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green.shade200, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.green, width: 2),
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
