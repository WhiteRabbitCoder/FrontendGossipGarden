import 'achievement.dart';
import 'plant.dart';

class FriendGarden {
  final String id;
  final String displayName;
  final List<Plant> featuredPlants;
  final List<AchievementProgress> achievements;

  const FriendGarden({
    required this.id,
    required this.displayName,
    required this.featuredPlants,
    required this.achievements,
  });
}
