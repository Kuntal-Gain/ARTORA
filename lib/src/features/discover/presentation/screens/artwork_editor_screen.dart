import 'dart:io';

import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/model/artwork_req_model.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/imports/imports.dart';

/// Create a new artwork, or edit one when [artworkId] is given.
class ArtworkEditorScreen extends ConsumerStatefulWidget {
  const ArtworkEditorScreen({super.key, this.artworkId});

  final String? artworkId;

  @override
  ConsumerState<ArtworkEditorScreen> createState() =>
      _ArtworkEditorScreenState();
}

class _ArtworkEditorScreenState extends ConsumerState<ArtworkEditorScreen> {
  static const int _maxTitle = 100;
  static const int _maxDescription = 500;
  static const int _maxTags = 10;

  final _title = TextEditingController();
  final _description = TextEditingController();
  final _tagInput = TextEditingController();
  final _tagFocus = FocusNode();

  File? _image;
  String? _existingImageUrl;
  ArtworkCategoryModel? _category;
  List<String> _tags = [];
  bool _isPrivate = false;
  String? _originalVisibility;
  bool _prefilled = false;

  /// 'draft' or 'public' while a create request runs, so only that button spins.
  String? _submittingAs;

  bool get _isEdit => widget.artworkId != null;

  bool get _hasImage => _image != null || _existingImageUrl != null;

  bool get _canPublish =>
      _hasImage && _title.text.trim().isNotEmpty && _category != null;

  @override
  void initState() {
    super.initState();
    _title.addListener(_rebuild);
    _description.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _tagInput.dispose();
    _tagFocus.dispose();
    super.dispose();
  }

  void _prefill(ArtworkModel art) {
    if (_prefilled) return;
    _prefilled = true;
    _title.text = art.title;
    _description.text = art.description ?? '';
    _category = art.category;
    _tags = [...art.tags];
    _originalVisibility = art.visibility;
    _isPrivate = art.visibility == 'private';
    final first = art.images.isEmpty ? null : art.images.first;
    _existingImageUrl = first?.url;
  }

  // ── Image ────────────────────────────────────────────────

  Future<void> _pickImage() async {
    final result = await MediaService.instance.pickImage(
      source: ImageSource.gallery,
    );
    final file = result.fold((failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return null;
    }, (file) => file);
    if (file == null || !mounted) return;
    final saved = await MediaService.instance.persist(file);
    if (!mounted) return;

    // Preview first; it returns the (possibly replaced) file on Continue.
    final confirmed = await context.push<File>(
      AppRoutes.artworkPreview,
      extra: saved,
    );
    if (confirmed != null && mounted) setState(() => _image = confirmed);
  }

  void _removeImage() => setState(() {
        _image = null;
        _existingImageUrl = null;
      });

  // ── Tags ─────────────────────────────────────────────────

  void _addTag(String raw) {
    final tag = raw.trim().replaceAll('#', '').toLowerCase();
    _tagInput.clear();
    if (tag.isEmpty || _tags.contains(tag)) return;
    if (_tags.length >= _maxTags) {
      showGlobalToast(message: 'You can add up to 10 tags.', status: 'error');
      return;
    }
    setState(() => _tags = [..._tags, tag]);
    _tagFocus.requestFocus();
  }

  void _removeTag(String tag) =>
      setState(() => _tags = _tags.where((t) => t != tag).toList());

  // ── Category ─────────────────────────────────────────────

  Future<void> _pickCategory() async {
    FocusScope.of(context).unfocus();
    final picked = await showModalBottomSheet<ArtworkCategoryModel>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (_) => _CategorySheet(selectedId: _category?.id),
    );
    if (picked != null) setState(() => _category = picked);
  }

  // ── Submit ───────────────────────────────────────────────

  PostArtworkModel _buildModel(String visibility) {
    final description = _description.text.trim();
    return PostArtworkModel(
      title: _title.text.trim(),
      description: description.isEmpty ? null : description,
      categoryId: _category!.id,
      tags: _tags,
      visibility: visibility,
      images: [if (_image != null) _image!],
    );
  }

  Future<void> _submitCreate({required bool draft}) async {
    if (!_canPublish) {
      showGlobalToast(
        message: 'Add an image, a title and a category first.',
        status: 'error',
      );
      return;
    }
    final visibility = draft ? 'draft' : 'public';
    setState(() => _submittingAs = visibility);
    await ref
        .read(postArtworkProvider.notifier)
        .submit(_buildModel(visibility));
    if (mounted) setState(() => _submittingAs = null);
  }

  Future<void> _submitEdit() async {
    // A draft stays a draft unless it's made private.
    final visibility = _isPrivate
        ? 'private'
        : (_originalVisibility == 'draft' ? 'draft' : 'public');
    await ref
        .read(updateArtworkProvider(widget.artworkId!).notifier)
        .submit(_buildModel(visibility));
  }

  Future<void> _delete() async {
    final confirmed = await showAppAlertDialog(
      context,
      title: 'Delete artwork?',
      message: 'This artwork will be removed permanently.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );
    if (confirmed != true) return;
    await ref.read(deleteArtworkProvider(widget.artworkId!).notifier).submit();
  }

  void _onResult(
    RequestState<void>? previous,
    RequestState<void> next,
    String successMessage,
  ) {
    switch (next) {
      case RequestSuccess():
        showGlobalToast(message: successMessage);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.profile);
        }
      case RequestFailure(:final failure):
        showGlobalToast(message: failure.message, status: 'error');
      case RequestInitial() || RequestLoading():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.artworkId;

    if (id == null) {
      ref.listen(
        postArtworkProvider,
        (prev, next) => _onResult(
          prev,
          next,
          _submittingAs == 'draft' ? 'Draft saved' : 'Artwork published',
        ),
      );
    } else {
      ref.listen(
        updateArtworkProvider(id),
        (prev, next) => _onResult(prev, next, 'Changes saved'),
      );
      ref.listen(
        deleteArtworkProvider(id),
        (prev, next) => _onResult(prev, next, 'Artwork deleted'),
      );
    }

    final Widget body;
    if (id == null) {
      body = _form(context);
    } else {
      body = switch (ref.watch(singleArtworkProvider(id))) {
        RequestInitial() || RequestLoading() => const AppLoading(),
        RequestFailure(:final failure) => AppErrorWidget(
            message: failure.message,
            onRetry: () =>
                ref.read(singleArtworkProvider(id).notifier).refresh(),
          ),
        RequestSuccess(:final data) => () {
            _prefill(data);
            return _form(context);
          }(),
      };
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(AppIcons.back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.home),
        ),
        title: Text(
          _isEdit ? 'Edit Artwork' : 'Create Artwork',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(top: false, child: body),
    );
  }

  Widget _form(BuildContext context) {
    final id = widget.artworkId;
    final createState = id == null ? ref.watch(postArtworkProvider) : null;
    final updateState =
        id == null ? null : ref.watch(updateArtworkProvider(id));
    final deleteState =
        id == null ? null : ref.watch(deleteArtworkProvider(id));
    final busy = createState is RequestLoading ||
        updateState is RequestLoading ||
        deleteState is RequestLoading;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pagePadding,
              AppSpacing.sm,
              AppSpacing.pagePadding,
              AppSpacing.lg,
            ),
            children: [
              if (_hasImage)
                _ImagePreviewCard(
                  file: _image,
                  url: _existingImageUrl,
                  onChange: busy ? null : _pickImage,
                  onRemove: _isEdit || busy ? null : _removeImage,
                )
              else
                _ImageDropZone(onTap: _pickImage),
              AppSpacing.vGap(AppSpacing.lg),
              const _Label('Title', required: true),
              _Input(
                controller: _title,
                hint: 'Enter artwork title',
                maxLength: _maxTitle,
              ),
              _Counter(_title.text.length, _maxTitle),
              const _Label('Description'),
              _Input(
                controller: _description,
                hint: 'Share the story behind your artwork...',
                maxLength: _maxDescription,
                maxLines: 4,
              ),
              _Counter(_description.text.length, _maxDescription),
              const _Label('Category', required: true),
              _CategoryField(category: _category, onTap: _pickCategory),
              AppSpacing.vGap(AppSpacing.ml),
              _Label(
                _tags.isEmpty
                    ? 'Tags (up to $_maxTags)'
                    : 'Tags (${_tags.length}/$_maxTags)',
              ),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final tag in _tags)
                      _TagChip(label: tag, onRemove: () => _removeTag(tag)),
                  ],
                ),
                AppSpacing.vGap(AppSpacing.ms),
              ],
              _Input(
                controller: _tagInput,
                focusNode: _tagFocus,
                hint: 'Type a tag and press enter',
                enabled: _tags.length < _maxTags,
                textInputAction: TextInputAction.done,
                onSubmitted: _addTag,
              ),
              if (_tags.isEmpty) _Counter(0, _maxTags),
              if (_isEdit) ...[
                AppSpacing.vGap(AppSpacing.ml),
                _PrivateToggle(
                  value: _isPrivate,
                  onChanged: (v) => setState(() => _isPrivate = v),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          child: Row(
            children: _isEdit
                ? [
                    Expanded(
                      child: _OutlineAction(
                        label: 'Delete Artwork',
                        color: AppColors.error,
                        isLoading: deleteState is RequestLoading,
                        onPressed: busy ? null : _delete,
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.ms),
                    Expanded(
                      child: _PrimaryAction(
                        label: 'Save Changes',
                        isLoading: updateState is RequestLoading,
                        onPressed: busy || !_canPublish ? null : _submitEdit,
                      ),
                    ),
                  ]
                : [
                    Expanded(
                      child: _OutlineAction(
                        label: 'Save as Draft',
                        color: AppColors.textPrimary,
                        isLoading: busy && _submittingAs == 'draft',
                        onPressed: busy || !_canPublish
                            ? null
                            : () => _submitCreate(draft: true),
                      ),
                    ),
                    AppSpacing.hGap(AppSpacing.ms),
                    Expanded(
                      child: _PrimaryAction(
                        label: 'Publish',
                        isLoading: busy && _submittingAs == 'public',
                        onPressed: busy || !_canPublish
                            ? null
                            : () => _submitCreate(draft: false),
                      ),
                    ),
                  ],
          ),
        ),
      ],
    );
  }
}

// ── Pieces ─────────────────────────────────────────────────

class _ImageDropZone extends StatelessWidget {
  const _ImageDropZone({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.textDisabled,
          radius: AppBorders.lg.topLeft.x,
        ),
        child: AspectRatio(
          aspectRatio: 1.2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.image,
                size: 36.r,
                color: AppColors.textPrimary,
              ),
              AppSpacing.vGap(AppSpacing.ms),
              Text(
                'Tap to select image',
                style: textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                'PNG, JPG, WebP • Max 20 MB',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.ms,
                  ),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppBorders.sm,
                  ),
                ),
                child: const Text('Select Image'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(radius),
        ),
      );
    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.file,
    required this.url,
    required this.onChange,
    required this.onRemove,
  });

  final File? file;
  final String? url;
  final VoidCallback? onChange;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppBorders.lg,
      child: AspectRatio(
        aspectRatio: 1.45,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (file != null)
              Image.file(file!, fit: BoxFit.cover)
            else
              CommonImage(imageUrl: url!, fit: BoxFit.cover),
            if (onRemove != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: _GlassButton(
                  onTap: onRemove,
                  tooltip: 'Remove image',
                  child: Icon(
                    AppIcons.close,
                    size: 18.r,
                    color: AppColors.white,
                  ),
                ),
              ),
            Positioned(
              right: AppSpacing.ms,
              bottom: AppSpacing.ms,
              child: _GlassButton(
                onTap: onChange,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.share,
                        size: 16.r,
                        color: AppColors.white,
                      ),
                      AppSpacing.hGap(AppSpacing.xs),
                      Text(
                        'Change Image',
                        style: context.textTheme.labelMedium?.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
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

/// Dark translucent pill/circle used over the image.
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.child, this.onTap, this.tooltip});

  final Widget child;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.scrim,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.sm),
          child: child,
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.required = false});

  final String text;
  final bool required;

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
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.maxLines = 1,
    this.focusNode,
    this.enabled = true,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final int maxLines;
  final FocusNode? focusNode;
  final bool enabled;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: AppBorders.md,
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: maxLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      inputFormatters: [
        if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
      ],
      style: context.textTheme.bodyMedium?.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.textTheme.bodyMedium?.copyWith(
          color: AppColors.textDisabled,
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.ms,
        ),
        border: border,
        enabledBorder: border,
        disabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Counter extends StatelessWidget {
  const _Counter(this.value, this.max);

  final int value;
  final int max;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$value/$max',
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
}

class _CategoryField extends StatelessWidget {
  const _CategoryField({required this.category, required this.onTap});

  final ArtworkCategoryModel? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppBorders.md,
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.ms,
          ),
          child: Row(
            children: [
              Icon(
                AppIcons.image,
                size: 20.r,
                color: AppColors.textPrimary,
              ),
              AppSpacing.hGap(AppSpacing.ms),
              Expanded(
                child: Text(
                  category?.name ?? 'Select category',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(
                AppIcons.chevronDown,
                color: AppColors.textPrimary,
                size: 22.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategorySheet extends ConsumerWidget {
  const _CategorySheet({this.selectedId});

  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(artworkCategoriesProvider);
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.5,
        child: switch (state) {
          RequestInitial() || RequestLoading() => const AppLoading(),
          RequestFailure(:final failure) => AppErrorWidget(
              message: failure.message,
              onRetry: () =>
                  ref.read(artworkCategoriesProvider.notifier).refresh(),
            ),
          RequestSuccess(:final data) when data.isEmpty => const Center(
              child: Text('No categories available'),
            ),
          RequestSuccess(:final data) => ListView(
              children: [
                for (final category in data)
                  ListTile(
                    title: Text(
                      category.name,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                    trailing: category.id == selectedId
                        ? const Icon(
                            AppIcons.check,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => Navigator.of(context).pop(category),
                  ),
              ],
            ),
        },
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.ms,
        right: AppSpacing.xs,
        top: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: AppBorders.xl,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(
              color: AppColors.secondary,
            ),
          ),
          InkResponse(
            onTap: onRemove,
            radius: 14.r,
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Icon(
                AppIcons.close,
                size: 14.r,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateToggle extends StatelessWidget {
  const _PrivateToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.ms,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppBorders.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.lock,
            color: AppColors.textPrimary,
            size: 22.r,
          ),
          AppSpacing.hGap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set as private',
                  style: context.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Only you can see this artwork',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          disabledForegroundColor: color.withValues(alpha: 0.5),
          side: BorderSide(color: color.withValues(alpha: 0.7)),
          shape: const RoundedRectangleBorder(borderRadius: AppBorders.md),
        ),
        child: isLoading
            ? SizedBox.square(
                dimension: 20.r,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.background,
          disabledBackgroundColor: AppColors.primaryPressed.withValues(
            alpha: 0.35,
          ),
          disabledForegroundColor: AppColors.textSecondary,
          shape: const RoundedRectangleBorder(borderRadius: AppBorders.md),
        ),
        child: isLoading
            ? SizedBox.square(
                dimension: 20.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.background,
                ),
              )
            : Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
