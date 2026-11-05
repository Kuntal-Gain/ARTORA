import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String username;
  final String displayName;
  final String? email;
  final String? bio;
  final String? avatarPath;
  final String? coverPath;
  final String? websiteUrl;
  final Map<String, String> socialLinks;
  final List<String> specialties;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    this.email,
    this.bio,
    this.avatarPath,
    this.coverPath,
    this.websiteUrl,
    this.socialLinks = const {},
    this.specialties = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String,
      email: json['email'] as String?,
      bio: json['bio'] as String?,
      avatarPath: json['avatar_path'] as String?,
      coverPath: json['cover_path'] as String?,
      websiteUrl: json['website_url'] as String?,
      socialLinks: (json['social_links'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value.toString(),
            ),
          ) ??
          const {},
      specialties: List<String>.from(
        json['specialties'] as List? ?? const [],
      ),
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ),
      updatedAt: DateTime.tryParse(
        json['updated_at']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'display_name': displayName,
      'email': email,
      'bio': bio,
      'avatar_path': avatarPath,
      'cover_path': coverPath,
      'website_url': websiteUrl,
      'social_links': socialLinks,
      'specialties': specialties,
      'created_at': createdAt?.toUtc().toIso8601String(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    String? email,
    String? bio,
    String? avatarPath,
    String? coverPath,
    String? websiteUrl,
    Map<String, String>? socialLinks,
    List<String>? specialties,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      socialLinks: socialLinks ?? this.socialLinks,
      specialties: specialties ?? this.specialties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        displayName,
        email,
        bio,
        avatarPath,
        coverPath,
        websiteUrl,
        socialLinks,
        specialties,
        createdAt,
        updatedAt,
      ];
}
