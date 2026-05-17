import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gossip_garden/features/plants/presentation/providers/navigation_provider.dart';

ProviderContainer buildContainer() {
  final container = ProviderContainer();
  return container;
}

void main() {
  late ProviderContainer container;

  setUp(() {
    container = buildContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('NavigationState — estado inicial', () {
    test('tab activo es dashboard', () {
      final state = container.read(navigationProvider);
      expect(state.activeTab, TabId.dashboard);
    });

    test('ningún overlay activo', () {
      final state = container.read(navigationProvider);
      expect(state.showChat, isFalse);
      expect(state.showPlantProfile, isFalse);
      expect(state.selectedFriendId, isNull);
    });
  });

  group('NavigationNotifier.changeTab', () {
    test('cambia al tab garden', () {
      container.read(navigationProvider.notifier).changeTab(TabId.garden);
      expect(container.read(navigationProvider).activeTab, TabId.garden);
    });

    test('cambia al tab chat', () {
      container.read(navigationProvider.notifier).changeTab(TabId.chat);
      expect(container.read(navigationProvider).activeTab, TabId.chat);
    });

    test('cierra overlays al cambiar de tab', () {
      // Abre un overlay primero
      container.read(navigationProvider.notifier).openChat('plant-1');
      expect(container.read(navigationProvider).showChat, isTrue);

      // Cambiar de tab cierra el chat
      container.read(navigationProvider.notifier).changeTab(TabId.garden);
      expect(container.read(navigationProvider).showChat, isFalse);
      expect(container.read(navigationProvider).showPlantProfile, isFalse);
    });

    test('limpia selectedFriendId al cambiar de tab', () {
      container
          .read(navigationProvider.notifier)
          .openFriendGarden('friend-uuid');
      expect(container.read(navigationProvider).selectedFriendId, isNotNull);

      container.read(navigationProvider.notifier).changeTab(TabId.profile);
      expect(container.read(navigationProvider).selectedFriendId, isNull);
    });
  });

  group('NavigationNotifier.selectPlant', () {
    test('muestra plant profile y cierra chat', () {
      // Abre chat primero
      container.read(navigationProvider.notifier).openChat('p1');
      expect(container.read(navigationProvider).showChat, isTrue);

      // Seleccionar planta cierra chat y abre perfil
      container.read(navigationProvider.notifier).selectPlant('p2');
      final state = container.read(navigationProvider);
      expect(state.showPlantProfile, isTrue);
      expect(state.showChat, isFalse);
      expect(state.selectedPlantId, 'p2');
    });
  });

  group('NavigationNotifier.openChat', () {
    test('muestra chat y cierra plant profile', () {
      container.read(navigationProvider.notifier).selectPlant('p1');
      expect(container.read(navigationProvider).showPlantProfile, isTrue);

      container.read(navigationProvider.notifier).openChat('p1');
      final state = container.read(navigationProvider);
      expect(state.showChat, isTrue);
      expect(state.showPlantProfile, isFalse);
    });
  });

  group('NavigationNotifier.openFriendGarden', () {
    test('setea selectedFriendId', () {
      container
          .read(navigationProvider.notifier)
          .openFriendGarden('friend-uuid-123');
      expect(
        container.read(navigationProvider).selectedFriendId,
        'friend-uuid-123',
      );
    });
  });

  group('NavigationNotifier.handleBack', () {
    test('cierra chat y devuelve false (no pop de la app)', () {
      container.read(navigationProvider.notifier).openChat('p1');

      final shouldPop =
          container.read(navigationProvider.notifier).handleBack();

      expect(shouldPop, isFalse);
      expect(container.read(navigationProvider).showChat, isFalse);
    });

    test('cierra plant profile y devuelve false', () {
      container.read(navigationProvider.notifier).selectPlant('p1');

      final shouldPop =
          container.read(navigationProvider.notifier).handleBack();

      expect(shouldPop, isFalse);
      expect(container.read(navigationProvider).showPlantProfile, isFalse);
    });

    test('cierra friend garden y devuelve false', () {
      container.read(navigationProvider.notifier).openFriendGarden('f1');

      final shouldPop =
          container.read(navigationProvider.notifier).handleBack();

      expect(shouldPop, isFalse);
      expect(container.read(navigationProvider).selectedFriendId, isNull);
    });

    test('devuelve true cuando no hay overlay activo (salir de la app)', () {
      // Estado inicial limpio → handleBack devuelve true
      final shouldPop =
          container.read(navigationProvider.notifier).handleBack();
      expect(shouldPop, isTrue);
    });

    test('chat tiene prioridad sobre plantProfile', () {
      // Abre profile y luego chat (openChat cierra profile)
      container.read(navigationProvider.notifier).selectPlant('p1');
      expect(container.read(navigationProvider).showPlantProfile, isTrue);

      container.read(navigationProvider.notifier).openChat('p1');
      expect(container.read(navigationProvider).showChat, isTrue);
      expect(container.read(navigationProvider).showPlantProfile, isFalse);

      // handleBack cierra el chat (prioridad más alta)
      final shouldPop =
          container.read(navigationProvider.notifier).handleBack();
      expect(shouldPop, isFalse);
      expect(container.read(navigationProvider).showChat, isFalse);

      // Ahora sin overlays → handleBack retorna true
      final shouldPopFinal =
          container.read(navigationProvider.notifier).handleBack();
      expect(shouldPopFinal, isTrue);
    });
  });

  group('NavigationState.copyWith', () {
    test('solo actualiza los campos especificados', () {
      const original = NavigationState(
        activeTab: TabId.dashboard,
        selectedPlantId: 'p1',
        showChat: false,
      );

      final updated = original.copyWith(activeTab: TabId.chat);

      expect(updated.activeTab, TabId.chat);
      expect(updated.selectedPlantId, 'p1'); // sin cambios
      expect(updated.showChat, isFalse); // sin cambios
    });

    test('selectedFriendId se setea a null con copyWith sin pasar el param', () {
      final original = NavigationState(
        activeTab: TabId.dashboard,
        selectedPlantId: 'p1',
        selectedFriendId: 'f1',
      );

      // copyWith sin selectedFriendId → usa null (comportamiento de la implementación actual)
      final updated = original.copyWith(activeTab: TabId.garden);
      expect(updated.selectedFriendId, isNull);
    });
  });
}
