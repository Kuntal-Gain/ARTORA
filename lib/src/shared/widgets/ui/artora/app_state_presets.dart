import '../../../../imports/imports.dart';

/// Ready-made empty states for the artwork domain.
abstract final class AppEmptyPresets {
  AppEmptyPresets._();

  static Widget noArtwork({VoidCallback? onCreate}) => AppEmptyState(
        icon: Icons.palette_outlined,
        title: 'No Artwork Yet',
        subtitle: 'Share your first artwork with the community.',
        actionLabel: 'Create Artwork',
        onAction: onCreate,
      );

  static Widget noSaved({VoidCallback? onExplore}) => AppEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No Saved Artwork',
        subtitle: 'Save artwork you love and get back to it anytime.',
        actionLabel: 'Explore',
        onAction: onExplore,
      );

  static Widget noComments({VoidCallback? onComment}) => AppEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No Comments Yet',
        subtitle: 'Be the first to share your thoughts.',
        actionLabel: 'Comment',
        onAction: onComment,
      );

  static Widget noResults({VoidCallback? onExplore}) => AppEmptyState(
        icon: Icons.search_off_rounded,
        title: 'No Results Found',
        subtitle: 'Try a different search term or explore categories.',
        actionLabel: 'Explore',
        onAction: onExplore,
      );
}

/// Ready-made error states for common failures.
abstract final class AppErrorPresets {
  AppErrorPresets._();

  static Widget network({VoidCallback? onRetry}) => AppErrorWidget(
        icon: Icons.wifi_off_rounded,
        title: 'Network Error',
        message: 'Something went wrong. Please check your connection.',
        onRetry: onRetry,
      );

  static Widget upload({VoidCallback? onRetry}) => AppErrorWidget(
        icon: Icons.cloud_upload_outlined,
        title: 'Upload Error',
        message: 'Failed to upload artwork. Please try again.',
        retryLabel: 'Retry',
        onRetry: onRetry,
      );

  static Widget permission({VoidCallback? onBack}) => AppErrorWidget(
        icon: Icons.lock_outline_rounded,
        title: 'Permission Error',
        message: "You don't have permission to perform this action.",
        retryLabel: 'Go Back',
        onRetry: onBack,
      );
}
