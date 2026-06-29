import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../providers/plant_providers.dart';
import '../providers/achievement_providers.dart';

import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'garden_view_screen.dart';
import 'plant_profile_screen.dart';
import 'plant_chat_screen.dart';
import 'friend_garden_screen.dart';
import 'profile_settings_screen.dart';

import '../widgets/animated_bottom_nav.dart';
import '../../../../core/theme/garden_colors.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    ref.watch(achievementStatsProvider);
    final plants = ref.watch(plantsProvider).valueOrNull;
    if (plants != null) {
      for (final plant in plants) {
        ref.watch(achievementWateringWatcherProvider(plant.id));
      }
    }

    final hasOverlay =
        nav.showChat || nav.showPlantProfile || nav.selectedFriendId != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (hasOverlay) {
          notifier.handleBack();
        } else if (nav.activeTab != TabId.dashboard) {
          notifier.changeTab(TabId.dashboard);
        } else {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Offstage(
              offstage: hasOverlay,
              child: SafeArea(
                child: PageTransitionSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
                    return FadeThroughTransition(
                      animation: primaryAnimation,
                      secondaryAnimation: secondaryAnimation,
                      fillColor: Colors.transparent,
                      child: child,
                    );
                  },
                  child: _buildCurrentScreen(nav.activeTab.index, notifier),
                ),
              ),
            ),
            /// OVERLAY (Animated)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutQuart,
                    reverseCurve: Curves.easeInQuart,
                  )),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: _buildOverlay(nav, notifier),
            ),
  
            /// BOTTOM NAV (True Floating)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(animation),
                  child: child,
                );
              },
              child: hasOverlay 
                ? const SizedBox.shrink(key: ValueKey('hiddenNav'))
                : Align(
                    key: const ValueKey('bottomNav'),
                    alignment: Alignment.bottomCenter,
                    child: AnimatedBottomNav(
                      activeTab: nav.activeTab,
                      onTabChange: notifier.changeTab,
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay(NavigationState nav, NavigationNotifier notifier) {
    if (nav.showPlantProfile) {
      return PlantProfileScreen(
        key: ValueKey('PlantProfileScreen_${nav.selectedPlantId}'),
        plantId: nav.selectedPlantId,
        onBack: notifier.handleBack,
        onOpenChat: notifier.openChat,
      );
    }
    if (nav.showChat) {
      return PlantChatScreen(
        key: ValueKey('PlantChatScreen_${nav.selectedPlantId}'),
        plantId: nav.selectedPlantId,
        onBack: notifier.handleBack,
      );
    }
    if (nav.selectedFriendId != null) {
      return FriendGardenScreen(
        key: ValueKey('FriendGardenScreen_${nav.selectedFriendId}'),
        friendId: nav.selectedFriendId!,
        onBack: notifier.handleBack,
      );
    }
    return const SizedBox.shrink(key: ValueKey('empty_overlay'));
  }

  Widget _buildCurrentScreen(int index, NavigationNotifier notifier) {
    switch (index) {
      case 0:
        return DashboardScreen(
          key: const ValueKey('DashboardScreen'),
          onSelectPlant: notifier.selectPlant,
          onOpenChat: notifier.openChat,
          onOpenFriendGarden: notifier.openFriendGarden,
        );
      case 1:
        return const ChatListScreen(key: ValueKey('ChatListScreen'));
      case 2:
        return GardenViewScreen(key: const ValueKey('GardenViewScreen'));
      case 3:
        return const ProfileSettingsScreen(key: ValueKey('ProfileSettingsScreen'));
      default:
        return const SizedBox.shrink();
    }
  }
}
