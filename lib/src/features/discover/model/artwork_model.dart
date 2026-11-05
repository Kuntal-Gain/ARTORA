import 'package:equatable/equatable.dart';

class ArtworkListModel extends Equatable {
  const ArtworkListModel({
    this.artworks = const [],
    this.pagination = const ArtworkPaginationModel(),
  });

  final List<ArtworkModel> artworks;
  final ArtworkPaginationModel pagination;

  factory ArtworkListModel.fromJson(Map<String, dynamic> json) {
    return ArtworkListModel(
      artworks: (json['data'] as List<dynamic>? ?? [])
          .map(
            (e) => ArtworkModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      pagination: json['pagination'] is Map<String, dynamic>
          ? ArtworkPaginationModel.fromJson(
              json['pagination'] as Map<String, dynamic>,
            )
          : const ArtworkPaginationModel(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': artworks.map((e) => e.toJson()).toList(),
      'pagination': pagination.toJson(),
    };
  }

  ArtworkListModel copyWith({
    List<ArtworkModel>? artworks,
    ArtworkPaginationModel? pagination,
  }) {
    return ArtworkListModel(
      artworks: artworks ?? this.artworks,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  List<Object?> get props => [artworks, pagination];
}

class ArtworkPaginationModel extends Equatable {
  const ArtworkPaginationModel({
    this.nextCursor,
    this.hasMore = false,
  });

  final String? nextCursor;
  final bool hasMore;

  factory ArtworkPaginationModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ArtworkPaginationModel(
      nextCursor: json['next_cursor'] as String?,
      hasMore: json['has_more'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'next_cursor': nextCursor,
      'has_more': hasMore,
    };
  }

  ArtworkPaginationModel copyWith({
    String? nextCursor,
    bool? hasMore,
  }) {
    return ArtworkPaginationModel(
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
    );
  }

  @override
  List<Object?> get props => [nextCursor, hasMore];
}

class ArtworkModel extends Equatable {
  const ArtworkModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.images = const [],
    this.category,
    this.tags = const [],
    this.visibility = 'public',
    this.isLiked = false,
    this.isBookmarked = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? description;
  final List<ArtworkImageModel> images;
  final ArtworkCategoryModel? category;
  final List<String> tags;
  final String visibility;
  final bool isLiked;
  final bool isBookmarked;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory ArtworkModel.fromJson(Map<String, dynamic> json) {
    return ArtworkModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      images: ((json['images'] as List<dynamic>? ?? []).toList()
            ..sort(
              (a, b) => ((a as Map)['position'] as num? ?? 0).compareTo(
                (b as Map)['position'] as num? ?? 0,
              ),
            ))
          .map(
            (e) => ArtworkImageModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      category: json['category'] is Map<String, dynamic>
          ? ArtworkCategoryModel.fromJson(
              json['category'] as Map<String, dynamic>,
            )
          : null,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      visibility: json['visibility'] as String? ?? 'public',
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      createdAt: DateTime.tryParse(
        json['created_at'] as String? ?? '',
      ),
      updatedAt: DateTime.tryParse(
        json['updated_at'] as String? ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'images': images.map((e) => e.toJson()).toList(),
      'category': category?.toJson(),
      'tags': tags,
      'visibility': visibility,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  ArtworkModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    List<ArtworkImageModel>? images,
    ArtworkCategoryModel? category,
    List<String>? tags,
    String? visibility,
    bool? isLiked,
    bool? isBookmarked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ArtworkModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      images: images ?? this.images,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      visibility: visibility ?? this.visibility,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        images,
        category,
        tags,
        visibility,
        isLiked,
        isBookmarked,
        createdAt,
        updatedAt,
      ];
}

class ArtworkImageModel extends Equatable {
  const ArtworkImageModel({
    required this.url,
    this.thumbnailUrl,
    this.mimeType,
    this.size,
  });

  final String url;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? size;

  factory ArtworkImageModel.fromJson(Map<String, dynamic> json) {
    return ArtworkImageModel(
      url: json['image_url'] as String? ?? json['url'] as String? ?? '',
      thumbnailUrl: json['thumbnail_url'] as String?,
      mimeType: json['mime_type'] as String?,
      size: (json['size'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'mime_type': mimeType,
      'size': size,
    };
  }

  ArtworkImageModel copyWith({
    String? url,
    String? thumbnailUrl,
    String? mimeType,
    int? size,
  }) {
    return ArtworkImageModel(
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
    );
  }

  @override
  List<Object?> get props => [
        url,
        thumbnailUrl,
        mimeType,
        size,
      ];
}

class ArtworkCategoryModel extends Equatable {
  const ArtworkCategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  final String id;
  final String name;
  final String slug;

  factory ArtworkCategoryModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ArtworkCategoryModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
    };
  }

  ArtworkCategoryModel copyWith({
    String? id,
    String? name,
    String? slug,
  }) {
    return ArtworkCategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
    );
  }

  @override
  List<Object?> get props => [id, name, slug];
}
