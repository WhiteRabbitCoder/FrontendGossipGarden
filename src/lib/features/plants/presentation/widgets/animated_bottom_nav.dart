import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/navigation_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_text_styles.dart';

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
    (TabId.garden, Icons.eco_rounded, 'Jardín'),
    (TabId.chat, Icons.chat_bubble_rounded, 'Chats'),
    (TabId.profile, Icons.person_rounded, 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: GardenColors.creamPaper.withOpacity(0.85),
              borderRadius: BorderRadius.circular(38),
              border: Border.all(
                color: GardenColors.leafGreen.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: GardenColors.leafDark.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.map((tab) {
                final isActive = activeTab == tab.$1;
                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onTabChange(tab.$1);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isActive && tab.$1 != TabId.dashboard) ? GardenColors.leafDark : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: tab.$1 == TabId.dashboard
                              ? AnimatedScale(
                                  scale: isActive ? 1.3 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOutBack,
                                  child: Opacity(
                                    opacity: isActive ? 1.0 : 0.6,
                                    child: Image.asset(
                                      'images/house_icon.png',
                                      width: 32,
                                      height: 32,
                                    ),
                                  ),
                                )
                              : Icon(
                                  tab.$2,
                                  size: 24,
                                  color: isActive ? Colors.white : GardenColors.inkSoft,
                                ),
                        ),
                        if (isActive) const SizedBox(height: 2),
                        if (isActive)
                          Text(
                            tab.$3,
                            style: GardenTextStyles.label.copyWith(
                              fontSize: 12,
                              color: GardenColors.leafDark,
                              fontWeight: FontWeight.w800,
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
      ),
    );
  }
}
