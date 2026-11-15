import '../../../../imports/imports.dart';

/// Ready-made empty states for the artwork domain.
abstract final class AppEmptyPresets {
  AppEmptyPresets._();

  static Widget noArtwork({VoidCallback? onCreate}) => AppEmptyState(
        icon: AppIcons.palette,
        title: LocaleKeys.states_no_artwork_title.tr(),
        subtitle: LocaleKeys.states_no_artwork_subtitle.tr(),
        actionLabel: LocaleKeys.states_create_artwork.tr(),
        onAction: onCreate,
      );

  static Widget noSaved({VoidCallback? onExplore}) => AppEmptyState(
        icon: AppIcons.bookmark,
        title: LocaleKeys.states_no_saved_title.tr(),
        subtitle: LocaleKeys.states_no_saved_subtitle.tr(),
        actionLabel: LocaleKeys.states_explore.tr(),
        onAction: onExplore,
      );

  static Widget noComments({VoidCallback? onComment}) => AppEmptyState(
        icon: AppIcons.comment,
        title: LocaleKeys.states_no_comments_title.tr(),
        subtitle: LocaleKeys.states_no_comments_subtitle.tr(),
        actionLabel: LocaleKeys.states_comment.tr(),
        onAction: onComment,
      );

  static Widget noResults({VoidCallback? onExplore}) => AppEmptyState(
        icon: AppIcons.searchOff,
        title: LocaleKeys.states_no_results_title.tr(),
        subtitle: LocaleKeys.states_no_results_subtitle.tr(),
        actionLabel: LocaleKeys.states_explore.tr(),
        onAction: onExplore,
      );
}

/// Ready-made error states for common failures.
abstract final class AppErrorPresets {
  AppErrorPresets._();

  static Widget network({VoidCallback? onRetry}) => AppErrorWidget(
        icon: AppIcons.wifiOff,
        title: LocaleKeys.states_network_error_title.tr(),
        message: LocaleKeys.states_network_error_message.tr(),
        onRetry: onRetry,
      );

  static Widget upload({VoidCallback? onRetry}) => AppErrorWidget(
        icon: AppIcons.cloudUpload,
        title: LocaleKeys.states_upload_error_title.tr(),
        message: LocaleKeys.states_upload_error_message.tr(),
        retryLabel: LocaleKeys.states_retry.tr(),
        onRetry: onRetry,
      );

  static Widget permission({VoidCallback? onBack}) => AppErrorWidget(
        icon: AppIcons.lock,
        title: LocaleKeys.states_permission_error_title.tr(),
        message: LocaleKeys.states_permission_error_message.tr(),
        retryLabel: LocaleKeys.states_go_back.tr(),
        onRetry: onBack,
      );
}
