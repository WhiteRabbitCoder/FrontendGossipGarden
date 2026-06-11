import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/navigation_provider.dart';
import '../../../../core/theme/garden_colors.dart';
import '../../../../core/theme/garden_icons.dart';
import '../../../../core/theme/garden_text_styles.dart';
import '../../../../core/widgets/garden_icon.dart';

class AnimatedBottomNav extends StatelessWidget {
  final TabId activeTab;
  final ValueChanged<TabId> onTabChange;

  const AnimatedBottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  static const _tabs = [
    (TabId.dashboard, GardenIcons.home, 'Inicio'),
    (TabId.garden, GardenIcons.garden, 'Jardín'),
    (TabId.chat, GardenIcons.chat, 'Chats'),
    (TabId.profile, GardenIcons.profile, 'Perfil'),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? GardenColors.leafDark
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: AnimatedScale(
                            scale: isActive ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: GardenIcon(
                              asset: tab.$2,
                              size: 26,
                              opacity: isActive ? 1.0 : 0.55,
                            ),
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
                          ),
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
