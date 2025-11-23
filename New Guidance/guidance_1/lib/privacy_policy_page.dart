import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Privacy Policy & Data Protection',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'Data Protection Act of 2012 (Republic Act 10173)',
              'This application complies with the Philippine Data Protection Act '
              'which protects individual personal information in information and '
              'communications systems both in the government and the private sector.',
            ),
            _buildSection(
              'Data Collection',
              'We collect and process your personal information for:',
              bulletPoints: [
                'Student counseling services',
                'Academic support and guidance',
                'Communication purposes',
                'Service improvement',
              ],
            ),
            _buildSection(
              'Your Rights',
              'Under the Data Privacy Act, you have the right to:',
              bulletPoints: [
                'Be informed about how your data is processed',
                'Access your personal information',
                'Object to the processing of your information',
                'Rectify inaccurate or incorrect information',
                'Request for data portability',
                'Remove or withdraw your information',
              ],
            ),
            _buildSection(
              'Data Security',
              'We implement appropriate security measures to protect your personal '
              'information from unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              'Consent',
              'By using this application, you consent to the collection, use, and '
              'processing of your personal information as described in this privacy policy.',
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I Understand'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, {List<String>? bulletPoints}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(content),
        if (bulletPoints != null) ...[
          const SizedBox(height: 8),
          ...bulletPoints.map((point) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(point)),
                  ],
                ),
              )),
        ],
      ],
    );
  }
}
