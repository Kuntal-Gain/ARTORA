import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:artora/src/imports/imports.dart';
import 'package:image_cropper/image_cropper.dart';

/// How the picked image is shaped before it's used.
enum _Shape { original, fit, square, standard, wide, manual }

/// Full-screen look at the picked image before it's used, with crop presets
/// (1:1, 4:3, 16:9), Original, Fit (whole image on a square canvas) and Manual
/// (free-form crop). Pops with the chosen [File] on Continue; Replace picks
/// another one.
class ArtworkImagePreviewScreen extends StatefulWidget {
  const ArtworkImagePreviewScreen({super.key, required this.file});

  final File file;

  @override
  State<ArtworkImagePreviewScreen> createState() =>
      _ArtworkImagePreviewScreenState();
}

class _ArtworkImagePreviewScreenState extends State<ArtworkImagePreviewScreen> {
  /// Longest side of the Fit canvas; keeps the PNG a sensible size.
  static const int _fitMaxSide = 2048;

  /// The picked image, untouched: every shape is made from this, so switching
  /// shapes never stacks crops.
  late File _source = widget.file;

  /// What Continue returns.
  late File _file = widget.file;

  _Shape _shape = _Shape.original;
  bool _busy = false;

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
    if (!mounted) return;
    setState(() {
      _source = saved;
      _file = saved;
      _shape = _Shape.original;
    });
  }

  Future<void> _select(_Shape shape) async {
    if (_busy || shape == _shape) return;

    final File? result;
    try {
      setState(() => _busy = true);
      result = switch (shape) {
        _Shape.original => _source,
        _Shape.fit => await _padToSquare(_source),
        _Shape.square => await _crop(const CropAspectRatio(ratioX: 1, ratioY: 1)),
        _Shape.standard =>
          await _crop(const CropAspectRatio(ratioX: 4, ratioY: 3)),
        _Shape.wide => await _crop(const CropAspectRatio(ratioX: 16, ratioY: 9)),
        _Shape.manual => await _crop(null),
      };
    } on Object catch (e, stack) {
      // Always log the real cause; the toast shows it too in debug builds.
      AppLogger.error('Image crop failed', error: e, stackTrace: stack);
      showGlobalToast(
        message: kDebugMode
            ? '${LocaleKeys.preview_crop_crop_failed.tr()} $e'
            : LocaleKeys.preview_crop_crop_failed.tr(),
        status: 'error',
      );
      return;
    } finally {
      if (mounted) setState(() => _busy = false);
    }

    // null: the crop screen was cancelled, keep what we had.
    if (result == null || !mounted) return;
    setState(() {
      _file = result!;
      _shape = shape;
    });
  }

  /// Opens the native crop screen; [ratio] null means free-form (Manual).
  Future<File?> _crop(CropAspectRatio? ratio) async {
    final locked = ratio != null;
    final cropped = await ImageCropper().cropImage(
      sourcePath: _source.path,
      aspectRatio: ratio,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: LocaleKeys.preview_title.tr(),
          toolbarColor: AppColors.background,
          toolbarWidgetColor: AppColors.textPrimary,
          statusBarLight: false,
          backgroundColor: AppColors.background,
          activeControlsWidgetColor: AppColors.primary,
          lockAspectRatio: locked,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: LocaleKeys.preview_title.tr(),
          aspectRatioLockEnabled: locked,
          resetAspectRatioEnabled: !locked,
          aspectRatioPickerButtonHidden: true,
        ),
      ],
    );
    if (cropped == null) return null;
    return MediaService.instance.persist(File(cropped.path));
  }

  /// Draws the whole image, centred, on a square canvas in the app's
  /// background colour, so nothing is cut off. Saved as PNG (only lossless
  /// output `dart:ui` can encode).
  Future<File> _padToSquare(File source) async {
    final codec = await ui.instantiateImageCodec(await source.readAsBytes());
    final image = (await codec.getNextFrame()).image;

    final side = math.max(image.width, image.height).toDouble();
    final double scale = math.min(1, _fitMaxSide / side);
    final canvasSide = side * scale;
    final w = image.width * scale;
    final h = image.height * scale;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, canvasSide, canvasSide),
      ui.Paint()..color = AppColors.background,
    );
    canvas.drawImageRect(
      image,
      ui.Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      ui.Rect.fromLTWH((canvasSide - w) / 2, (canvasSide - h) / 2, w, h),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    final side2 = canvasSide.round();
    final out = await recorder.endRecording().toImage(side2, side2);
    final bytes = await out.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    out.dispose();
    if (bytes == null) throw const FormatException('Could not encode image');

    final file = File(
      '${Directory.systemTemp.path}/fit_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List());
    return MediaService.instance.persist(file);
  }

  @override
  Widget build(BuildContext context) {
    final options = <(_Shape, IconData?, String)>[
      (_Shape.original, AppIcons.original, LocaleKeys.preview_original.tr()),
      (_Shape.fit, AppIcons.fit, LocaleKeys.preview_fit.tr()),
      (_Shape.square, null, '1:1'),
      (_Shape.standard, null, '4:3'),
      (_Shape.wide, null, '16:9'),
      (_Shape.manual, AppIcons.fill, LocaleKeys.preview_crop_manual.tr()),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: AppColors.transparent,
        centerTitle: true,
        leading: IconButton(
          tooltip: LocaleKeys.common_back.tr(),
          icon: const Icon(AppIcons.back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          LocaleKeys.preview_title.tr(),
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _busy ? null : _replace,
            child: Text(
              LocaleKeys.preview_replace.tr(),
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Always the whole result, never stretched or cut.
                        Image.file(_file, fit: BoxFit.contain),
                        if (_busy)
                          const ColoredBox(
                            color: Color(0x66000000),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                      ],
                    ),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (shape, icon, label) in options)
                        Padding(
                          padding: EdgeInsets.only(right: AppSpacing.xs),
                          child: SizedBox(
                            width: 68.w,
                            child: _ModeButton(
                              icon: icon,
                              label: label,
                              selected: _shape == shape,
                              onTap: _busy ? null : () => _select(shape),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              AppSpacing.vGap(AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: FilledButton(
                  onPressed: _busy ? null : () => context.pop(_file),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    shape: const RoundedRectangleBorder(
                      borderRadius: AppBorders.md,
                    ),
                  ),
                  child: Text(
                    LocaleKeys.preview_continue_button.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w600),
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
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  /// `null` for the ratio presets, which show their ratio as the main text.
  final IconData? icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

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
              if (icon != null)
                Icon(icon, color: color, size: 22.r)
              else
                SizedBox(
                  height: 22.r,
                  child: Center(
                    child: Text(
                      label,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              AppSpacing.vGap(AppSpacing.xs),
              Text(
                icon != null ? label : ' ',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
