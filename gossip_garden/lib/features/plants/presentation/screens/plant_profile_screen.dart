import 'package:flutter/material.dart';

class PlantProfileScreen extends StatelessWidget {
  final String plantId;
  final VoidCallback onBack;
  final Function(String) onOpenChat;

  const PlantProfileScreen({
    super.key,
    required this.plantId,
    required this.onBack,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plant $plantId'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => onOpenChat(plantId),
          child: const Text('Abrir chat'),
        ),
      ),
    );
  }
}