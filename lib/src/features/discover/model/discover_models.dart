/// An artist as shown on feed cards, artist rows and search results.
class Artist {
  const Artist({
    required this.id,
    required this.username,
    required this.displayName,
    required this.avatarUrl,
    this.followers = 0,
    this.specialties = const [],
  });

  final String id;
  final String username;
  final String displayName;
  final String avatarUrl;
  final int followers;
  final List<String> specialties;
}

class Artwork {
  const Artwork({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.aspectRatio,
    required this.artist,
    required this.category,
    this.tags = const [],
    this.likes = 0,
    this.comments = 0,
    this.isEditorsPick = false,
  });

  final String id;
  final String title;
  final String imageUrl;

  /// Image width / height, used to size masonry tiles before the image loads.
  final double aspectRatio;
  final Artist artist;
  final String category;
  final List<String> tags;
  final int likes;
  final int comments;
  final bool isEditorsPick;
}

class ArtCategory {
  const ArtCategory({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

class ArtCollection {
  const ArtCollection({
    required this.id,
    required this.title,
    required this.coverUrl,
    required this.artworkCount,
  });

  final String id;
  final String title;
  final String coverUrl;
  final int artworkCount;
}

class SearchResults {
  const SearchResults({
    this.artworks = const [],
    this.artists = const [],
    this.tags = const [],
  });

  static const SearchResults empty = SearchResults();

  final List<Artwork> artworks;
  final List<Artist> artists;
  final List<String> tags;
}

/// Everything the explore screen shows, loaded in one go.
typedef ExploreContent = ({
  List<ArtCategory> categories,
  List<String> trendingTags,
  List<ArtCollection> collections,
  List<Artist> artists,
  List<Artwork> editorsPicks,
});

enum SearchScope { all, artwork, artists, tags }
