import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/utils.dart';

/// A service to handle media selection (images, videos, files).
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera.
  FutureEither<File?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return runTask(
      () async {
        // Check permissions
        if (source == ImageSource.camera) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            throw Exception('Camera permission denied');
          }
        } else {
          if (Platform.isAndroid || Platform.isIOS) {
            final status = await Permission.photos.request();
            if (!status.isGranted && !status.isLimited) {
              throw Exception('Photos permission denied');
            }
          }
        }

        final XFile? file = await _imagePicker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );

        return file != null ? File(file.path) : null;
      },
      operation: 'media.pickImage',
      category: LogCategory.app,
      context: {'source': source.name},
    );
  }

  /// Copies a picked file out of the picker's cache, which the OS can clear
  /// before the file is used (e.g. an upload after a long form session).
  Future<File> persist(File file) async {
    final dir = await getApplicationSupportDirectory();
    final dot = file.path.lastIndexOf('.');
    final ext = dot == -1 ? '' : file.path.substring(dot);
    return file.copy(
      '${dir.path}${Platform.pathSeparator}pick_${DateTime.now().microsecondsSinceEpoch}$ext',
    );
  }

  /// Pick multiple images from gallery.
  FutureEither<List<File>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return runTask(
      () async {
        if (Platform.isAndroid || Platform.isIOS) {
          final status = await Permission.photos.request();
          if (!status.isGranted && !status.isLimited) {
            throw Exception('Photos permission denied');
          }
        }

        final List<XFile> files = await _imagePicker.pickMultiImage(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality,
        );

        return files.map((file) => File(file.path)).toList();
      },
      operation: 'media.pickMultiImage',
      category: LogCategory.app,
    );
  }

  /// Pick a video from gallery or camera.
  FutureEither<File?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    return runTask(
      () async {
        if (source == ImageSource.camera) {
          final status = await Permission.camera.request();
          if (!status.isGranted) {
            throw Exception('Camera permission denied');
          }
        } else {
          if (Platform.isAndroid || Platform.isIOS) {
            final status = await Permission.photos.request();
            if (!status.isGranted && !status.isLimited) {
              throw Exception('Photos permission denied');
            }
          }
        }

        final XFile? file = await _imagePicker.pickVideo(
          source: source,
          maxDuration: maxDuration,
        );

        return file != null ? File(file.path) : null;
      },
      operation: 'media.pickVideo',
      category: LogCategory.app,
      context: {'source': source.name},
    );
  }

  /// Pick one or more files from the device.
  FutureEither<List<File>> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    return runTask(
      () async {
        if (Platform.isAndroid) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            // Note: On Android 13+, storage permission might be handled differently (media-specific)
            // but permission_handler usually handles the abstraction.
          }
        }

        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: type,
          allowedExtensions: allowedExtensions,
          allowMultiple: allowMultiple,
        );

        if (result == null || result.files.isEmpty) return [];

        return result.paths
            .where((path) => path != null)
            .map((path) => File(path!))
            .toList();
      },
      operation: 'media.pickFiles',
      category: LogCategory.app,
    );
  }
}
