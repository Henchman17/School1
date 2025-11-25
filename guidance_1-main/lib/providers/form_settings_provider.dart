import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FormSettingsProvider with ChangeNotifier {
  Map<String, bool> _formSettings = {
    'scrf_enabled': true,
    'routine_interview_enabled': true,
    'good_moral_request_enabled': true,
    'guidance_scheduling_enabled': true,
    'dass21_enabled': true,
  };

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, bool> get formSettings => _formSettings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  static const String apiBaseUrl = 'http://10.0.2.2:8080';

  Future<void> fetchFormSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/form-settings?admin_id=1'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['settings'] as Map<String, dynamic>? ?? {};
        _formSettings = {
          'scrf_enabled': settings['scrf_enabled'] ?? true,
          'routine_interview_enabled': settings['routine_interview_enabled'] ?? true,
          'good_moral_request_enabled': settings['good_moral_request_enabled'] ?? true,
          'guidance_scheduling_enabled': settings['guidance_scheduling_enabled'] ?? true,
          'dass21_enabled': settings['dass21_enabled'] ?? true,
        };
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to fetch form settings';
      }
    } catch (e) {
      _errorMessage = 'Error fetching form settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateFormSettings(Map<String, bool> newSettings) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$apiBaseUrl/api/admin/form-settings?admin_id=1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'settings': newSettings}),
      );

      if (response.statusCode == 200) {
        _formSettings = Map<String, bool>.from(newSettings);
        _errorMessage = null;
      } else {
        _errorMessage = 'Failed to update form settings';
      }
    } catch (e) {
      _errorMessage = 'Error updating form settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void updateSettingsSilently(Map<String, bool> newSettings) {
    _formSettings = Map<String, bool>.from(newSettings);
  }
}
