import '../../../../imports/imports.dart';

/// Ready-made empty states for the artwork domain.
abstract final class AppEmptyPresets {
  AppEmptyPresets._();

  static Widget noArtwork({VoidCallback? onCreate}) => AppEmptyState(
        icon: AppIcons.palette,
        title: 'No Artwork Yet',
        subtitle: 'Share your first artwork with the community.',
        actionLabel: 'Create Artwork',
        onAction: onCreate,
      );

  static Widget noSaved({VoidCallback? onExplore}) => AppEmptyState(
        icon: AppIcons.bookmark,
        title: 'No Saved Artwork',
        subtitle: 'Save artwork you love and get back to it anytime.',
        actionLabel: 'Explore',
        onAction: onExplore,
      );

  static Widget noComments({VoidCallback? onComment}) => AppEmptyState(
        icon: AppIcons.comment,
        title: 'No Comments Yet',
        subtitle: 'Be the first to share your thoughts.',
        actionLabel: 'Comment',
        onAction: onComment,
      );

  static Widget noResults({VoidCallback? onExplore}) => AppEmptyState(
        icon: AppIcons.searchOff,
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
        icon: AppIcons.wifiOff,
        title: 'Network Error',
        message: 'Something went wrong. Please check your connection.',
        onRetry: onRetry,
      );

  static Widget upload({VoidCallback? onRetry}) => AppErrorWidget(
        icon: AppIcons.cloudUpload,
        title: 'Upload Error',
        message: 'Failed to upload artwork. Please try again.',
        retryLabel: 'Retry',
        onRetry: onRetry,
      );

  static Widget permission({VoidCallback? onBack}) => AppErrorWidget(
        icon: AppIcons.lock,
        title: 'Permission Error',
        message: "You don't have permission to perform this action.",
        retryLabel: 'Go Back',
        onRetry: onBack,
      );
}
