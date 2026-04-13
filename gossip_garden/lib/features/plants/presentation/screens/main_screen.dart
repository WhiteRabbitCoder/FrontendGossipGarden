import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';

import 'dashboard_screen.dart';
import 'chat_list_screen.dart';
import 'garden_view_screen.dart';
import 'plant_profile_screen.dart';
import 'plant_chat_screen.dart';

import '../widgets/animated_bottom_nav.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    /// ONBOARDING SIMPLE
    if (nav.showOnboarding) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: notifier.completeOnboarding,
            child: const Text('Entrar'),
          ),
        ),
      );
    }

    final hasOverlay =
        nav.showChat || nav.showPlantProfile || nav.selectedFriendId != null;

    return Scaffold(
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
                const Center(child: Text('Profile')),
              ],
            ),
          ),

          /// OVERLAY
          if (hasOverlay) _buildOverlay(nav, notifier),
        ],
      ),
      bottomNavigationBar: hasOverlay
          ? null
          : AnimatedBottomNav(
              activeTab: nav.activeTab,
              onTabChange: notifier.changeTab,
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

    return const SizedBox.shrink();
  }
}
