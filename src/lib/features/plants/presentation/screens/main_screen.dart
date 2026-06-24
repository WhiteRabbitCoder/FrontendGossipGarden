import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
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
            SafeArea(
              child: IndexedStack(
                index: nav.activeTab.index,
                children: [
                  DashboardScreen(
                    onSelectPlant: notifier.selectPlant,
                    onOpenChat: notifier.openChat,
                    onOpenFriendGarden: notifier.openFriendGarden,
                  ),
                  const ChatListScreen(),
                  GardenViewScreen(),
                  const ProfileSettingsScreen(),
                ],
              ),
            ),
  
            /// OVERLAY
            if (hasOverlay) _buildOverlay(nav, notifier),
  
            /// BOTTOM NAV (True Floating)
            if (!hasOverlay)
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedBottomNav(
                  activeTab: nav.activeTab,
                  onTabChange: notifier.changeTab,
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
        plantId: nav.selectedPlantId,
        onBack: notifier.handleBack,
        onOpenChat: notifier.openChat,
      );
    }
    if (nav.showChat) {
      return PlantChatScreen(
        plantId: nav.selectedPlantId,
        onBack: notifier.handleBack,
      );
    }
    if (nav.selectedFriendId != null) {
      return FriendGardenScreen(
        friendId: nav.selectedFriendId!,
        onBack: notifier.handleBack,
      );
    }

    return const SizedBox.shrink();
  }
}
