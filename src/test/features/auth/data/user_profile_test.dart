import 'package:flutter_test/flutter_test.dart';

import 'package:gossip_garden/features/auth/data/user_profile.dart';

void main() {
  group('UserProfile.fromJson', () {
    test('parsea perfil completo', () {
      final profile = UserProfile.fromJson({
        'uid': 'user-uuid-123',
        'displayName': 'Angel Gaviria',
        'email': 'angel@example.com',
        'photoURL': 'https://example.com/photo.jpg',
        'onboardingCompleted': true,
        'favoritePlantIds': ['plant1', 'plant2'],
        'useGridView': false,
        'notificationPreference': 'all',
      });

      expect(profile.uid, 'user-uuid-123');
      expect(profile.displayName, 'Angel Gaviria');
      expect(profile.email, 'angel@example.com');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.onboardingCompleted, isTrue);
      expect(profile.favoritePlantIds, ['plant1', 'plant2']);
      expect(profile.useGridView, isFalse);
      expect(profile.notificationPreference, 'all');
    });

    test('usa defaults seguros para campos ausentes', () {
      final profile = UserProfile.fromJson({'uid': 'id-only'});

      expect(profile.uid, 'id-only');
      expect(profile.displayName, isNull);
      expect(profile.email, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.onboardingCompleted, isFalse);
      expect(profile.favoritePlantIds, isEmpty);
      expect(profile.useGridView, isTrue);
      expect(profile.notificationPreference, 'important');
    });

    test('uid vacío cuando ausente', () {
      final profile = UserProfile.fromJson({});
      expect(profile.uid, '');
    });

    test('favoriteIds vacío cuando null', () {
      final profile = UserProfile.fromJson({'favoritePlantIds': null});
      expect(profile.favoritePlantIds, isEmpty);
    });
  });

  group('UserProfile.toJson', () {
    test('serializa correctamente', () {
      const profile = UserProfile(
        uid: 'uid-abc',
        displayName: 'Test User',
        email: 'test@example.com',
        photoUrl: 'https://photo.url',
        onboardingCompleted: true,
        favoritePlantIds: ['p1', 'p2'],
        useGridView: true,
        notificationPreference: 'important',
      );

      final json = profile.toJson();

      expect(json['uid'], 'uid-abc');
      expect(json['displayName'], 'Test User');
      expect(json['email'], 'test@example.com');
      expect(json['photoURL'], 'https://photo.url');
      expect(json['onboardingCompleted'], isTrue);
      expect(json['favoritePlantIds'], ['p1', 'p2']);
      expect(json['useGridView'], isTrue);
      expect(json['notificationPreference'], 'important');
    });

    test('round-trip fromJson → toJson preserva datos', () {
      final original = {
        'uid': 'uid-roundtrip',
        'displayName': 'Round Trip',
        'email': 'rt@example.com',
        'photoURL': null,
        'onboardingCompleted': false,
        'favoritePlantIds': <String>[],
        'useGridView': true,
        'notificationPreference': 'important',
      };

      final profile = UserProfile.fromJson(original);
      final serialized = profile.toJson();

      expect(serialized['uid'], original['uid']);
      expect(serialized['displayName'], original['displayName']);
      expect(serialized['onboardingCompleted'], original['onboardingCompleted']);
    });
  });
}
