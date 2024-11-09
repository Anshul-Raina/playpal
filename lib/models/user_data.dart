class UserData {
  final String uid; // New field for UID
  final String name;
  final int age;
  final String gender;
  final String pronouns;
  final String location;
  final String relationshipGoal;
  final String sexualOrientation;
  final List<String> lookingFor;
  final List<String> favoriteActivities;
  final List<String> topFiveFavorites;
  final String musicPreferences;
  final String uniqueInterests;
  final String profileImageUrl;
  final List<String> photoUrls;
  final bool completedOnboarding;

  UserData({
    required this.uid, // Initialize UID
    required this.name,
    required this.age,
    required this.gender,
    required this.pronouns,
    required this.location,
    required this.relationshipGoal,
    required this.sexualOrientation,
    required this.lookingFor,
    required this.favoriteActivities,
    required this.topFiveFavorites,
    required this.musicPreferences,
    required this.uniqueInterests,
    required this.profileImageUrl,
    required this.photoUrls,
    this.completedOnboarding = false,
  });

  UserData copyWith({
    String? uid,
    String? name,
    int? age,
    String? gender,
    String? pronouns,
    String? location,
    String? relationshipGoal,
    String? sexualOrientation,
    List<String>? lookingFor,
    List<String>? favoriteActivities,
    List<String>? topFiveFavorites,
    String? musicPreferences,
    String? uniqueInterests,
    String? profileImageUrl,
    List<String>? photoUrls,
    bool? completedOnboarding,
  }) {
    return UserData(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      pronouns: pronouns ?? this.pronouns,
      location: location ?? this.location,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      sexualOrientation: sexualOrientation ?? this.sexualOrientation,
      lookingFor: lookingFor ?? this.lookingFor,
      favoriteActivities: favoriteActivities ?? this.favoriteActivities,
      topFiveFavorites: topFiveFavorites ?? this.topFiveFavorites,
      musicPreferences: musicPreferences ?? this.musicPreferences,
      uniqueInterests: uniqueInterests ?? this.uniqueInterests,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      completedOnboarding: completedOnboarding ?? this.completedOnboarding,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid, // Add UID to map
      'name': name,
      'age': age,
      'gender': gender,
      'pronouns': pronouns,
      'location': location,
      'relationshipGoal': relationshipGoal,
      'sexualOrientation': sexualOrientation,
      'lookingFor': lookingFor,
      'favoriteActivities': favoriteActivities,
      'topFiveFavorites': topFiveFavorites,
      'musicPreferences': musicPreferences,
      'uniqueInterests': uniqueInterests,
      'profileImageUrl': profileImageUrl,
      'photoUrls': photoUrls,
      'completedOnboarding': completedOnboarding,
    };
  }

  factory UserData.fromMap(Map<String, dynamic> map) {
    return UserData(
      uid: map['uid'] ?? '', // Read UID from map
      name: map['name'] ?? '',
      age: map['age']?.toInt() ?? 0,
      gender: map['gender'] ?? '',
      pronouns: map['pronouns'] ?? '',
      location: map['location'] ?? '',
      relationshipGoal: map['relationshipGoal'] ?? '',
      sexualOrientation: map['sexualOrientation'] ?? '',
      lookingFor: List<String>.from(map['lookingFor'] ?? []),
      favoriteActivities: List<String>.from(map['favoriteActivities'] ?? []),
      topFiveFavorites: List<String>.from(map['topFiveFavorites'] ?? []),
      musicPreferences: map['musicPreferences'] ?? '',
      uniqueInterests: map['uniqueInterests'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      photoUrls: List<String>.from(map['photoUrls'] ?? []),
      completedOnboarding: map['completedOnboarding'] ?? false,
    );
  }
}
