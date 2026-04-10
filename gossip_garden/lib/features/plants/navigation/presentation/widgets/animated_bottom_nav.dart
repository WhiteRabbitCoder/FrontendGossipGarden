import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../presentation/providers/navigation_provider.dart';

class AnimatedBottomNav extends StatelessWidget {
  final TabId activeTab;
  final ValueChanged<TabId> onTabChange;

  const AnimatedBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  static const _tabs = [
    (TabId.dashboard, Icons.home_rounded, 'Inicio'),
    (TabId.chat, Icons.chat_bubble_outline_rounded, 'Chat'),
    (TabId.garden, Icons.local_florist_rounded, 'Jardín'),
    (TabId.profile, Icons.person_outline_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 88,
          padding: const EdgeInsets.only(top: 12, bottom: 18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.75),
            border: Border(
              top: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.08),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _tabs.map((tab) {
              final isActive = activeTab == tab.$1;

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTabChange(tab.$1);
                },
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 180),
                  scale: isActive ? 1.0 : 0.92,
                  curve: Curves.easeOutBack,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          tab.$2,
                          size: 24,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tab.$3,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                          color: isActive
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      )
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}