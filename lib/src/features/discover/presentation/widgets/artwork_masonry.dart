import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_tile.dart';
import 'package:artora/src/features/discover/presentation/widgets/masonry_grid.dart';
import 'package:artora/src/imports/imports.dart';

/// Masonry of [ArtworkTile]s wired to the like / bookmark / follow state.
/// Used by the feed, search results and saved screens.
class ArtworkMasonry extends ConsumerWidget {
  const ArtworkMasonry({
    super.key,
    required this.artworks,
    this.showFollow = false,
  });

  final List<Artwork> artworks;

  /// Feed layout with a Follow pill; otherwise the compact search layout.
  final bool showFollow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked = ref.watch(likedProvider);
    final bookmarked = ref.watch(bookmarkedProvider);
    final following = ref.watch(followingProvider);

    return MasonryGrid<Artwork>(
      items: artworks,
      aspectRatioOf: (artwork) => artwork.aspectRatio,
      footerExtent: showFollow ? 0.4 : 0.3,
      itemBuilder: (context, artwork) => ArtworkTile(
        artwork: artwork,
        isLiked: liked.contains(artwork.id),
        isBookmarked: bookmarked.contains(artwork.id),
        onLike: () => ref.read(likedProvider.notifier).toggle(artwork.id),
        onBookmark: () =>
            ref.read(bookmarkedProvider.notifier).toggle(artwork.id),
        isFollowing: showFollow ? following.contains(artwork.artist.id) : null,
        onFollow: () =>
            ref.read(followingProvider.notifier).toggle(artwork.artist.id),
      ),
    );
  }
}
