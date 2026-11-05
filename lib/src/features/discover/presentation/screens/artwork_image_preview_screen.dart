import 'dart:io';

import 'package:artora/src/imports/imports.dart';

enum _PreviewMode { fit, fill, original }

/// Full-screen look at the picked image before it's used.
/// Pops with the chosen [File] on Continue; Replace picks another one.
class ArtworkImagePreviewScreen extends StatefulWidget {
  const ArtworkImagePreviewScreen({super.key, required this.file});

  final File file;

  @override
  State<ArtworkImagePreviewScreen> createState() =>
      _ArtworkImagePreviewScreenState();
}

class _ArtworkImagePreviewScreenState extends State<ArtworkImagePreviewScreen> {
  late File _file = widget.file;
  _PreviewMode _mode = _PreviewMode.fit;

  Future<void> _replace() async {
    final result = await MediaService.instance.pickImage(
      source: ImageSource.gallery,
    );
    final picked = result.fold((failure) {
      showGlobalToast(message: failure.message, status: 'error');
      return null;
    }, (file) => file);
    if (picked == null) return;
    final saved = await MediaService.instance.persist(picked);
    if (mounted) setState(() => _file = saved);
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      _file,
      fit: switch (_mode) {
        _PreviewMode.fit => BoxFit.contain,
        _PreviewMode.fill => BoxFit.cover,
        _PreviewMode.original => BoxFit.none,
      },
      width: double.infinity,
      height: double.infinity,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Preview',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _replace,
            child: Text(
              'Replace',
              style: context.textTheme.titleSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.pagePadding,
            AppSpacing.sm,
            AppSpacing.pagePadding,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: AppBorders.lg,
                  child: ColoredBox(
                    color: AppColors.surface,
                    // Original size can exceed the frame; let it be panned.
                    child: _mode == _PreviewMode.original
                        ? InteractiveViewer(
                            constrained: false,
                            child: Image.file(_file),
                          )
                        : image,
                  ),
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),
              Container(
                padding: EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppBorders.lg,
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    for (final (mode, icon, label) in [
                      (_PreviewMode.fit, Icons.fit_screen_outlined, 'Fit'),
                      (_PreviewMode.fill, Icons.crop_free_rounded, 'Fill'),
                      (
                        _PreviewMode.original,
                        Icons.photo_size_select_actual_outlined,
                        'Original',
                      ),
                    ])
                      Expanded(
                        child: _ModeButton(
                          icon: icon,
                          label: label,
                          selected: _mode == mode,
                          onTap: () => setState(() => _mode = mode),
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: () => context.pop(_file),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppBorders.md,
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return Material(
      color: selected
          ? AppColors.primary.withValues(alpha: 0.12)
          : AppColors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppBorders.md,
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.transparent,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22.r),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
