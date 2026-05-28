import 'package:flutter/material.dart';
import '../providers/navigation_provider.dart';

class NavLink extends StatelessWidget {
  final TabId tab;
  final TabId activeTab;
  final ValueChanged<TabId> onTap;
  final IconData icon;
  final String label;

  const NavLink({
    super.key,
    required this.tab,
    required this.activeTab,
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = activeTab == tab;
    return GestureDetector(
      onTap: () => onTap(tab),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF4A6741).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? const Color(0xFF4A6741) : Colors.black54,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? const Color(0xFF4A6741) : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
