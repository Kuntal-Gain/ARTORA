import 'dart:io';

import 'package:equatable/equatable.dart';

/// Values the create / edit form sends.
///
/// [images] are new local files to upload. On update an empty list keeps the
/// artwork's existing images.
class PostArtworkModel extends Equatable {
  const PostArtworkModel({
    required this.title,
    required this.categoryId,
    this.description,
    this.tags = const [],
    this.visibility = 'public',
    this.images = const [],
  });

  final String title;
  final String? description;
  final String categoryId;
  final List<String> tags;

  /// 'public', 'private' or 'draft'.
  final String visibility;
  final List<File> images;

  /// Row values without the images (those are uploaded separately).
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'tags': tags,
      'visibility': visibility,
    };
  }

  PostArtworkModel copyWith({
    String? title,
    String? description,
    String? categoryId,
    List<String>? tags,
    String? visibility,
    List<File>? images,
  }) {
    return PostArtworkModel(
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      images: images ?? this.images,
    );
  }

  @override
  List<Object?> get props => [
        title,
        description,
        categoryId,
        tags,
        visibility,
        images,
      ];
}
