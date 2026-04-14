class UserProfile {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;
  final bool onboardingCompleted;
  final List<String> favoritePlantIds;
  final bool useGridView;
  final String notificationPreference;

  const UserProfile({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
    required this.onboardingCompleted,
    required this.favoritePlantIds,
    required this.useGridView,
    required this.notificationPreference,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid']?.toString() ?? '',
      displayName: json['displayName']?.toString(),
      email: json['email']?.toString(),
      photoUrl: json['photoURL']?.toString(),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      favoritePlantIds:
          List<String>.from(json['favoritePlantIds'] as List? ?? const []),
      useGridView: json['useGridView'] as bool? ?? true,
      notificationPreference:
          json['notificationPreference']?.toString() ?? 'important',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoURL': photoUrl,
      'onboardingCompleted': onboardingCompleted,
      'favoritePlantIds': favoritePlantIds,
      'useGridView': useGridView,
      'notificationPreference': notificationPreference,
    };
  }
}
