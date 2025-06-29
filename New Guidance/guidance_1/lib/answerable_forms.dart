import 'package:flutter/material.dart';
import 'routine_interview_page.dart';
import 'scrf_page.dart';

class AnswerableForms extends StatelessWidget {
  const AnswerableForms({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge;
    return Scaffold(
       appBar: AppBar(
        title: const Text('Answerable Forms'),
        backgroundColor: const Color.fromARGB(255, 30, 182, 88),
      ),
      body: Stack(
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
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              padding: const EdgeInsets.all(24.0),
              children: [
                SizedBox(
                  height: 150,
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScrfPage()),
                        );
                      },
                      child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment, size: 48, color: Colors.blue),
                          const SizedBox(height: 12),
                          Text('Student Commulative Form', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    height: 150,
                    child: Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RoutineInterviewPage()),
                          );
                        },
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: const [
                              Icon(Icons.assignment, size: 48, color: Colors.blue),
                              SizedBox(height: 12),
                              Text('Routine Interview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {},
                      child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment, size: 48, color: Colors.blue),
                          const SizedBox(height: 12),
                          Text('Exit interview for transferring students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 150,
                  child: Card(
                    elevation: 4,
                    child: InkWell(
                      onTap: () {},
                      child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment, size: 48, color: Colors.blue),
                          const SizedBox(height: 12),
                          Text('Exit interview for graduating students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
