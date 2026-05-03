/// Model representing a user of the application
/// 
/// Contains user profile information and preferences.
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final UserPreferences preferences;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.lastLoginAt,
    required this.preferences,
  });

  /// Creates a User from JSON data
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'] as String)
          : null,
      preferences: json['preferences'] != null
          ? UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>)
          : const UserPreferences(),
    );
  }

  /// Converts the User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'preferences': preferences.toJson(),
    };
  }

  /// Creates a copy of this User with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    UserPreferences? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model representing user preferences and settings
class UserPreferences {
  final bool notificationsEnabled;
  final bool expiryAlertsEnabled;
  final int expiryAlertDays; // Days before expiry to alert
  final String currency;
  final String measurementSystem; // 'metric' or 'imperial'
  final List<String> dietaryRestrictions;
  final List<String> allergens;
  final double? monthlyBudget;

  const UserPreferences({
    this.notificationsEnabled = true,
    this.expiryAlertsEnabled = true,
    this.expiryAlertDays = 3,
    this.currency = 'USD',
    this.measurementSystem = 'metric',
    this.dietaryRestrictions = const [],
    this.allergens = const [],
    this.monthlyBudget,
  });

  /// Creates UserPreferences from JSON data
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      expiryAlertsEnabled: json['expiryAlertsEnabled'] as bool? ?? true,
      expiryAlertDays: json['expiryAlertDays'] as int? ?? 3,
      currency: json['currency'] as String? ?? 'USD',
      measurementSystem: json['measurementSystem'] as String? ?? 'metric',
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? (json['dietaryRestrictions'] as List<dynamic>)
              .map((e) => e as String)
              .toList()
          : [],
      allergens: json['allergens'] != null
          ? (json['allergens'] as List<dynamic>).map((e) => e as String).toList()
          : [],
      monthlyBudget: json['monthlyBudget'] != null
          ? (json['monthlyBudget'] as num).toDouble()
          : null,
    );
  }

  /// Converts UserPreferences to JSON
  Map<String, dynamic> toJson() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'expiryAlertsEnabled': expiryAlertsEnabled,
      'expiryAlertDays': expiryAlertDays,
      'currency': currency,
      'measurementSystem': measurementSystem,
      'dietaryRestrictions': dietaryRestrictions,
      'allergens': allergens,
      'monthlyBudget': monthlyBudget,
    };
  }

  /// Creates a copy of UserPreferences with updated fields
  UserPreferences copyWith({
    bool? notificationsEnabled,
    bool? expiryAlertsEnabled,
    int? expiryAlertDays,
    String? currency,
    String? measurementSystem,
    List<String>? dietaryRestrictions,
    List<String>? allergens,
    double? monthlyBudget,
  }) {
    return UserPreferences(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      expiryAlertsEnabled: expiryAlertsEnabled ?? this.expiryAlertsEnabled,
      expiryAlertDays: expiryAlertDays ?? this.expiryAlertDays,
      currency: currency ?? this.currency,
      measurementSystem: measurementSystem ?? this.measurementSystem,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergens: allergens ?? this.allergens,
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
    );
  }

  /// Checks if using metric system
  bool get isMetric => measurementSystem.toLowerCase() == 'metric';

  /// Checks if using imperial system
  bool get isImperial => measurementSystem.toLowerCase() == 'imperial';

  @override
  String toString() {
    return 'UserPreferences(currency: $currency, measurementSystem: $measurementSystem)';
  }
}

// Made with Bob
