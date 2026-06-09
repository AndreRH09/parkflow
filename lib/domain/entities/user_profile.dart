class UserProfile {
  final String id;
  final String? email;
  final String? fullName;
  final int? age;
  final String? dni;
  final String? phone;
  final String? avatarUrl;
  final String? role;
  final double rating;
  final int ratingCount;
  final bool profileComplete;
  final bool garageConfigComplete;
  final String? city;

  const UserProfile({
    required this.id,
    this.email,
    this.fullName,
    this.age,
    this.dni,
    this.phone,
    this.avatarUrl,
    this.role,
    this.rating = 0,
    this.ratingCount = 0,
    this.profileComplete = false,
    this.garageConfigComplete = false,
    this.city,
  });

  bool get needsOnboarding =>
      !profileComplete || fullName == null || age == null || dni == null;
  bool get needsRoleSelection => profileComplete && role == null;
  bool get needsGarageSetup => role == 'host' && !garageConfigComplete;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      email: map['email'] as String?,
      fullName: map['full_name'] as String?,
      age: map['age'] as int?,
      dni: map['dni'] as String?,
      phone: map['phone'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      role: map['role'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: (map['rating_count'] as int?) ?? 0,
      profileComplete: (map['profile_complete'] as bool?) ?? false,
      garageConfigComplete: (map['garage_config_complete'] as bool?) ?? false,
      city: map['city'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'full_name': fullName,
        'age': age,
        'dni': dni,
        'phone': phone,
        'avatar_url': avatarUrl,
        'role': role,
        'profile_complete': profileComplete,
        'garage_config_complete': garageConfigComplete,
        'city': city,
      };

  UserProfile copyWith({
    String? fullName,
    int? age,
    String? dni,
    String? phone,
    String? avatarUrl,
    String? role,
    bool? profileComplete,
    bool? garageConfigComplete,
    String? city,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      age: age ?? this.age,
      dni: dni ?? this.dni,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      rating: rating,
      ratingCount: ratingCount,
      profileComplete: profileComplete ?? this.profileComplete,
      garageConfigComplete: garageConfigComplete ?? this.garageConfigComplete,
      city: city ?? this.city,
    );
  }
}
