
import 'dart:io';

import 'package:equatable/equatable.dart';

// Import your existing ArtworkImageModel.

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
  final String visibility;
  final List<File> images;


  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'category_id': categoryId,
      'tags': tags,
      'visibility': visibility,
      'images': images.toList(),
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
