import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class AdminAnalyticsPage extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const AdminAnalyticsPage({super.key, this.userData});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  Map<String, dynamic>? analyticsData;
  bool isLoading = true;
  String errorMessage = '';
  String selectedView = 'overview'; // 'overview', 'appointments', 'users', 'purposes'

  static const String apiBaseUrl = 'http://localhost:8080';

  @override
  void initState() {
    super.initState();
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final adminId = widget.userData?['id'] ?? 0;
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/admin/analytics?admin_id=$adminId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          analyticsData = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load analytics';
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

  Widget buildSummaryCards() {
    final dailySummary = analyticsData?['daily_appointment_summary'] as List<dynamic>? ?? [];
    final totalAppointments = dailySummary.isNotEmpty ? dailySummary.first['total_appointments'] ?? 0 : 0;
    final completedAppointments = dailySummary.isNotEmpty ? dailySummary.first['completed'] ?? 0 : 0;
    final scheduledAppointments = dailySummary.isNotEmpty ? dailySummary.first['scheduled'] ?? 0 : 0;

    final userRegistrations = analyticsData?['monthly_user_registrations'] as List<dynamic>? ?? [];
    final totalUsers = userRegistrations.isNotEmpty ? userRegistrations.first['total_registrations'] ?? 0 : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.dashboard_rounded, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              Text(
                'Key Metrics Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade800,
                  shadows: [
                    Shadow(
                      color: Colors.blue.shade200.withOpacity(0.5),
                      offset: const Offset(1, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildAnimatedMetricCard(
                  'Total Appointments',
                  totalAppointments.toString(),
                  Icons.calendar_month_rounded,
                  [Colors.blue.shade400, Colors.blue.shade600, Colors.blue.shade800],
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnimatedMetricCard(
                  'Completed',
                  completedAppointments.toString(),
                  Icons.check_circle_rounded,
                  [Colors.green.shade400, Colors.green.shade600, Colors.green.shade800],
                  Icons.thumb_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnimatedMetricCard(
                  'Scheduled',
                  scheduledAppointments.toString(),
                  Icons.schedule_rounded,
                  [Colors.orange.shade400, Colors.orange.shade600, Colors.orange.shade800],
                  Icons.access_time,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnimatedMetricCard(
                  'Total Users',
                  totalUsers.toString(),
                  Icons.people_alt_rounded,
                  [Colors.purple.shade400, Colors.purple.shade600, Colors.purple.shade800],
                  Icons.group_add,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedMetricCard(String title, String value, IconData icon, List<Color> gradientColors, IconData trendIcon) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: gradientColors.first.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 0),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.white),
                  const SizedBox(width: 8),
                  Icon(trendIcon, size: 20, color: Colors.white.withOpacity(0.8)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildAppointmentChart() {
    final data = analyticsData?['daily_appointment_summary'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.blue[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Daily Appointment Trends',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.map((e) => double.tryParse(e['total_appointments']?.toString() ?? '0') ?? 0).reduce((a, b) => a > b ? a : b) + 5,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${rod.toY.round()}',
                          const TextStyle(color: Colors.white),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < data.length) {
                            final day = data[value.toInt()]['appointment_day']?.toString() ?? '';
                            return Text(day.length > 3 ? day.substring(0, 3) : day,
                                style: const TextStyle(fontSize: 12));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((entry) {
                    final item = entry.value;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: double.tryParse(item['total_appointments']?.toString() ?? '0') ?? 0,
                          color: Colors.blue,
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPurposePieChart() {
    final data = analyticsData?['appointment_purpose_distribution'] as List<dynamic>? ?? [];
    if (data.isEmpty) return const SizedBox.shrink();

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.red, Colors.purple, Colors.teal];

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.green[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  'Appointment Purposes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sections: data.asMap().entries.map((entry) {
                    final item = entry.value;
                    final percentage = item['percentage'] is num ? (item['percentage'] as num).toDouble() : double.tryParse(item['percentage']?.toString() ?? '0') ?? 0;
                    return PieChartSectionData(
                      value: percentage,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: colors[entry.key % colors.length],
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: data.asMap().entries.map((entry) {
                final item = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: colors[entry.key % colors.length],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item['purpose_category']?.toString() ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDataTable(String title, List<dynamic>? data, List<String> columns) {
    if (data == null || data.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(16),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.table_chart, color: Colors.grey, size: 48),
              const SizedBox(height: 16),
              Text('$title: No data available', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.table_chart, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Text(title,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[600])),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
                dataRowColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return Colors.blue[100];
                  }
                  return null;
                }),
                columns: columns.map((col) => DataColumn(
                  label: Text(col.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                )).toList(),
                rows: data.map((row) {
                  return DataRow(
                    cells: columns.map((col) => DataCell(Text(row[col]?.toString() ?? ''))).toList(),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF1E88E5),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading analytics data...'),
            ],
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text(
            'Analytics Dashboard',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
                onPressed: fetchAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [const Color.fromARGB(255, 5, 5, 5), const Color.fromARGB(255, 0, 0, 0), const Color.fromARGB(255, 0, 0, 0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            'Analytics Dashboard',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        backgroundColor: const Color(0xFF1E88E5),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Summary Cards
              buildSummaryCards(),

              // Charts Section
              buildAppointmentChart(),
              buildPurposePieChart(),

              // Data Tables
              buildDataTable(
                'Daily Appointment Summary',
                analyticsData?['daily_appointment_summary'],
                ['appointment_day', 'total_appointments', 'scheduled', 'completed', 'cancelled'],
              ),
              buildDataTable(
                'Monthly User Registrations',
                analyticsData?['monthly_user_registrations'],
                ['registration_month', 'total_registrations', 'student_registrations', 'counselor_registrations', 'admin_registrations'],
              ),
              buildDataTable(
                'Appointment Purpose Distribution',
                analyticsData?['appointment_purpose_distribution'],
                ['purpose_category', 'appointment_count', 'percentage'],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
