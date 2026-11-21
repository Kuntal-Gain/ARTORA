import 'package:artora/src/features/discover/model/discover_models.dart';
import 'package:artora/src/features/discover/presentation/providers/block_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
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
    final me = AppConfig.supabase.auth.currentUser?.id;
    final blocked = ref.watch(blockedIdsProvider);

    return MasonryGrid<Artwork>(
      items: artworks,
      aspectRatioOf: (artwork) => artwork.aspectRatio,
      footerExtent: showFollow ? 0.4 : 0.3,
      itemBuilder: (context, artwork) => ArtworkTile(
        artwork: artwork,
        onTap: () => context.push(AppRoutes.artworkDetailPath(artwork.id)),
        isLiked: liked.contains(artwork.id),
        isBookmarked: bookmarked.contains(artwork.id),
        onLike: () => toggleLikeOptimistic(ref, artwork.id),
        onBookmark: () =>
            ref.read(bookmarkedProvider.notifier).toggle(artwork.id),
        // null hides the pill: nothing to follow on your own work.
        isFollowing: showFollow && artwork.artist.id != me
            ? following.contains(artwork.artist.id)
            : null,
        onFollow: () =>
            ref.read(followActionsProvider).toggle(artwork.artist.id),
        isBlocked: blocked.contains(artwork.artist.id),
        onUnblock: () => unblockWithToast(ref, artwork.artist.id),
      ),
    );
  }
}
