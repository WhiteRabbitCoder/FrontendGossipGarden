import 'package:flutter/material.dart';

class SummaryBanner extends StatelessWidget {
  final VoidCallback onAction;

  const SummaryBanner({super.key, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A6741), Color(0xFF6B8E23)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4A6741).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: Color(0xFFFFD12B), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ATENCIÓN REQUERIDA',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.0),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  '1 tiene sed, 2 buscan el sol',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1.2),
                ),
                const SizedBox(height: 8),
                Text(
                  'Te tomará menos de 3 minutos',
                  style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD12B),
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: const Text('Ayudarlas (3)', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                ),
              ],
            ),
          ),
          // Ilustración sutil a la derecha
          Opacity(
            opacity: 0.15,
            child: const Icon(Icons.eco_rounded, size: 100, color: Colors.white),
          ),
        ],
      ),
    );
  }
}