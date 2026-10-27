
class UserModel {
  final String id;
  final String? email;
  final String username;
  final String displayName;
  final String? bio;
  final String? avatarPath;
  final String? coverPath;
  final List<String>? specialties;
  final String? websiteUrl;
  final Map<String, dynamic>? socialLinks;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.email,
    required this.username,
    this.displayName = 'New Artist',
    this.bio,
    this.avatarPath,
    this.coverPath,
    this.specialties = const [],
    this.websiteUrl,
    this.socialLinks = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String,
      displayName:
          json['display_name'] as String? ?? 'New Artist',
      bio: json['bio'] as String?,
      avatarPath: json['avatar_path'] as String?,
      coverPath: json['cover_path'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((item) => item as String)
              .toList() ??
          const [],
      websiteUrl: json['website_url'] as String?,
      socialLinks: Map<String, dynamic>.from(
        json['social_links'] as Map? ?? {},
      ),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_path': avatarPath,
      'cover_path': coverPath,
      'specialties': specialties,
      'website_url': websiteUrl,
      'social_links': socialLinks,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? email,
    String? username,
    String? displayName,
    String? bio,
    String? avatarPath,
    String? coverPath,
    List<String>? specialties,
    String? websiteUrl,
    Map<String, dynamic>? socialLinks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      specialties: specialties ?? this.specialties,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
