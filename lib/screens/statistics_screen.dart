import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int totalHabits = 0;
  int totalCompleted = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('habits')
        .where('uid', isEqualTo: user.uid)
        .get();

    int completed = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final completedDates = List<String>.from(data['completedDates'] ?? []);
      completed += completedDates.length;
    }

    setState(() {
      totalHabits = snapshot.docs.length;
      totalCompleted = completed;
    });
  }

  @override
  Widget build(BuildContext context) {
    double successRate = totalHabits == 0
        ? 0
        : (totalCompleted / (totalHabits * 7)) * 100; // asumsi seminggu

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Statistik & Progres',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _statTile("Total Kebiasaan", totalHabits.toString()),
            _statTile("Total Hari Diselesaikan", totalCompleted.toString()),
            _statTile("Persentase Keberhasilan", "${successRate.toStringAsFixed(1)}%"),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: successRate / 100,
              backgroundColor: Colors.grey,
              color: Colors.amber,
              minHeight: 10,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        "$label: $value",
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
