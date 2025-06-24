import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Map<String, dynamic>> habits = [];

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('uid', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .get();

    setState(() {
      habits.clear();
      habits.addAll(
        snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'habit': data['habit'],
            'frequency': data['frequency'],
            'completedDates': List<String>.from(data['completedDates'] ?? []),
          };
        }),
      );
    });
  }

  bool isCompletedToday(List<String> completedDates) {
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    return completedDates.contains(todayStr);
  }

  Future<void> _toggleCompletion(int index) async {
    final habit = habits[index];
    final completedDates = List<String>.from(habit['completedDates']);
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";

    if (completedDates.contains(todayStr)) {
      completedDates.remove(todayStr);
    } else {
      completedDates.add(todayStr);
    }

    // Update Firestore
    await FirebaseFirestore.instance
        .collection('habits')
        .doc(habit['id'])
        .update({'completedDates': completedDates});

    // Update local state
    setState(() {
      habits[index]['completedDates'] = completedDates;
    });
  }

  Future<void> _addHabit() async {
    final result = await Navigator.pushNamed(context, '/add');
    if (result != null && result is Map<String, String>) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final newHabit = {
        'uid': user.uid,
        'habit': result['habit'],
        'frequency': result['frequency'],
        'completedDates': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _loadHabits();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Habit Tracker',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            color: Colors.white,
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: habits.isEmpty
          ? Center(
              child: Text(
                'Belum ada kebiasaan',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                final completedDates =
                    habit['completedDates'] as List<String>;
                final today = DateTime.now();
                final todayStr = "${today.year}-${today.month}-${today.day}";
                final isCompleted = completedDates.contains(todayStr);

                return Card(
                  color: Colors.grey[900],
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(
                      habit['habit'],
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color:
                            isCompleted ? Colors.greenAccent : Colors.white,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    subtitle: Text(
                      'Frekuensi: ${habit['frequency']}',
                      style: GoogleFonts.poppins(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        isCompleted
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isCompleted ? Colors.green : Colors.white,
                      ),
                      onPressed: () => _toggleCompletion(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        backgroundColor: Colors.amber,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
