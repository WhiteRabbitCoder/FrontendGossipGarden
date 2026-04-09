import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../../../../core/widgets/keep_alive_wrapper.dart';

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nav = ref.watch(navigationProvider);
    final notifier = ref.read(navigationProvider.notifier);

    /// ONBOARDING
    if (nav.showOnboarding) {
      return OnboardingScreen(
        onComplete: notifier.completeOnboarding,
      );
    }

    final showOverlay =
        nav.showChat || nav.showPlantProfile || nav.selectedFriendId != null;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        final shouldExit = notifier.handleBack();
        if (shouldExit) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            /// 🔥 BASE CON ESTADO PERSISTENTE
            IndexedStack(
              index: nav.activeTab.index,
              children: [
                DashboardScreen(
                  onSelectPlant: notifier.selectPlant,
                  onOpenChat: notifier.openChat,
                  onOpenFriendGarden: notifier.openFriendGarden,
                ),
                ChatListScreen(
                  onOpenChat: notifier.openChat,
                ),
                GardenViewScreen(
                  onSelectPlant: notifier.selectPlant,
                ),
                const ProfileSettingsScreen(),
              ],
            ),

            /// 🔥 OVERLAYS (encima del stack)
            if (nav.showChat)
              PlantChatScreen(
                plantId: nav.selectedPlantId,
                onBack: notifier.handleBack,
              ),

            if (!nav.showChat && nav.showPlantProfile)
              PlantProfileScreen(
                plantId: nav.selectedPlantId,
                onBack: notifier.handleBack,
                onOpenChat: notifier.openChat,
              ),

            if (!nav.showChat &&
                !nav.showPlantProfile &&
                nav.selectedFriendId != null)
              FriendGardenScreen(
                friendId: nav.selectedFriendId!,
                onBack: notifier.handleBack,
              ),
          ],
        ),

        /// 🔥 Bottom Nav solo si no hay overlays
        bottomNavigationBar: showOverlay
            ? null
            : BottomNav(
                activeTab: nav.activeTab,
                onTabChange: notifier.changeTab,
              ),
      ),
    );
  }
}