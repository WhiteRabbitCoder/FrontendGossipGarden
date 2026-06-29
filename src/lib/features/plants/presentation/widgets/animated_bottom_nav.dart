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
      decoration: BoxDecoration(
        color: GardenColors.creamPaper,
        image: const DecorationImage(
          image: AssetImage('images/PaperTexture.png'),
          fit: BoxFit.cover,
          opacity: 0.3,
        ),
        borderRadius: BorderRadius.circular(38),
        border: Border.all(
          color: GardenColors.ink,
          width: 1.8,
        ),
        boxShadow: const [
          BoxShadow(
            color: GardenColors.ink,
            blurRadius: 0,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: GardenColors.creamLight,
          borderRadius: BorderRadius.circular(36),
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
                            border: isActive
                                ? Border.all(
                                    color: GardenColors.ink,
                                    width: 1.5,
                                  )
                                : null,
                          ),
                          child: AnimatedScale(
                            scale: isActive ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            child: GardenIcon(
                              asset: tab.$2,
                              size: 26,
                              color: isActive ? GardenColors.creamLight : null,
                            ),
                          ),
                        ),
                        if (isActive) const SizedBox(height: 2),
                        if (isActive)
                          Text(
                            tab.$3,
                            style: GardenTextStyles.label.copyWith(
                              fontSize: 12,
                              color: GardenColors.ink,
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
    );
  }
}
