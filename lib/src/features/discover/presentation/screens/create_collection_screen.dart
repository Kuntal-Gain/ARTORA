import 'dart:io';

import 'package:artora/src/features/discover/data/discover_usecase_impl.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/presentation/providers/collection_providers.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/shared/widgets/navigation/artora_bottom_nav.dart';

/// Name, optional cover and a pick of your own artworks -> a new collection.
class CreateCollectionScreen extends ConsumerStatefulWidget {
  const CreateCollectionScreen({super.key});

  @override
  ConsumerState<CreateCollectionScreen> createState() =>
      _CreateCollectionScreenState();
}

class _CreateCollectionScreenState
    extends ConsumerState<CreateCollectionScreen> {
  static const int _maxName = DiscoverUsecaseImpl.collectionTitleMax;
  static const int _profileTab = 3;

  final _name = TextEditingController();
  File? _cover;
  List<ArtworkModel> _artworks = [];

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickCover() async {
    final result = await MediaService.instance.pickImage(
      source: ImageSource.gallery,
    );
    final file = result.fold((failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return null;
    }, (file) => file);
    if (file == null || !mounted) return;
    final saved = await MediaService.instance.persist(file);
    if (mounted) setState(() => _cover = saved);
  }

  Future<void> _pickArtworks() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<List<ArtworkModel>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => _ArtworkPickerSheet(initial: _artworks),
    );
    if (picked != null) setState(() => _artworks = picked);
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref.read(createCollectionProvider.notifier).submit(
      title: _name.text,
      cover: _cover,
      artworkIds: [for (final a in _artworks) a.id],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(createCollectionProvider, (_, next) {
      switch (next) {
        case RequestSuccess():
          showGlobalToast(message: LocaleKeys.collection_created.tr());
          context.canPop() ? context.pop() : context.go(AppRoutes.profile);
        case RequestFailure(:final failure):
          showGlobalToast(message: failure.message, status: 'error');
        case RequestInitial() || RequestLoading():
          break;
      }
    });
    final busy = ref.watch(createCollectionProvider) is RequestLoading;
    final canSubmit = !busy && _name.text.trim().isNotEmpty;
    final textTheme = context.textTheme;
    final showIntro = _cover == null && _artworks.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      bottomNavigationBar: ArtoraBottomNav(
        currentIndex: _profileTab,
        onSelected: (index) => context.go(ArtoraBottomNav.tabPaths[index]),
        onCreate: ArtoraBottomNav.showCreateComingSoon,
      ),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.profile),
        ),
        title: Text(
          LocaleKeys.collection_create_title.tr(),
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.pagePadding,
          AppSpacing.sm,
          AppSpacing.pagePadding,
          // Clear the floating bottom nav.
          MediaQuery.paddingOf(context).bottom + 110.r,
        ),
        children: [
          if (showIntro) ...[
            const Center(
                child: AppStackedCardsArt(badge: true, sparkles: false)),
            AppSpacing.vGap(AppSpacing.md),
            Text(
              LocaleKeys.collection_intro_title.tr(),
              textAlign: TextAlign.center,
              style: textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            AppSpacing.vGap(AppSpacing.xs),
            Text(
              LocaleKeys.collection_intro_hint.tr(),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            AppSpacing.vGap(AppSpacing.lg),
          ],
          _Label(LocaleKeys.collection_name_label.tr(), required: true),
          _NameField(controller: _name, maxLength: _maxName),
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_name.text.length}/$_maxName',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
          _Label(
            LocaleKeys.collection_cover_label.tr(),
            note: LocaleKeys.collection_optional.tr(),
          ),
          if (_cover == null)
            AppDashedBox(
              onTap: busy ? null : _pickCover,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(
                      AppIcons.imageAdd,
                      size: 34.r,
                      color: AppColors.textPrimary,
                    ),
                    AppSpacing.vGap(AppSpacing.sm),
                    Text(
                      LocaleKeys.collection_add_cover.tr(),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vGap(AppSpacing.xs),
                    Text(
                      LocaleKeys.collection_cover_formats.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _CoverPreview(
              file: _cover!,
              onChange: busy ? null : _pickCover,
              onRemove: busy ? null : () => setState(() => _cover = null),
            ),
          AppSpacing.vGap(AppSpacing.lg),
          Row(
            children: [
              Expanded(
                  child: _Label(LocaleKeys.collection_artworks_label.tr())),
              Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  LocaleKeys.collection_artwork_count.tr(
                    namedArgs: {'count': '${_artworks.length}'},
                  ),
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          if (_artworks.isEmpty)
            AppDashedBox(
              onTap: busy ? null : _pickArtworks,
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    const _PlusDot(),
                    AppSpacing.vGap(AppSpacing.sm),
                    Text(
                      LocaleKeys.collection_artworks_label.tr(),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppSpacing.vGap(AppSpacing.xs),
                    Text(
                      LocaleKeys.collection_artworks_hint.tr(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _artworks.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppSpacing.ms,
                crossAxisSpacing: AppSpacing.ms,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, i) {
                final art = _artworks[i];
                return _ArtworkThumb(
                  url: _thumbOf(art),
                  onRemove: busy
                      ? null
                      : () => setState(
                            () => _artworks = [..._artworks]..removeAt(i),
                          ),
                );
              },
            ),
            AppSpacing.vGap(AppSpacing.ms),
            AppDashedBox(
              onTap: busy ? null : _pickArtworks,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Column(
                  children: [
                    const _PlusDot(),
                    AppSpacing.vGap(AppSpacing.xs),
                    Text(
                      LocaleKeys.collection_add_more.tr(),
                      style: textTheme.titleSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          AppSpacing.vGap(AppSpacing.lg),
          SizedBox(
            height: 52.h,
            child: FilledButton(
              onPressed: canSubmit ? _submit : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.elevated,
                disabledForegroundColor: AppColors.textDisabled,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppBorders.md,
                ),
              ),
              child: busy
                  ? SizedBox.square(
                      dimension: 20.r,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : Text(
                      LocaleKeys.collection_create_title.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

String? _thumbOf(ArtworkModel art) {
  if (art.images.isEmpty) return null;
  final first = art.images.first;
  return first.thumbnailUrl ?? first.url;
}

// ── Pieces ─────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false, this.note});

  final String text;
  final bool required;

  /// Lighter suffix, e.g. "(Optional)".
  final String? note;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.titleSmall?.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w600,
    );
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text.rich(
        TextSpan(
          text: text,
          style: style,
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: style?.copyWith(color: AppColors.error),
              ),
            if (note != null)
              TextSpan(
                text: ' $note',
                style: style?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.maxLength});

  final TextEditingController controller;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: AppBorders.md,
      borderSide: BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.done,
      textCapitalization: TextCapitalization.words,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      style: context.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: LocaleKeys.collection_name_hint.tr(),
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: AppColors.textDisabled,
        ),
        prefixIcon: Icon(
          AppIcons.layers,
          size: 20.r,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _PlusDot extends StatelessWidget {
  const _PlusDot();

  @override
  Widget build(BuildContext context) => Container(
        width: 36.r,
        height: 36.r,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(AppIcons.add, size: 20.r, color: AppColors.background),
      );
}

/// Dark round button over an image (remove "x").
class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: LocaleKeys.collection_remove.tr(),
      child: Material(
        color: AppColors.scrim,
        shape: CircleBorder(
          side: BorderSide(color: AppColors.white.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(AppIcons.close, size: 16.r, color: AppColors.white),
          ),
        ),
      ),
    );
  }
}

class _CoverPreview extends StatelessWidget {
  const _CoverPreview({
    required this.file,
    required this.onChange,
    required this.onRemove,
  });

  final File file;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorders.lg,
      child: AspectRatio(
        aspectRatio: 1.8,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(file, fit: BoxFit.cover),
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: _RemoveButton(onTap: onRemove),
            ),
            Positioned(
              right: AppSpacing.ms,
              bottom: AppSpacing.ms,
              child: Material(
                color: AppColors.scrim,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: AppColors.white.withValues(alpha: 0.5),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: onChange,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.ms,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AppIcons.image,
                            size: 16.r, color: AppColors.white),
                        AppSpacing.hGap(AppSpacing.xs),
                        Text(
                          LocaleKeys.collection_change_cover.tr(),
                          style: context.textTheme.labelMedium?.copyWith(
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkThumb extends StatelessWidget {
  const _ArtworkThumb({required this.url, this.onRemove, this.selected});

  final String? url;
  final VoidCallback? onRemove;

  /// Picker mode: null hides the check; true / false shows its state.
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    final image = url;
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        borderRadius: AppBorders.md,
        border: Border.all(
          color: selected ?? false
              ? AppColors.primary
              : AppColors.primary.withValues(alpha: 0.25),
          width: selected ?? false ? 3 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: AppBorders.md,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image == null || image.isEmpty)
              const ColoredBox(
                color: AppColors.elevated,
                child: Icon(AppIcons.image, color: AppColors.textSecondary),
              )
            else
              CommonImage(imageUrl: image, fit: BoxFit.cover),
            if (onRemove != null)
              Positioned(
                top: AppSpacing.xs,
                right: AppSpacing.xs,
                child: _RemoveButton(onTap: onRemove),
              ),
            if (selected ?? false)
              Positioned(
                right: AppSpacing.xs,
                bottom: AppSpacing.xs,
                child:
                    Icon(AppIcons.check, size: 24.r, color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Multi-select of your own artworks, keeping the order they were tapped in.
class _ArtworkPickerSheet extends ConsumerStatefulWidget {
  const _ArtworkPickerSheet({required this.initial});

  final List<ArtworkModel> initial;

  @override
  ConsumerState<_ArtworkPickerSheet> createState() =>
      _ArtworkPickerSheetState();
}

class _ArtworkPickerSheetState extends ConsumerState<_ArtworkPickerSheet> {
  late final List<ArtworkModel> _selected = [...widget.initial];

  void _toggle(ArtworkModel art) => setState(() {
        final i = _selected.indexWhere((a) => a.id == art.id);
        i == -1 ? _selected.add(art) : _selected.removeAt(i);
      });

  @override
  Widget build(BuildContext context) {
    final uid = AppConfig.supabase.auth.currentUser?.id;
    final feed = uid == null
        ? const RequestLoading<ArtworkListModel>()
        : ref.watch(userArtworkFeedProvider(uid));

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.pagePadding),
              child: Text(
                LocaleKeys.collection_pick_title.tr(),
                style: context.textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AppSpacing.vGap(AppSpacing.ms),
            Expanded(
              child: switch (feed) {
                RequestInitial() || RequestLoading() => const AppLoading(),
                RequestFailure(:final failure) => AppErrorWidget(
                    message: failure.message,
                    onRetry: () => ref
                        .read(userArtworkFeedProvider(uid!).notifier)
                        .refresh(),
                  ),
                RequestSuccess(:final data) when data.artworks.isEmpty =>
                  AppEmptyState(
                    icon: AppIcons.image,
                    title: LocaleKeys.profile_no_artworks.tr(),
                  ),
                RequestSuccess(:final data) => GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.pagePadding,
                    ),
                    itemCount: data.artworks.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                    ),
                    itemBuilder: (context, i) {
                      final art = data.artworks[i];
                      return GestureDetector(
                        onTap: () => _toggle(art),
                        child: _ArtworkThumb(
                          url: _thumbOf(art),
                          selected: _selected.any((a) => a.id == art.id),
                        ),
                      );
                    },
                  ),
              },
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.pagePadding),
              child: SizedBox(
                height: 52.h,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_selected),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppBorders.md,
                    ),
                  ),
                  child: Text(
                    LocaleKeys.collection_pick_done.tr(
                      namedArgs: {'count': '${_selected.length}'},
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
