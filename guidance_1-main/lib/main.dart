import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:guidance_1/providers/app_state_provider.dart';
import 'package:guidance_1/providers/auth_provider.dart';
import 'package:guidance_1/providers/form_settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart';
import 'navigation_rail_example.dart';
import 'shared_enums.dart';
import 'admin/admin_dashboard.dart';
import 'admin/admin_users_page.dart';
import 'admin/admin_appointments_page.dart';
import 'admin/admin_analytics_page.dart';
import 'admin/admin_discipline_page.dart';
import 'counselor/counselor_dashboard.dart';
import 'counselor/counselor_students_page.dart';
import 'counselor/counselor_appointments_page.dart';
import 'counselor/counselor_sessions_page.dart';
import 'student/guidance_scheduling_page.dart';
import 'student/answerable_forms.dart';
import 'student/good_moral_request.dart';
import 'head/head_dashboard.dart';

// AutoRefreshService - Singleton for global state management
class AutoRefreshService {
  static final AutoRefreshService _instance = AutoRefreshService._internal();

  factory AutoRefreshService() {
    return _instance;
  }

  AutoRefreshService._internal();

  Timer? _timer;
  FormSettingsProvider? _formSettingsProvider;

  void setFormSettingsProvider(FormSettingsProvider provider) {
    _formSettingsProvider = provider;
    initialize();
  }

  void initialize() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) => _refresh());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _refresh() async {
    if (_formSettingsProvider == null) return;

    try {
      final response = await http.get(
        Uri.parse('${FormSettingsProvider.apiBaseUrl}/api/admin/form-settings?admin_id=1'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final settings = data['settings'] as Map<String, dynamic>? ?? {};

        bool toBool(dynamic v, bool defaultVal) {
          if (v is bool) return v;
          if (v is String) {
            final lower = v.toLowerCase();
            if (lower == 'true') return true;
            if (lower == 'false') return false;
          }
          if (v is num) return v != 0;
          return defaultVal;
        }

        final newSettings = <String, bool>{
          'scrf_enabled': toBool(settings['scrf_enabled'], true),
          'routine_interview_enabled': toBool(settings['routine_interview_enabled'], true),
          'good_moral_request_enabled': toBool(settings['good_moral_request_enabled'], true),
          'guidance_scheduling_enabled': toBool(settings['guidance_scheduling_enabled'], true),
          'dass21_enabled': toBool(settings['dass21_enabled'], false),
        };

        // Check if settings have changed
        if (!mapEquals(_formSettingsProvider!.formSettings, newSettings)) {
          _formSettingsProvider!.updateSettingsSilently(newSettings);
          _formSettingsProvider!.notifyListeners();
        }
      }
    } catch (e) {
      // Handle error silently or log it
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    });
  }

  runApp(const MainApp());
  
  // Initialize AutoRefreshService globally
  AutoRefreshService().initialize();
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final formSettingsProvider = Provider.of<FormSettingsProvider>(context, listen: false);
      AutoRefreshService().setFormSettingsProvider(formSettingsProvider);
    });
  }

  @override
  void dispose() {
    AutoRefreshService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
        ChangeNotifierProvider(create: (_) => FormSettingsProvider()),
      ],
      child: MaterialApp(
        title: 'PLSP Guidance',
        theme: ThemeData(
          primarySwatch: Colors.green,
          textTheme: const TextTheme(
            headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            bodyLarge: TextStyle(fontSize: 14),
            bodyMedium: TextStyle(fontSize: 12),
            bodySmall: TextStyle(fontSize: 10),
            labelLarge: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            labelMedium: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            labelSmall: TextStyle(fontSize: 8, fontWeight: FontWeight.w500),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => const NavigationRailExample(),
          '/admin-dashboard': (context) => const AdminDashboardPage(),
          '/admin-users': (context) => const AdminUsersPage(),
          '/admin-appointments': (context) => const AdminAppointmentsPage(),
          '/admin-analytics': (context) => const AdminAnalyticsPage(),
          '/admin-discipline': (context) => const AdminDisciplinePage(),
          '/counselor-dashboard': (context) => const CounselorDashboardPage(),
          '/counselor-students': (context) => const CounselorStudentsPage(),
          '/counselor-appointments': (context) => const CounselorAppointmentsPage(),
          '/counselor-sessions': (context) => const CounselorSessionsPage(),
          '/head-dashboard': (context) => const HeadDashboardPage(),
          '/guidance-scheduling': (context) => const GuidanceSchedulingPage(status: SchedulingStatus.none),
          '/answerable-forms': (context) => const AnswerableForms(),
          '/good-moral-request': (context) => const GoodMoralRequest(),
        },
        home: const LoginPage(),
      ),
    );
  }
}