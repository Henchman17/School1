import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Config {
  static const String backendUrl = 'http://10.0.2.2:8080';
}

class PsychExxam extends StatefulWidget {
  final int userId;
  final String studentId;
  final String fullName;
  final String program;
  final String major;

  const PsychExxam({
    Key? key,
    required this.userId,
    required this.studentId,
    required this.fullName,
    required this.program,
    required this.major,
  }) : super(key: key);

  @override
  _PsychExxamState createState() => _PsychExxamState();
}

class _PsychExxamState extends State<PsychExxam> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSubmitted = false;

  Map<String, int?> _responses = {};
  Map<String, dynamic>? _existingAssessment;

  final List<Map<String, dynamic>> _questions = [
    {'key': 'q1', 'text': 'I found it hard to wind down'},
    {'key': 'q2', 'text': 'I was aware of dryness of my mouth'},
    {'key': 'q3', 'text': 'I couldn\'t seem to experience any positive feeling at all'},
    {'key': 'q4', 'text': 'I experienced breathing difficulty'},
    {'key': 'q5', 'text': 'I found it difficult to work up the initiative to do things'},
    {'key': 'q6', 'text': 'I tended to over-react to situations'},
    {'key': 'q7', 'text': 'I experienced trembling'},
    {'key': 'q8', 'text': 'I felt that I was using a lot of nervous energy'},
    {'key': 'q9', 'text': 'I was worried about situations in which I might panic'},
    {'key': 'q10', 'text': 'I felt that I had nothing to look forward to'},
    {'key': 'q11', 'text': 'I found myself getting agitated'},
    {'key': 'q12', 'text': 'I found it difficult to relax'},
    {'key': 'q13', 'text': 'I felt down-hearted and blue'},
    {'key': 'q14', 'text': 'I was intolerant of delays'},
    {'key': 'q15', 'text': 'I felt I was close to panic'},
    {'key': 'q16', 'text': 'I was unable to become enthusiastic about anything'},
    {'key': 'q17', 'text': 'I felt I wasn\'t worth much as a person'},
    {'key': 'q18', 'text': 'I felt that I was rather touchy'},
    {'key': 'q19', 'text': 'I was aware of the action of my heart'},
    {'key': 'q20', 'text': 'I felt scared without any good reason'},
    {'key': 'q21', 'text': 'I felt that life was meaningless'},
  ];

  final List<String> _ratingDescriptions = [
    'Did not apply to me at all',
    'Applied to some degree, or some of the time',
    'Applied to a considerable degree, or a good part of the time',
    'Applied very much, or most of the time',
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingAssessment();
  }

  Future<void> _loadExistingAssessment() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${Config.backendUrl}/student/dass21?user_id=${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['assessment'] != null) {
          _existingAssessment = data['assessment'];
          _isSubmitted = _existingAssessment!['status'] == 'completed';

          for (int i = 1; i <= 21; i++) {
            final key = 'q$i';
            if (_existingAssessment![key] != null) {
              _responses[key] = _existingAssessment![key];
            }
          }

          setState(() {});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load assessment: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _submitAssessment() async {
    if (!_formKey.currentState!.validate()) return;

    for (var q in _questions) {
      if (_responses[q['key']] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please answer all questions.")),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final body = {
        "user_id": widget.userId,
        "student_id": widget.studentId,
        "full_name": widget.fullName,
        "program": widget.program,
        "major": widget.major,
        "status": "completed",
        ..._responses,
      };

      final res = await http.post(
        Uri.parse('${Config.backendUrl}/student/dass21'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        setState(() => _isSubmitted = true);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Assessment submitted!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveDraft() async {
    setState(() => _isLoading = true);

    try {
      final body = {
        "user_id": widget.userId,
        "student_id": widget.studentId,
        "full_name": widget.fullName,
        "program": widget.program,
        "major": widget.major,
        "status": "draft",
        ..._responses,
      };

      final res = await http.post(
        Uri.parse('${Config.backendUrl}/student/dass21'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Draft saved!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isLoading = false);
  }

  Widget _buildQuestionCard(Map<String, dynamic> q, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${index + 1}. ${q['text']}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            SizedBox(height: 12),
            Column(
              children: List.generate(4, (ratingIndex) {
                return RadioListTile<int>(
                  title: Text(_ratingDescriptions[ratingIndex]),
                  value: ratingIndex,
                  groupValue: _responses[q['key']],
                  onChanged: _isSubmitted
                      ? null
                      : (value) {
                          setState(() {
                            _responses[q['key']] = value;
                          });
                        },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _existingAssessment == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("DASS-21 Assessment"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ..._questions
                  .asMap()
                  .entries
                  .map((e) => _buildQuestionCard(e.value, e.key)),

              SizedBox(height: 20),

              if (!_isSubmitted)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveDraft,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                        child: Text("Save Draft"),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAssessment,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green),
                        child: Text("Submit"),
                      ),
                    ),
                  ],
                ),

              if (_isSubmitted)
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Assessment Completed",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}