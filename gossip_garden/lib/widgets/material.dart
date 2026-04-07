import 'package:flutter/material.dart';

class PlantCard extends StatelessWidget {
  final String name;
  final String mood;
  final double hydration;

  const PlantCard({
    super.key, 
    required this.name, 
    required this.mood, 
    required this.hydration
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF1E1E1E), // Estética Eco-Tech oscura
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(Icons.eco, color: Colors.greenAccent, size: 40),
            Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(mood, style: const TextStyle(color: Colors.greenAccent)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: hydration,
              backgroundColor: Colors.white10,
              color: hydration < 0.3 ? Colors.redAccent : Colors.greenAccent,
            ),
          ],
        ),
      ),
    );
  }
}