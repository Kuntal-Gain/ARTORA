import 'dart:ui' show lerpDouble;

import 'package:artora/src/features/auth/model/user_model.dart';
import 'package:artora/src/features/auth/presentation/providers/auth_providers.dart';
import 'package:artora/src/features/discover/model/artwork_model.dart';
import 'package:artora/src/features/discover/state/artwork_provider.dart';
import 'package:artora/src/features/discover/presentation/providers/follow_providers.dart';
import 'package:artora/src/imports/imports.dart';
import 'package:artora/src/services/supabase_storage_service.dart';

/// Profile content only. Keep your existing bottom navigation in the parent.
///
/// Shows the signed-in user's profile and artworks from the providers; images
/// that are missing (or still loading) fall back to styled placeholders.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({
    super.key,
    this.userId,
    // Space reserved so the last row clears the parent's floating bottom nav.
    this.bottomInset = 110,
    this.showBack = false,
    this.onBack,
    this.onMore,
    this.onEditProfile,
    this.onEditAvatar,
    this.onArtworkTap,
  });

  /// Whose profile to show; `null` is the signed-in user's own.
  final String? userId;

  final double bottomInset;

  /// Only for viewing another user's profile; the own-profile tab has no back.
  final bool showBack;
  final VoidCallback? onBack;
  final VoidCallback? onMore;
  final VoidCallback? onEditProfile;
  final VoidCallback? onEditAvatar;
  final ValueChanged<int>? onArtworkTap;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

enum _ProfileTab { artwork, collections }

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  _ProfileTab _selectedTab = _ProfileTab.artwork;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // Scroll distance over which the app bar collapses (expanded 128 - toolbar 56,
  // both scaled), so it must be scaled too or the avatar docks off-line.
  double get _collapseRange => 72.r;

  /// Avatar that shrinks and docks into the app bar next to the name.
  Widget _floatingAvatar(BuildContext context) {
    final status = MediaQuery.paddingOf(context).top;
    return AnimatedBuilder(
      animation: _scroll,
      builder: (context, _) {
        final offset = _scroll.hasClients ? _scroll.offset : 0.0;
        final t = (offset / _collapseRange).clamp(0.0, 1.0);
        final size = lerpDouble(96.r, 36.r, t)!;
        final dockedLeft = widget.showBack ? 66.r : 20.r;
        final left = lerpDouble(20.r, dockedLeft, t)!;
        // Scrolls with content until it reaches the toolbar, then stays docked.
        final top = status + (82.r - offset).clamp(10.r, double.infinity);
        return Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              child: _ProfileAvatar(
                size: size,
                showBadge: t < 0.3 && !_isOther,
                image: _avatarImage,
                onEdit: widget.onEditAvatar,
              ),
            ),
            Positioned(
              left: (widget.showBack ? 66.r : 20.r) + 36.r + 10.r,
              right: _isOther ? 20.r : 72.r,
              top: status,
              height: 56.r,
              child: IgnorePointer(
                child: Opacity(
                  opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        color: _ProfileColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Set at the top of build(); read by the scroll-driven avatar builder too.
  UserModel? _user;

  String get _displayName => _user?.displayName.trim() ?? '';

  String get _username => _user?.username.trim() ?? '';

  String? get _bio {
    final value = _user?.bio?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  List<String> get _specialties =>
      (_user?.specialties ?? const []).map(_titleCase).toList();

  ImageProvider? _storageImage(String bucket, String? path) {
    final url = SupabaseStorageService.instance.publicUrl(bucket, path);
    return url == null ? null : NetworkImage(url);
  }

  ImageProvider? get _avatarImage =>
      _storageImage(SupabaseBuckets.avatars, _user?.avatarPath);

  ImageProvider? get _coverImage =>
      _storageImage(SupabaseBuckets.banners, _user?.coverPath);

  // True when viewing someone else; set in build() like [_user].
  bool _isOther = false;

  Future<void> _refresh() async {
    final id = widget.userId;
    final user = id == null
        ? await ref.refresh(currentUserProvider.future)
        : await ref.refresh(userProfileProvider(id).future);
    if (user != null) {
      await ref.read(userArtworkFeedProvider(user.id).notifier).refresh();
    }
  }

  String _titleCase(String value) {
    return value
        .replaceAll('-', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _showSpecialties(List<String> specialties) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _ProfileColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.profile_specialties.tr(),
                style: context.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 16.r),
              Wrap(
                spacing: 8.r,
                runSpacing: 8.r,
                children: [
                  for (final item in specialties) _SpecialtyChip(label: item),
                ],
              ),
              SizedBox(height: 16.r),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.userId;
    _user = (id == null
            ? ref.watch(currentUserProvider)
            : ref.watch(userProfileProvider(id)))
        .value;
    _isOther = id != null && id != ref.watch(currentUserProvider).value?.id;
    final specialties = _specialties;
    final uid = _user?.id;
    final feed = uid == null
        ? const RequestLoading<ArtworkListModel>()
        : ref.watch(userArtworkFeedProvider(uid));
    final artworks = switch (feed) {
      RequestSuccess(:final data) => data.artworks,
      _ => const <ArtworkModel>[],
    };

    Widget message(String text) => SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32.r),
            child: Center(
              child: Text(
                text,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: _ProfileColors.secondary,
                ),
              ),
            ),
          ),
        );

    final Widget gallery = _selectedTab == _ProfileTab.collections
        ? message(LocaleKeys.profile_no_collections.tr())
        : switch (feed) {
            RequestInitial() || RequestLoading() => SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.r),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
            RequestFailure() => message(LocaleKeys.profile_load_failed.tr()),
            RequestSuccess() when artworks.isEmpty => message(
                LocaleKeys.profile_no_artworks.tr(),
              ),
            RequestSuccess() => SliverGrid.builder(
                itemCount: artworks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10.r,
                  crossAxisSpacing: 10.r,
                  childAspectRatio: 1.45,
                ),
                itemBuilder: (context, index) {
                  final art = artworks[index];
                  final url = art.images.isEmpty
                      ? null
                      : (art.images.first.thumbnailUrl ?? art.images.first.url);
                  return _GalleryTile(
                    image:
                        url == null || url.isEmpty ? null : NetworkImage(url),
                    variant: index + 2,
                    label: art.title,
                    // Own profile: tapping a tile opens it for editing.
                    onTap: widget.onArtworkTap != null
                        ? () => widget.onArtworkTap!(index)
                        : _isOther
                            ? () => context.push(
                                  AppRoutes.artworkDetailPath(art.id),
                                )
                            : () =>
                                context.push(AppRoutes.editArtworkPath(art.id)),
                  );
                },
              ),
          };

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _ProfileColors.canvas,
      ),
      child: Scaffold(
        backgroundColor: _ProfileColors.canvas,
        body: Stack(
          children: [
            RefreshIndicator(
              color: _ProfileColors.accent,
              backgroundColor: _ProfileColors.surface,
              edgeOffset: MediaQuery.paddingOf(context).top + 56.r,
              onRefresh: _refresh,
              child: CustomScrollView(
                controller: _scroll,
                // No bounce at the top: pulling down there only triggers refresh.
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                slivers: [
                  // Full-bleed cover (extends under the status bar). Buttons float on it.
                  SliverAppBar(
                    pinned: true,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                    toolbarHeight: 56.r,
                    expandedHeight:
                        128.r, // status-bar inset is added automatically
                    backgroundColor: _ProfileColors.canvas,
                    surfaceTintColor: Colors.transparent,
                    automaticallyImplyLeading: false,
                    leadingWidth: widget.showBack ? 72.r : 0,
                    leading: widget.showBack
                        ? Padding(
                            padding: EdgeInsets.only(left: 18.r),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _HeaderAction(
                                icon: AppIcons.back,
                                tooltip: LocaleKeys.common_back.tr(),
                                onTap: widget.onBack ??
                                    () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          )
                        : null,
                    actions: [
                      // The gear opens Settings, which only makes sense on
                      // your own profile.
                      if (!_isOther)
                        Padding(
                          padding: EdgeInsets.only(right: 18.r),
                          child: Center(
                            child: _HeaderAction(
                              icon: AppIcons.settings,
                              tooltip: LocaleKeys.settings_title.tr(),
                              onTap: widget.onMore,
                            ),
                          ),
                        ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ProfileMedia(
                            image: _coverImage,
                            variant: 0,
                            icon: AppIcons.landscape,
                            label: LocaleKeys.profile_cover_image.tr(),
                          ),
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: [0, 0.35, 1],
                                colors: [
                                  Color(0x66080611),
                                  Colors.transparent,
                                  Color(0x990B0A13),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Rounded profile card containing header, info and gallery.
                  DecoratedSliver(
                    decoration: BoxDecoration(
                      color: _ProfileColors.canvas,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(28.r)),
                      border: Border.all(color: _ProfileColors.cardBorder),
                    ),
                    sliver: SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: _ProfileHeader(
                            onEditProfile: widget.onEditProfile,
                            other: _isOther
                                ? _OtherActions(userId: widget.userId!)
                                : null,
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: 20.r),
                          sliver: SliverToBoxAdapter(
                            child: _ProfileInfo(
                              name: _displayName,
                              username: _username,
                              bio: _bio,
                              specialties: specialties,
                              onShowSpecialties: () =>
                                  _showSpecialties(specialties),
                              artworks: artworks.length,
                              userId: _user?.id,
                              followers: _user?.totalFollowers ?? 0,
                              followings: _user?.totalFollowings ?? 0,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(20.r, 16.r, 20.r, 0),
                          sliver: SliverToBoxAdapter(
                            child: _ProfileTabs(
                              selected: _selectedTab,
                              onSelected: (tab) {
                                if (tab != _selectedTab) {
                                  setState(() => _selectedTab = tab);
                                }
                              },
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            20.r,
                            14.r,
                            20.r,
                            widget.bottomInset.r,
                          ),
                          sliver: gallery,
                        ),
                      ],
                    ),
                  ),
                  // Short profiles (few artworks) would never scroll far enough
                  // to collapse the header, so pad the end up to that distance.
                  SliverLayoutBuilder(
                    builder: (context, constraints) => SliverToBoxAdapter(
                      child: SizedBox(
                        height: (constraints.viewportMainAxisExtent +
                                _collapseRange -
                                constraints.precedingScrollExtent)
                            .clamp(0.0, double.infinity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _floatingAvatar(context),
          ],
        ),
      ),
    );
  }
}

class _ProfileColors {
  static const canvas = Color(0xFF0D0C14);
  static const surface = Color(0xFF101015);
  static const border = Color(0xFF4A3B66);
  static const cardBorder = Color(0x26FFFFFF);
  static const text = Color(0xFFF8F6FF);
  static const secondary = Color(0xFFACA6BB);
  static const description = Color(0xFFD4CEDC);
  static const accent = Color(0xFFAE78F6);
  static const chipSurface = Color(0xFF1A1724);
  static const separator = Color(0xFF393445);
}

/// Avatar (overlapping the cover) + Edit Profile button row.
class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.onEditProfile, this.other});

  final VoidCallback? onEditProfile;

  /// Follow / Message buttons, shown instead of Edit Profile on other profiles.
  final Widget? other;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58.r,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 20.r,
            top: 14.r,
            child: other ?? _EditProfileButton(onTap: onEditProfile),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfo extends StatelessWidget {
  const _ProfileInfo({
    required this.name,
    required this.username,
    required this.bio,
    required this.specialties,
    required this.onShowSpecialties,
    required this.artworks,
    required this.followers,
    required this.followings,
    this.userId,
  });

  final String? userId;
  final String name;
  final String username;
  final String? bio;
  final List<String> specialties;
  final VoidCallback onShowSpecialties;
  final int artworks;
  final int followers;
  final int followings;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleLarge?.copyWith(
                  color: _ProfileColors.text,
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.r),
        Text(
          '@$username',
          style: context.textTheme.bodyMedium?.copyWith(
            color: _ProfileColors.secondary,
            fontSize: 13.sp,
          ),
        ),
        if (bio != null) ...[
          SizedBox(height: 10.r),
          Text(
            bio!,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyMedium?.copyWith(
              color: _ProfileColors.description,
              fontSize: 13.sp,
              height: 1.45,
            ),
          ),
        ],
        if (specialties.isNotEmpty) ...[
          SizedBox(height: 12.r),
          Wrap(
            spacing: 8.r,
            runSpacing: 8.r,
            children: [
              for (final s in specialties.take(4)) _SpecialtyChip(label: s),
              if (specialties.length > 4)
                _SpecialtyChip(label: '+', onTap: onShowSpecialties),
            ],
          ),
        ],
        SizedBox(height: 16.r),
        _ProfileStats(
          artworks: artworks,
          followers: followers,
          followings: followings,
          userId: userId,
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.tooltip, this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xB30B0A14),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0x33FFFFFF)),
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            height: 38.r,
            width: 38.r,
            child: Icon(icon, size: 22.r, color: _ProfileColors.text),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.size,
    required this.showBadge,
    this.image,
    this.onEdit,
  });

  final double size;
  final bool showBadge;
  final ImageProvider? image;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final s = size / 96.r;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            padding: EdgeInsets.all(3.r * s),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF4D8FF), Color(0xFFAE78F6)],
              ),
            ),
            child: Container(
              padding: EdgeInsets.all(2.r * s),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _ProfileColors.canvas,
              ),
              child: ClipOval(
                child: _ProfileMedia(
                  image: image,
                  variant: 1,
                  icon: AppIcons.person,
                ),
              ),
            ),
          ),
          if (showBadge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Material(
                color: _ProfileColors.accent,
                shape: CircleBorder(
                  side: BorderSide(color: _ProfileColors.canvas, width: 2.r),
                ),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onEdit,
                  child: SizedBox(
                    height: 32.r,
                    width: 32.r,
                    child: Icon(
                      AppIcons.edit,
                      size: 15.r,
                      color: const Color(0xFF160D24),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EditProfileButton extends StatelessWidget {
  const _EditProfileButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.r,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _ProfileColors.text,
          disabledForegroundColor: _ProfileColors.text,
          backgroundColor: const Color(0xFF1B1727),
          side: const BorderSide(color: _ProfileColors.border),
          padding: EdgeInsets.symmetric(horizontal: 22.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
        icon: Icon(AppIcons.edit, size: 16.r),
        label: Text(
          LocaleKeys.profile_edit_profile.tr(),
          maxLines: 1,
          style: context.textTheme.labelMedium?.copyWith(
            color: _ProfileColors.text,
            fontWeight: FontWeight.w700,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}

/// Follow toggle and Message button for another artist's profile.
class _OtherActions extends ConsumerWidget {
  const _OtherActions({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final following = ref.watch(followingProvider).contains(userId);
    final style = context.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 13.sp,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 40.r,
          child: OutlinedButton(
            // No messaging backend yet.
            onPressed: () => showGlobalToast(
              message: LocaleKeys.profile_messaging_soon.tr(),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _ProfileColors.text,
              backgroundColor: const Color(0xFF1B1727),
              side: const BorderSide(color: _ProfileColors.border),
              padding: EdgeInsets.symmetric(horizontal: 18.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(LocaleKeys.profile_message.tr(), style: style),
          ),
        ),
        SizedBox(width: 10.r),
        SizedBox(
          height: 40.r,
          child: FilledButton(
            onPressed: () =>
                ref.read(followingProvider.notifier).toggle(userId),
            style: FilledButton.styleFrom(
              backgroundColor:
                  following ? const Color(0xFF1B1727) : _ProfileColors.accent,
              foregroundColor:
                  following ? _ProfileColors.text : const Color(0xFF160D24),
              side: following
                  ? const BorderSide(color: _ProfileColors.border)
                  : null,
              padding: EdgeInsets.symmetric(horizontal: 22.r),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: Text(
              (following
                      ? LocaleKeys.discover_following
                      : LocaleKeys.discover_follow)
                  .tr(),
              style: style,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecialtyChip extends StatelessWidget {
  const _SpecialtyChip({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ProfileColors.chipSurface,
      shape: const StadiumBorder(
        side: BorderSide(color: _ProfileColors.border),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.r, vertical: 7.r),
          child: Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC99BFF),
              fontWeight: FontWeight.w600,
              fontSize: 11.5.sp,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileStats extends StatelessWidget {
  const _ProfileStats({
    required this.artworks,
    required this.followers,
    required this.followings,
    this.userId,
  });

  final int artworks;
  final int followers;
  final int followings;

  /// Whose followers / following the counts open; `null` until loaded.
  final String? userId;

  @override
  Widget build(BuildContext context) {
    final id = userId;
    return Row(
      children: [
        _Stat(
          value: formatCompact(artworks),
          label: LocaleKeys.profile_artworks.tr(),
        ),
        SizedBox(width: 28.r),
        _Stat(
          value: formatCompact(followers),
          label: LocaleKeys.profile_followers.tr(),
          onTap: id == null
              ? null
              : () => context.push(AppRoutes.artistConnectionsPath(id)),
        ),
        SizedBox(width: 28.r),
        _Stat(
          value: formatCompact(followings),
          label: LocaleKeys.discover_following.tr(),
          onTap: id == null
              ? null
              : () => context.push(
                    AppRoutes.artistConnectionsPath(id, following: true),
                  ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Column(
        children: [
          Text(
            value,
            style: context.textTheme.titleMedium?.copyWith(
              color: _ProfileColors.text,
              fontWeight: FontWeight.w800,
              fontSize: 17.sp,
              height: 1.2,
            ),
          ),
          SizedBox(height: 2.r),
          Text(
            label,
            style: context.textTheme.bodySmall?.copyWith(
              color: _ProfileColors.text.withValues(alpha: 0.8),
              fontSize: 12.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selected, required this.onSelected});

  final _ProfileTab selected;
  final ValueChanged<_ProfileTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(height: 1, color: _ProfileColors.separator),
        Row(
          children: [
            for (final tab in _ProfileTab.values)
              Expanded(
                child: InkWell(
                  onTap: () => onSelected(tab),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 6.r, bottom: 10.r),
                        child: Text(
                          (tab == _ProfileTab.artwork
                                  ? LocaleKeys.discover_artwork
                                  : LocaleKeys.profile_collections)
                              .tr(),
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: selected == tab
                                ? _ProfileColors.accent
                                : _ProfileColors.text,
                            fontWeight: selected == tab
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 3.r,
                        decoration: BoxDecoration(
                          color: selected == tab
                              ? _ProfileColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(3.r),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({
    required this.image,
    required this.variant,
    required this.label,
    this.onTap,
  });

  final ImageProvider? image;
  final int variant;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: AppBorders.shapeSm.borderRadius,
        border: Border.all(color: const Color(0x33C99BFF)),
      ),
      child: ClipRRect(
        borderRadius: AppBorders.shapeSm.borderRadius,
        child: Material(
          color: _ProfileColors.chipSurface,
          child: InkWell(
            onTap: onTap,
            child: _ProfileMedia(
              image: image,
              variant: variant,
              icon: AppIcons.image,
              label: label,
            ),
          ),
        ),
      ),
    );
  }
}

/// Replace this slot with a real image by passing [image].
class _ProfileMedia extends StatelessWidget {
  const _ProfileMedia({
    this.image,
    required this.variant,
    required this.icon,
    this.label,
  });

  final ImageProvider? image;
  final int variant;
  final IconData icon;
  final String? label;

  static const _gradients = <List<Color>>[
    [Color(0xFF191032), Color(0xFF71466F), Color(0xFFD37489)],
    [Color(0xFF4B3775), Color(0xFFA974B7), Color(0xFFD8ACD4)],
    [Color(0xFF4A347D), Color(0xFFAC5C9A), Color(0xFFF18AA5)],
    [Color(0xFF2A3770), Color(0xFF8C4C91), Color(0xFFD985B6)],
    [Color(0xFF8F80B2), Color(0xFFD9ABCA), Color(0xFF6D5D90)],
    [Color(0xFF4A2B29), Color(0xFFB37D59), Color(0xFFE6C49B)],
    [Color(0xFF33245C), Color(0xFF7A4A9D), Color(0xFFE77B95)],
    [Color(0xFF1D3F55), Color(0xFF5A7A94), Color(0xFF30334E)],
  ];

  @override
  Widget build(BuildContext context) {
    if (image != null) {
      return Image(
        image: image!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final palette = _gradients[variant % _gradients.length];
    return LayoutBuilder(
      builder: (context, constraints) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: palette,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              top: -constraints.maxHeight * 0.32,
              right: -constraints.maxWidth * 0.12,
              child: Container(
                width: constraints.maxWidth * 0.8,
                height: constraints.maxWidth * 0.8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x35FFFFFF),
                ),
              ),
            ),
            Center(
              child: Icon(
                icon,
                color: const Color(0xD9FFFFFF),
                size: constraints.maxHeight < 150 ? 33 : 48,
              ),
            ),
            if (label != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Text(
                    label!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: Color(0xE8FFFFFF),
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
