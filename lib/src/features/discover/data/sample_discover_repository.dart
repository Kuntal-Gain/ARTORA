import 'package:artora/src/features/discover/data/discover_repository.dart';
import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/imports/core_imports.dart';

/// In-app sample content, used until the artwork tables exist in Supabase.
///
/// To go live, implement [DiscoverRepository] against Supabase and return it
/// from `discoverRepositoryProvider`; the screens only use the contract.
/// Follows, likes and bookmarks are accepted but not persisted.
class SampleDiscoverRepository implements DiscoverRepository {
  static const Duration _latency = Duration(milliseconds: 350);

  static String _image(String seed, double aspectRatio) =>
      'https://picsum.photos/seed/artora-$seed/600/${(600 / aspectRatio).round()}';

  static String _avatar(String seed) =>
      'https://picsum.photos/seed/avatar-$seed/200/200';

  static Artist _artist(
    String id,
    String username,
    String displayName,
    int followers,
    List<String> specialties,
  ) => Artist(
    id: id,
    username: username,
    displayName: displayName,
    avatarUrl: _avatar(username),
    followers: followers,
    specialties: specialties,
  );

  static final Artist _me = _artist('me', 'you', 'You', 0, const []);

  static final List<Artist> _artists = [
    _artist('a1', 'lunaart', 'Luna Art', 12000, ['Digital Painting', 'Anime']),
    _artist('a2', 'kairo.arts', 'Kairo', 8400, ['Character Design', 'Anime']),
    _artist('a3', 'serenova', 'Serenova', 15000, ['Digital Painting', 'Concept Art']),
    _artist('a4', 'pixelnomad', 'Pixel Nomad', 9100, ['Pixel Art', 'Concept Art']),
    _artist('a5', 'artemis', 'Artemis', 11000, ['Character Design', '3D Art']),
    _artist('a6', 'mayasketches', 'Maya Sharma', 6300, ['Anime', 'Digital Painting']),
    _artist('a7', 'nyxdraws', 'Nyx', 4700, ['Concept Art', '3D Art']),
    _artist('a8', 'sakura.ink', 'Sakura Ink', 7200, ['Anime', 'Pixel Art']),
  ];

  static Artist _by(String username) =>
      _artists.firstWhere((artist) => artist.username == username);

  static Artwork _artwork(
    String id,
    String title,
    String username,
    String category,
    double aspectRatio,
    int likes,
    int comments,
    List<String> tags, {
    bool isEditorsPick = false,
  }) => Artwork(
    id: id,
    title: title,
    imageUrl: _image(id, aspectRatio),
    aspectRatio: aspectRatio,
    artist: _by(username),
    category: category,
    tags: tags,
    likes: likes,
    comments: comments,
    isEditorsPick: isEditorsPick,
  );

  static final List<Artwork> _artworks = [
    _artwork('w1', 'Nebula Dreams', 'lunaart', 'Digital Painting', 0.78, 1200, 48, ['fantasy', 'illustration', 'digitalpainting'], isEditorsPick: true),
    _artwork('w2', 'Lost Civilization', 'pixelnomad', 'Concept Art', 0.95, 842, 32, ['fantasy', 'environment', 'conceptart']),
    _artwork('w3', 'Shadow Blade', 'kairo.arts', 'Character Design', 0.8, 2400, 96, ['characterart', 'anime', 'scifi']),
    _artwork('w4', 'Coastal Evening', 'serenova', 'Digital Painting', 1.05, 692, 24, ['environment', 'landscape']),
    _artwork('w5', 'Silver Wanderer', 'mayasketches', 'Anime', 0.85, 1800, 57, ['anime', 'characterart']),
    _artwork('w6', 'Cozy Reading Nook', 'sakura.ink', 'Digital Painting', 0.9, 530, 18, ['illustration', 'interior']),
    _artwork('w7', 'Forest Guardian', 'lunaart', 'Digital Painting', 0.92, 2100, 64, ['fantasy', 'characterart', 'digitalpainting'], isEditorsPick: true),
    _artwork('w8', 'Moonlit Castle', 'pixelnomad', 'Concept Art', 1, 1400, 32, ['fantasy', 'environment'], isEditorsPick: true),
    _artwork('w9', 'Torii at Dusk', 'serenova', 'Digital Painting', 0.82, 980, 21, ['environment', 'anime']),
    _artwork('w10', "Dragon's Watch", 'artemis', 'Concept Art', 0.88, 3100, 112, ['fantasy', 'conceptart', 'scifi'], isEditorsPick: true),
    _artwork('w11', 'Neon District', 'nyxdraws', '3D Art', 0.75, 1650, 40, ['scifi', 'environment']),
    _artwork('w12', 'Ember Knight', 'artemis', 'Character Design', 0.7, 1270, 33, ['characterart', 'fantasy']),
    _artwork('w13', 'Pixel Harbor', 'sakura.ink', 'Pixel Art', 1.2, 760, 15, ['pixelart', 'environment']),
    _artwork('w14', 'Starfall Valley', 'serenova', 'Digital Painting', 1.3, 2250, 71, ['fantasy', 'environment', 'landscape'], isEditorsPick: true),
    _artwork('w15', 'Clockwork Heart', 'nyxdraws', '3D Art', 1, 590, 12, ['scifi', 'conceptart']),
    _artwork('w16', 'Spirit of the Tide', 'mayasketches', 'Anime', 0.8, 1930, 58, ['anime', 'fantasy']),
    _artwork('w17', 'Arcade Nights', 'pixelnomad', 'Pixel Art', 0.95, 640, 19, ['pixelart', 'scifi']),
    _artwork('w18', 'Crimson Ronin', 'kairo.arts', 'Anime', 0.72, 2700, 88, ['anime', 'characterart'], isEditorsPick: true),
    _artwork('w19', 'Crystal Bloom', 'lunaart', 'Digital Painting', 1, 1100, 29, ['fantasy', 'digitalpainting']),
    _artwork('w20', 'Sky Whale', 'nyxdraws', 'Concept Art', 1.25, 870, 26, ['scifi', 'conceptart', 'fantasy']),
  ];

  static final List<ArtCategory> _categories = [
    for (final name in [
      'Digital Painting',
      'Anime',
      'Character Design',
      'Concept Art',
      'Pixel Art',
      '3D Art',
    ])
      ArtCategory(name: name, imageUrl: _image('cat-$name', 1)),
  ];

  static const List<String> _trendingTags = [
    'illustration',
    'characterart',
    'fantasy',
    'scifi',
    'anime',
    'environment',
    'conceptart',
    'pixelart',
    'digitalpainting',
  ];

  static final List<ArtCollection> _collections = [
    ArtCollection(id: 'c1', title: 'Ethereal Worlds', coverUrl: _image('col-ethereal', 1.6), artworkCount: 32),
    ArtCollection(id: 'c2', title: 'Anime Spotlight', coverUrl: _image('col-anime', 1.6), artworkCount: 28),
    ArtCollection(id: 'c3', title: 'Dark Fantasy', coverUrl: _image('col-dark', 1.6), artworkCount: 19),
    ArtCollection(id: 'c4', title: 'Cozy Corners', coverUrl: _image('col-cozy', 1.6), artworkCount: 24),
  ];

  static final List<String> _allTags = {
    for (final artwork in _artworks) ...artwork.tags,
  }.toList()..sort();

  Future<Resource<T>> _respond<T>(T data) async {
    await Future<void>.delayed(_latency);
    return Resource<T>.success(data);
  }

  @override
  Future<Resource<Artist>> currentArtist() => _respond(_me);

  @override
  Future<Resource<List<Artwork>>> feed() => _respond(_artworks);

  @override
  Future<Resource<ExploreContent>> explore() => _respond((
    categories: _categories,
    trendingTags: _trendingTags,
    collections: _collections,
    artists: _artists,
    editorsPicks: _artworks.where((artwork) => artwork.isEditorsPick).toList(),
  ));

  @override
  Future<Resource<List<String>>> trendingTags() => _respond(_trendingTags);

  @override
  Future<Resource<SearchResults>> search(String query) {
    final q = query.trim().toLowerCase().replaceFirst('#', '');
    if (q.isEmpty) return _respond(SearchResults.empty);

    bool matches(String value) => value.toLowerCase().contains(q);

    return _respond(
      SearchResults(
        artworks: _artworks
            .where(
              (artwork) =>
                  matches(artwork.title) ||
                  matches(artwork.category) ||
                  matches(artwork.artist.username) ||
                  artwork.tags.any(matches),
            )
            .toList(),
        artists: _artists
            .where(
              (artist) =>
                  matches(artist.username) ||
                  matches(artist.displayName) ||
                  artist.specialties.any(matches),
            )
            .toList(),
        tags: _allTags.where(matches).toList(),
      ),
    );
  }

  @override
  Future<Resource<Set<String>>> followingIds() => _respond({'a5', 'a7'});

  @override
  Future<Resource<void>> setFollowing(
    String artistId, {
    required bool following,
  }) => _respond<void>(null);

  @override
  Future<Resource<void>> setLiked(String artworkId, {required bool liked}) =>
      _respond<void>(null);

  @override
  Future<Resource<void>> setBookmarked(
    String artworkId, {
    required bool bookmarked,
  }) => _respond<void>(null);
}
