import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';
import 'auth_test_page.dart';
import 'user_migration_script.dart';
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
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://tajmifkqcttcrhmmiobe.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRham1pZmtxY3R0Y3JobW1pb2JlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MDQ2NjksImV4cCI6MjA3NzI4MDY2OX0.9Aaewy6FVRJVtZCxQA4efeXo5oTGRO2eLNOUOwzz4Do', // Replace with your actual anon key
  );

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1920, 1080),
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
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/auth-test': (context) => const AuthTestPage(),
        '/user-migration': (context) => const UserMigrationPage(),
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
        '/guidance-scheduling': (context) => const GuidanceSchedulingPage(status: SchedulingStatus.none),
        '/answerable-forms': (context) => const AnswerableForms(),
        '/good-moral-request': (context) => const GoodMoralRequest(),
      },
      home: const LoginPage(),
    );
  }
}