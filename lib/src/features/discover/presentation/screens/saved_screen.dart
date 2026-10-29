import 'package:artora/src/features/discover/presentation/providers/discover_providers.dart';
import 'package:artora/src/features/discover/presentation/widgets/artwork_masonry.dart';
import 'package:artora/src/features/discover/presentation/widgets/masonry_grid.dart';
import 'package:artora/src/imports/imports.dart';

/// Artworks the user bookmarked from the feed, explore or search.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedArtworksProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              sliver: SliverToBoxAdapter(
                child: Text(
                  LocaleKeys.nav_saved.tr(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.colors.onSurface,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.pagePadding,
                0,
                AppSpacing.pagePadding,
                MediaQuery.paddingOf(context).bottom + AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: switch (saved) {
                  RequestInitial() || RequestLoading() =>
                    const MasonrySkeleton(),
                  RequestFailure() => AppErrorPresets.network(
                    onRetry: () => ref.read(feedProvider.notifier).refresh(),
                  ),
                  RequestSuccess(:final data) when data.isEmpty =>
                    AppEmptyPresets.noSaved(
                      onExplore: () => context.go(AppRoutes.explore),
                    ),
                  RequestSuccess(:final data) => ArtworkMasonry(
                    artworks: data,
                  ),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
