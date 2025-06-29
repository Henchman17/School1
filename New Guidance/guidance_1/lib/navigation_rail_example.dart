import 'package:flutter/material.dart';
import 'guidance_scheduling_page.dart';
import 'answerable_forms.dart';
import 'good_moral_request.dart';

enum SchedulingStatus { none, processing, approved }

class NavigationRailExample extends StatefulWidget {
  const NavigationRailExample({super.key});

  @override
  State<NavigationRailExample> createState() => _NavigationRailExampleState();
}

class _NavigationRailExampleState extends State<NavigationRailExample> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isExtended = false; // For collapsible NavigationRail
  SchedulingStatus _schedulingStatus = SchedulingStatus.none;

  void _navigateToAnswerableFormsPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AnswerableForms(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Top navigation bar
          Container(
            color: const Color.fromARGB(255, 30, 182, 88),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/s_logo.jpg',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "PLSP Guidance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                // Notification icon
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () {
                  },
                  tooltip: 'Notifications',
                ),
                // Collapse/expand button
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) =>
                        RotationTransition(
                          turns: child.key == const ValueKey('close')
                              ? Tween<double>(begin: 0.75, end: 1).animate(animation)
                              : animation,
                          child: child,
                        ),
                    child: _isExtended
                        ? const Icon(Icons.close, key: ValueKey('close'), color: Colors.white)
                        : const Icon(Icons.menu, key: ValueKey('menu'), color: Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      _isExtended = !_isExtended;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(150),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.asset(
                      'assets/images/s_logo.jpg',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // Smooth animated NavigationRail
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => SizeTransition(
                        sizeFactor: animation,
                        axis: Axis.horizontal,
                        child: child,
                      ),
                      child: _isExtended
                          ? SizedBox(
                              width: 150,
                              child: NavigationRail(
                                extended: true,
                                selectedIndex: _selectedIndex,
                                onDestinationSelected: (int index) {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                },
                                labelType: null,
                                destinations: const [
                                  NavigationRailDestination(
                                    icon: Icon(Icons.home),
                                    label: Text('Home'),
                                  ),
                                  NavigationRailDestination(
                                    icon: Icon(Icons.settings),
                                    label: Text('Settings'),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    if (_isExtended) const VerticalDivider(thickness: 1, width: 1),
                    // Main content area always visible
                    Expanded(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Stack(
                              children: [
                                Image.asset(
                                  'assets/images/school.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.lightGreen.withOpacity(0.3),
                                        Colors.green.shade900.withOpacity(1.0),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Center(
                            child: _selectedIndex == 0
                                ? Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: SingleChildScrollView(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Answerable Forms Card
                                          Column(
                                            children: [
                                              Container(
                                                width: 250,
                                                height: 250,
                                                margin: const EdgeInsets.only(bottom: 32),
                                                decoration: BoxDecoration(
                                                  //color: Colors.white.withOpacity(0.8),
                                                  //borderRadius: BorderRadius.circular(280),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withOpacity(0),
                                                      blurRadius: 20,
                                                      offset: Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                clipBehavior: Clip.hardEdge,
                                                child: Image.asset(
                                                  'assets/images/logonbg.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              ),
                                              SizedBox(
                                                width: 250,
                                                child: Card(
                                                  elevation: 4,
                                                  child: InkWell(
                                                    onTap: _navigateToAnswerableFormsPage,
                                                    child: SizedBox(
                                                      height: 150,
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: const [
                                                          Icon(Icons.assignment, size: 48, color: Colors.blue),
                                                          SizedBox(height: 12),
                                                          Text(
                                                            'Answerable Forms',
                                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 24),
                                          // Guidance Scheduling Card
                                          SizedBox(
                                            width: 250,
                                            child: Card(
                                              elevation: 4,
                                              child: InkWell(
                                                onTap: _navigateToGuidanceSchedulingPage,
                                                child: SizedBox(
                                                  height: 150,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      const Icon(Icons.calendar_month, size: 48, color: Colors.green),
                                                      const SizedBox(height: 12),
                                                      Text(
                                                        _schedulingStatus == SchedulingStatus.none
                                                            ? 'Guidance Scheduling'
                                                            : _schedulingStatus == SchedulingStatus.processing
                                                                ? 'Request: Processing'
                                                                : 'Request: Approved',
                                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                      ),
                                                      if (_schedulingStatus == SchedulingStatus.processing)
                                                        const Padding(
                                                          padding: EdgeInsets.only(top: 8.0),
                                                          child: CircularProgressIndicator(),
                                                        ),
                                                      if (_schedulingStatus == SchedulingStatus.approved)
                                                        const Padding(
                                                          padding: EdgeInsets.only(top: 8.0),
                                                          child: Icon(Icons.check_circle, color: Colors.green),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          // Good Moral Request Card
                                          SizedBox(
                                            width: 250,
                                            child: Card(
                                              elevation: 4,
                                              child: InkWell(
                                                onTap: _navigateToGoodMoralRequestPage,
                                                child: SizedBox(
                                                  height: 150,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: const [
                                                      Icon(Icons.description, size: 48, color: Colors.orange),
                                                      SizedBox(height: 12),
                                                      Text(
                                                        'Good Moral Request',
                                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text('Settings Page'),
                                      const SizedBox(height: 20),
                                      if (_schedulingStatus == SchedulingStatus.processing)
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _schedulingStatus = SchedulingStatus.approved;
                                            });
                                          },
                                          child: const Text('Approve Request (Demo)'),
                                        ),
                                      if (_schedulingStatus == SchedulingStatus.approved)
                                        ElevatedButton(
                                          onPressed: () {
                                            setState(() {
                                              _schedulingStatus = SchedulingStatus.none;
                                            });
                                          },
                                          child: const Text('Reset Scheduling Status'),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Help icon at bottom right
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.blueAccent,
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Help'),
                          content: const Text('This is a demo app for PLSP Guidance Counseling. '
                              'Use the cards to navigate through different functionalities.'), 
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Help',
                    child: const Icon(Icons.help_outline, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  void _navigateToGuidanceSchedulingPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuidanceSchedulingPage(
          status: _schedulingStatus,
        ),
      ),
    );
  }

  void _navigateToGoodMoralRequestPage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GoodMoralRequest(),
      ),
    );
  }
}
