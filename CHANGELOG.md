# Changelog

Maintained by Claude Code after each task; format is defined in [CLAUDE.md](CLAUDE.md#changelog-changelogmd).

## Unreleased

### fix: "Blocked" chip moves beside the name
The chip now sits next to the person's name (search results, artwork page, follower lists, feed cards) instead of next to the Unblock button.

- `lib/src/shared/widgets/ui/artora/app_artist_row.dart` — `fix`: chip beside the name
- `lib/src/features/discover/presentation/widgets/artwork_tile.dart`, `lib/src/features/discover/presentation/screens/artwork_detail_screen.dart`, `lib/src/features/profile/presentation/screens/follow_list_screen.dart` — `add`: chip beside the name
- `lib/src/features/discover/presentation/widgets/follow_button.dart` — `fix`: chip removed from beside the button

**Notes:**
- Explore artist cards are too narrow for a chip and still show only Unblock.

**Commit:** `fix: show blocked chip beside the name`

### feat: "Blocked" chip beside the Unblock button
A small red "Blocked" chip now sits next to the Unblock button in search results and on the artwork page. Feed cards, Explore artists and the narrow follower-list buttons have no room, so they show Unblock only.

- `lib/src/shared/widgets/ui/artora/app_blocked_chip.dart` — `add`: `AppBlockedChip`
- `lib/src/shared/widgets/ui/artora/app_artist_row.dart`, `lib/src/features/discover/presentation/widgets/follow_button.dart` — `fix`: chip beside Unblock
- `lib/src/shared/widgets/ui/artora/artora.dart` — `fix`: export
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `block.blocked_chip`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Commit:** `feat: add blocked chip beside unblock button`

### fix: blocked people show Unblock instead of Follow everywhere
Wherever a Follow button appeared for someone you blocked (feed cards, Explore artists, search results, artwork page, follower lists), it is now an Unblock button.

- `lib/src/features/discover/presentation/providers/block_providers.dart` — `add`: `unblockWithToast`
- `lib/src/features/discover/presentation/widgets/follow_button.dart` — `fix`: Unblock button for blocked users
- `lib/src/features/discover/presentation/widgets/artwork_tile.dart` — `fix`: `FollowPill` / `ArtworkTile` take `blocked` / `isBlocked` and `onUnblock`
- `lib/src/features/discover/presentation/widgets/artwork_masonry.dart`, `explore_widgets.dart`, `lib/src/features/discover/presentation/screens/explore_screen.dart`, `search_screen.dart` — `fix`: pass the blocked state and unblock action
- `lib/src/shared/widgets/ui/artora/app_artist_row.dart` — `add`: `isBlocked` / `onUnblock`

**Commit:** `fix: show unblock instead of follow for blocked users`

### fix: 404 page illustration sizing and button position
The SVG now gets an explicit size (it has none of its own) and falls back to a broken-image icon, with the cause logged, if it can't load. The Go to Home button is lifted well off the bottom edge.

- `lib/src/routing/not_found_screen.dart` — `fix`: `SvgPicture` width, `errorBuilder`, bottom padding 48

**Commit:** `fix: size 404 illustration and lift the button`

### fix: 404 page layout (app bar, centred illustration, bottom button)
The Page not found screen now has an app bar (title, back button when there is a previous page), the illustration centred in the body with the message under it, and the Go to Home button pinned to the bottom.

- `lib/src/routing/not_found_screen.dart` — `fix`: new layout

**Commit:** `fix: lay out 404 page with app bar and bottom button`

### feat: 404 page
Any location that doesn't exist (bad deep link, mistyped path) now shows a "Page not found" screen with the `404.svg` illustration in the centre, a short message and a Go to Home button.

- `lib/src/routing/not_found_screen.dart` — `add`: `NotFoundScreen`
- `lib/src/routing/app_router.dart` — `fix`: `errorBuilder` shows `NotFoundScreen`
- `lib/src/shared/app_assets.dart` — `add`: `notFound`
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `not_found.*`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Commit:** `feat: add 404 page`

### feat: Blocked Users screen
Settings → Blocked Users lists the people you blocked (avatar, name, @username) with an Unblock button; tapping a row opens their profile. Empty, loading and error states included.

- `lib/src/features/profile/presentation/screens/blocked_users_screen.dart` — `add`: the screen
- `lib/src/routing/app_routes.dart`, `app_router.dart` — `add`: `blockedUsers` route
- `lib/src/features/profile/presentation/screens/settings_screen.dart` — `fix`: Blocked Users row opens the screen
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `block.unblock`, `none_title`, `none_subtitle`, `load_failed`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Commit:** `feat: add blocked users screen`

### fix: other profiles use the same empty artworks / collections state
Someone else's empty Artwork and Collections tabs now show the same illustrated empty state as your own, without the create button, and with a hint written for a visitor ("They haven't shared any artwork yet.").

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: `_ProfileEmpty` action is optional; `empty()` uses it for every profile and drops the CTA on others
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `profile.other_empty_artworks_hint`, `profile.other_empty_collections_hint`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Commit:** `fix: reuse empty state on other profiles without create button`

### fix: Message / Follow buttons no longer overlap the avatar on other profiles
The two buttons were as wide as their labels and could slide under the avatar. They now share only the space to the right of it (equal widths), on blocked and normal profiles alike. The avatar is unchanged.

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: `_ProfileHeader` places the other-profile buttons between the avatar and the right margin; `_OtherActions` uses two `Expanded` buttons; `_LockedButton` padding trimmed

**Commit:** `fix: keep profile action buttons clear of the avatar`

### feat: blocked profile looks blocked
When you've blocked someone, their profile shows locked Follow and Message buttons (tapping says to unblock first) and a "This user is blocked" notice in place of their posts and collections. Unblock from the ⋮ menu.

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `add`: `_LockedButton`, `_BlockedNotice`; `fix`: `_OtherActions` takes `blocked`; artworks and collections tabs show the notice when blocked
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `block.user_is_blocked`, `block.blocked_hint`, `block.unblock_first`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Commit:** `feat: show blocked state on profile`

### fix: the profile menu reliably shows Unblock user for blocked people
Block / Unblock was decided from a list that could still be loading or stale. It now comes from `blockedIdsProvider`, which flips instantly when you block or unblock (and rolls back with an error toast if the server refuses).

- `lib/src/features/discover/presentation/providers/block_providers.dart` — `fix`: `blockedIdsProvider` (optimistic set of blocked ids, refreshes feeds / explore / saved / follows after a change); `removed`: `BlockActionsNotifier` / `blockActionsProvider`
- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: menu reads `blockedIdsProvider`; `_setBlocked` toasts only after a change that stuck

**Commit:** `fix: show unblock option for blocked users`

### fix: blocking is one-way (the blocker still sees the blocked person)
When A blocks B, A can still see B; only B loses sight of A (profile, artworks, comments), can't follow A, and can't comment on A's artworks. Before, both lost sight of each other and the profile closed after blocking.

- `supabase/blocks.sql` — `fix`: `has_blocked_me` replaces the two-way `has_block_between`; hiding policies now hide the blocker from the blocked only; `list_blocked_users` is a plain join (re-running this file replaces the old policies)
- `lib/src/network/constants/supabase_tables.dart` — `fix`: `SupabaseRpc.hasBlockedMe` replaces `hasBlockBetween`
- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: stays on the profile after blocking; the ⋮ menu shows Block user or Unblock user
- `assets/translations/en.json`, `assets/translations/ja.json` — `fix`: dialog message; `add`: `block.unblock_user`, `block.user_unblocked`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Run `supabase/blocks.sql` again if you already ran the earlier version.

**Commit:** `fix: make blocking one-way`

### feat: block user from another person's profile
On someone else's profile, a ⋮ button on the cover opens a small menu with "Block user"; choosing it asks for confirmation in a dialog, then blocks them, shows a toast and leaves the profile.

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `add`: ⋮ cover button (other profiles only), `_showUserMenu`, `_confirmBlock`, result listener
- `lib/src/shared/widgets/ui/artora/app_dialog_presets.dart` — `add`: `blockUser`
- `lib/src/features/discover/presentation/providers/block_providers.dart` — `fix`: missing imports
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `block.*`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Needs `supabase/blocks.sql` run first.

**Commit:** `feat: add block user menu to profile`

### feat: block users use case and providers
`blockUser`, `unblockUser` and `getBlockedUsers` on the discover use case, plus providers for the blocked list and for block / unblock actions. No screens yet.

- `lib/src/features/discover/model/blocked_user_model.dart` — `add`: `BlockedUserModel`
- `lib/src/features/discover/data/discover_usecase.dart`, `discover_usecase_impl.dart` — `add`: `blockUser` (idempotent), `unblockUser`, `getBlockedUsers`
- `lib/src/features/discover/presentation/providers/block_providers.dart` — `add`: `blockedUsersProvider`, `BlockActionsNotifier` / `blockActionsProvider` (refreshes feeds, explore, saved, follows, profile data after a change)

**Notes:**
- Needs `supabase/blocks.sql` run first.
- Still to build: Block button on profiles and the Blocked Users screen (Settings row still says coming soon).

**Commit:** `feat: add block users usecase and providers`

### wip: block users (database only)
Table, row level security, follow cleanup and hide-each-other rules for blocked users. No app screens yet.

- `supabase/blocks.sql` — `add`: `blocked_users` table and RLS, `has_block_between`, follow-removal trigger, restrictive policies on `profiles` / `artworks` / `comments` / `follows`, `list_blocked_users`
- `lib/src/network/constants/supabase_tables.dart` — `add`: `SupabaseRpc.listBlockedUsers`, `hasBlockBetween` (`SupabaseTables.blockedUsers` already existed)

**Notes:**
- Run `supabase/blocks.sql` only when the app side is ready: it changes what every user can see (blocked pairs disappear from each other).
- Still missing: app screens (block button on profiles, Blocked Users list), and `get_explore` / `get_user_by_id` still return blocked people (SECURITY DEFINER skips RLS).

**Commit:** `wip: add blocked users table and rls`

### feat: Account Settings (email view-only, change password, active sessions)
Settings → Account Settings opens a screen with the email (read-only), a change-password form that checks the current password first, and the list of devices signed in to the account with per-device and "all other devices" sign-out.

- `supabase/account.sql` — `add`: `verify_my_password`, `list_my_sessions`, `revoke_my_session` (own sessions only, SECURITY DEFINER)
- `lib/src/features/auth/presentation/screens/account_settings_screen.dart` — `add`: the screen
- `lib/src/features/auth/model/account_session.dart` — `add`: `AccountSession`
- `lib/src/services/auth_service.dart` — `add`: `verifyPassword`, `updatePassword`, `signOutOtherDevices`, `listSessions`, `revokeSession`
- `lib/src/features/auth/data/auth_usecase.dart`, `auth_usecase_impl.dart` — `add`: `changePassword` (verify, update, then sign other devices out), `listSessions`, `revokeSession`, `signOutOtherDevices`
- `lib/src/features/auth/presentation/providers/auth_providers.dart` — `add`: `changePasswordProvider`, `accountSessionsProvider`, `sessionActionsProvider`
- `lib/src/shared/widgets/ui/artora/app_dialog_presets.dart` — `add`: `signOutDevice`, `signOutOtherDevices`
- `lib/src/network/constants/supabase_tables.dart` — `add`: `SupabaseRpc.verifyMyPassword`, `listMySessions`, `revokeMySession`
- `lib/src/routing/app_routes.dart`, `app_router.dart` — `add`: `accountSettings` route
- `lib/src/features/profile/presentation/screens/settings_screen.dart` — `fix`: Account Settings row opens the screen
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `account_settings.*`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Run `supabase/account.sql` first; without it the password check and the session list fail.
- A device signed out from the list keeps working until its short access token expires (up to about an hour).
- Sessions from the app all report "Dart/…" as their user agent, so they show as "Artora app"; the device model isn't available.
- If Supabase has "Secure password change" on, it may ask the user to sign in again before changing the password.

**Commit:** `feat: add account settings screen`

### fix: remove image width/height columns (broke the feed)
The feed asked for `artwork_images.width` / `height`, which don't exist unless an extra SQL file is run, so every feed request failed. Tiles render the image at its natural height, so those columns aren't needed; the whole feature is removed and no SQL is required.

- `lib/src/features/discover/data/discover_helper.dart` — `removed`: `width,height` in the image select, `_imageSize`, and the size sent on upload
- `lib/src/features/discover/model/artwork_model.dart` — `removed`: `ArtworkImageModel.width` / `height` / `aspectRatio`
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `fix`: `aspectRatio` back to a neutral 1 (loading box only)
- `supabase/artwork_image_size.sql` — `removed`: not needed

**Notes:**
- If you already ran the old SQL, nothing breaks; the extra columns are just unused.

**Commit:** `fix: drop image size columns that broke the feed`

### fix: feed tiles render the image at its natural height
Tiles no longer force a box: the image fills the tile width and its own shape sets the height, so the masonry works for every image, including ones with no saved size. The saved size now only holds space while the image loads and balances the two columns.

- `lib/src/features/discover/presentation/widgets/artwork_tile.dart` — `fix`: removed the fixed `AspectRatio` / `BoxFit.cover`; image uses `BoxFit.fitWidth`; `_ImageBox` placeholder / error box
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `fix`: removed the 0.6–1.8 clamp on `aspectRatio`

**Notes:**
- Old images (no saved size) start as a square placeholder and change height once loaded.

**Commit:** `fix: render feed images at natural height`

### fix: masonry feed uses each image's real shape
Every tile was forced to a 1:1 box because the app never knew the image size. The size is now saved on upload and the tile uses it (kept between 0.6 and 1.8 so extreme images can't dominate the grid).

- `supabase/artwork_image_size.sql` — `add`: `width` / `height` columns on `artwork_images`
- `lib/src/features/discover/data/discover_helper.dart` — `add`: `_imageSize` (reads size from the file header), `width` / `height` saved on upload and fetched with the images
- `lib/src/features/discover/model/artwork_model.dart` — `add`: `ArtworkImageModel.width` / `height` / `aspectRatio`
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `fix`: `_toArtwork` uses the first image's ratio instead of a fixed 1

**Notes:**
- Run `supabase/artwork_image_size.sql` BEFORE using the app: new uploads send `width` / `height`, which fails if the columns don't exist.
- Existing artworks have no size, so they stay square until they are re-uploaded.

**Commit:** `fix: lay out feed tiles by real image aspect ratio`

### feat: image shapes in the artwork preview (1:1, 4:3, 16:9, Original, Fit, Manual)
The picked image can now actually be reshaped before upload (before, the preview only changed how it was displayed). Original keeps the file; Fit puts the whole image on a square canvas; 1:1 / 4:3 / 16:9 open a locked-ratio crop; Manual opens a free-form crop. Every shape is made from the original pick, so switching doesn't stack crops.

- `lib/src/features/discover/presentation/screens/artwork_image_preview_screen.dart` — `fix`: shape bar (scrollable), `image_cropper` crop screen, `_padToSquare` for Fit (PNG, longest side capped at 2048), busy state, cancelled crop keeps the previous result
- `pubspec.yaml` — `add`: `image_cropper`
- `android/app/src/main/AndroidManifest.xml` — `add`: `UCropActivity` (required by image_cropper)
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `preview_crop.manual`, `preview_crop.crop_failed`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Needs a full rebuild (new native plugin), not hot reload.
- Cropped images are saved as JPEG; Fit is PNG.
- Crop screen is the native one (uCrop on Android, TOCropViewController on iOS), so its look can't fully match the app.

**Commit:** `feat: add crop and aspect presets to image preview`

### refactor: table names come from SupabaseTables
Removed hardcoded table names from the discover feature; they are read from `SupabaseTables`.

- `lib/src/network/constants/supabase_tables.dart` — `fix`: `bookmarks` (unused) replaced by `savedArtworks = 'saved_artworks'`
- `lib/src/features/discover/data/discover_helper.dart` — `removed`: `likesTable` and `bookmarksTable` strings; uses `SupabaseTables.likes` / `savedArtworks`
- `lib/src/features/discover/data/discover_usecase_impl.dart` — `fix`: uses `SupabaseTables`
- `lib/src/features/discover/presentation/providers/discover_providers.dart`, `lib/src/features/discover/state/comments_provider.dart` — `fix`: realtime subscriptions use `SupabaseTables.likes` / `comments`

**Commit:** `refactor: use SupabaseTables for table names`

### feat: save / unsave artworks (private saved list)
Tapping save puts an artwork in your own saved list (own work of any visibility, or anyone's public work); tapping again removes it. The Saved screen loads your list from the server instead of filtering the For You page.

- `lib/src/features/discover/data/discover_helper.dart` — `fix`: saved table is now `saved_artworks`; `add`: `setRelation` (idempotent save / unsave), `getSavedIds`
- `lib/src/features/discover/data/discover_usecase.dart`, `discover_usecase_impl.dart` — `add`: `setSaved`, `getSavedIds`
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `fix`: `bookmarkedProvider` loads all my saved ids, saves via `setSaved`, refreshes the saved list after each change; `savedArtworksProvider` fetches `getUserSavedArtworks`; both reset on sign-out
- `lib/src/features/discover/presentation/screens/saved_screen.dart` — `fix`: shows the server list, drops unsaved cards immediately, retry reloads it

**Notes:**
- Run `supabase/saved_artworks.sql` first (it also copies rows from `artwork_bookmarks`).
- Saved list is the first page only (same as other lists).
- Likes and following state are still not reset on sign-out.

**Commit:** `feat: add private saved artworks toggle`

### feat: swipeable For You / Following tabs
The home feed uses `TabBar` + `TabBarView`, so the two feeds can be swiped as well as tapped. Each page has its own pull-to-refresh and keeps its scroll position.

- `lib/src/features/discover/presentation/screens/home_feed_screen.dart` — `fix`: `TabBar` / `TabBarView` with a `_FeedTab` page per feed; replaces `UnderlineTabs` and the `_showFollowing` flag

**Notes:**
- The top bar, search bar and tabs now stay fixed while a feed scrolls (they used to scroll away with the content).
- `UnderlineTabs` is still used by the follow list screen.

**Commit:** `feat: make home feed tabs swipeable`

### fix: no Follow button on your own work
Your own artworks and your own name in search no longer show Follow.

- `lib/src/features/discover/presentation/widgets/artwork_masonry.dart` — `fix`: feed tiles hide the Follow pill when the artist is you
- `lib/src/features/discover/presentation/screens/search_screen.dart` — `fix`: artist row hides Follow for you
- `lib/src/features/discover/presentation/screens/artwork_detail_screen.dart` — `fix`: artist row hides Follow on your own artwork
- `lib/src/network/client/sb_client.dart` — `fix`: explicit type on the `rpcRows` call
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `removed`: unused import

**Commit:** `fix: hide follow on own posts`

### feat: following feed from the server
`getFollowingPosts()` returns an `ArtworkListModel` of public artworks from followed artists, using the `get_following_feed` RPC. The home Following tab now uses it instead of filtering the already-loaded For You page, so it no longer misses followed artists' older work.

- `supabase/following_feed.sql` — `add`: `get_following_feed(page_limit, page_offset)` function and index
- `lib/src/network/client/sb_client.dart` — `add`: `rpcRows` (RPC returning table rows, shaped with embedded columns)
- `lib/src/network/constants/supabase_tables.dart` — `add`: `SupabaseRpc.getFollowingFeed`
- `lib/src/features/discover/data/discover_usecase.dart`, `discover_usecase_impl.dart` — `add`: `getFollowingPosts`
- `lib/src/features/discover/data/discover_helper.dart` — `add`: `getFollowingPage`
- `lib/src/features/discover/presentation/providers/discover_providers.dart` — `fix`: `followingFeedProvider` fetches from the server (autoDispose) instead of filtering `feedProvider`
- `lib/src/features/discover/presentation/screens/home_feed_screen.dart` — `fix`: pull-to-refresh and retry refresh the visible tab

**Notes:**
- Run `supabase/following_feed.sql` in the SQL editor first.
- First page only (no "load more" yet), same as the other feeds.
- Like counts changed on the For You list don't update the Following tab until it reloads.

**Commit:** `feat: load following feed from get_following_feed`

### fix: upload percentage follows bytes the server received
Removed the 90% cap. Upload connections now use a 32 KB OS send buffer; TCP keeps unacknowledged bytes in it, so each 16 KB flush only completes once the server has received nearly everything before it. The bar shows that real figure and holds at 99% until Supabase replies.

- `lib/src/services/supabase_storage_service.dart` — `fix`: `_smallBufferConnection` (opens the socket, sets `SO_SNDBUF`, then wraps TLS), 16 KB flushed chunks, 99% until the response; `removed`: `_sendShare`

**Notes:**
- The bar can lead the server by at most ~32–64 KB plus one TLS record.
- Needs a real upload test on Android and iOS; if the buffer option is refused, a warning is logged and the old behaviour applies.

**Commit:** `fix: track upload progress by server-received bytes`

### fix: upload progress jumped straight to 100%
The whole file was handed to the socket buffer at once, so the bar hit 100% before anything reached the server. Chunks are now flushed one by one; sending fills the bar to 90% and the server's reply completes it.

- `lib/src/services/supabase_storage_service.dart` — `fix`: per-chunk `flush()`, `_sendShare` 0.9 cap until the response arrives

**Notes:**
- Small images (a few hundred KB) still fit in the phone's socket buffer, so they jump to 90% quickly and wait there for the server.

**Commit:** `fix: make upload progress track bytes sent`

### feat: follow button states
One follow button with the four design states (Follow, Following with a check, Loading... with a spinner, Follow Back), used on the follow list, notifications, other artists' profiles, artwork detail and search.

- `lib/src/shared/widgets/ui/artora/app_follow_button.dart` — `fix`: rebuilt with the four states, localized labels, `followsMe` and `width`
- `lib/src/features/discover/presentation/widgets/follow_button.dart` — `add`: `FollowButton(userId)` wired to the follow providers
- `lib/src/features/discover/presentation/providers/follow_providers.dart` — `add`: `followPendingProvider`, `FollowActions.toggle` (marks pending, ignores repeat taps)
- `lib/src/shared/widgets/ui/artora/app_artist_row.dart` — `add`: `isFollowLoading`
- `lib/src/features/profile/presentation/screens/follow_list_screen.dart` — `removed`: `_FollowButton`; `fix`: uses `FollowButton`
- `lib/src/features/notifications/presentation/screens/notifications_screen.dart` — `fix`: `_FollowBackButton` uses `FollowButton`
- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: other-artist actions use `FollowButton`; Message button matches its height
- `lib/src/features/discover/presentation/screens/artwork_detail_screen.dart` — `fix`: artist row uses `FollowButton`
- `lib/src/features/discover/presentation/screens/search_screen.dart` — `fix`: artist rows show loading, toggle via `FollowActions`
- `lib/src/features/discover/presentation/widgets/artwork_masonry.dart`, `lib/src/features/discover/presentation/screens/explore_screen.dart` — `fix`: toggle via `FollowActions`
- `lib/src/theme/app_icons.dart` — `add`: `checkmark`
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `common.loading`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- The small `FollowPill` on feed / explore cards keeps its compact look (no Loading state).
- Other artists' profiles show Follow / Following only; the profile data has no "follows me" flag for Follow Back.

**Commit:** `feat: add follow button states`

### feat: image upload progress card
While images upload, Edit Profile and the artwork editor (publish, draft, save changes) show a dimmed overlay with the image thumbnail, a progress bar, "Uploading image…" and the percentage.

- `lib/src/services/supabase_storage_service.dart` — `add`: `UploadProgress` typedef; `uploadFile(onProgress:)` streams the file to the Storage REST API and reports bytes sent (the SDK upload has no progress)
- `lib/src/config/app_config.dart` — `add`: `supabaseUrl` / `supabaseAnonKey` getters, used by `init` and the upload
- `lib/src/shared/widgets/ui/artora/app_upload_widgets.dart` — `add`: `AppUploadCard`, `AppUploadOverlay`
- `lib/src/features/auth/data/auth_usecase.dart`, `auth_usecase_impl.dart` — `fix`: `updateProfile(onProgress:)`, one bar across avatar + cover weighted by size
- `lib/src/features/auth/presentation/providers/auth_providers.dart` — `fix`: `EditProfileNotifier.progress`
- `lib/src/features/discover/data/discover_usecase.dart`, `discover_usecase_impl.dart`, `discover_helper.dart` — `fix`: `postArtwork` / `updateArtwork` / `uploadImages` take `onProgress`
- `lib/src/features/discover/state/artwork_provider.dart` — `fix`: `PostArtworkNotifier.progress`; senders forward progress
- `lib/src/features/profile/presentation/screens/edit_profile_screen.dart` — `fix`: wrapped in `AppUploadOverlay`
- `lib/src/features/discover/presentation/screens/artwork_editor_screen.dart` — `fix`: wrapped in `AppUploadOverlay`
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `common.uploading_image`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Create Collection cover upload still has no progress card.
- Progress counts bytes handed to the socket, so it can run slightly ahead of the server on slow connections.

**Commit:** `feat: show upload progress card for images`

### feat: cover image on Edit Profile
A "Cover Image" section under the avatar picks a wide photo; Save uploads it to the `banners` bucket and sets `profiles.cover_path`.

- `lib/src/features/profile/presentation/screens/edit_profile_screen.dart` — `add`: `_CoverPicker` section; cover passed on save
- `lib/src/features/auth/data/auth_usecase.dart` — `add`: `pickCover`; `fix`: `updateProfile` takes an optional `cover`
- `lib/src/features/auth/data/auth_usecase_impl.dart` — `add`: `pickCover`, cover upload in `updateProfile`; `fix`: picking and uploading shared via `_pickImage` / `_uploadImage`
- `lib/src/features/auth/presentation/providers/auth_providers.dart` — `add`: `profileCoverProvider`; `fix`: `ProfileAvatarNotifier` takes its picker function
- `lib/src/network/constants/supabase_buckets.dart` — `add`: `coverPath` (`<uid>/cover.<ext>`)
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `edit_profile.cover`, `edit_profile.change_cover`
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- The `banners` bucket needs a storage policy allowing users to write under their own `<uid>/` folder.

**Commit:** `feat: add cover image to edit profile`

### feat: Edit Profile screen
Edit photo, display name, username (live availability check), bio and up to 5 specialties, with a live preview card. Opened from the profile's Edit Profile button and Settings → Edit Profile.

- `lib/src/features/profile/presentation/screens/edit_profile_screen.dart` — `add`: the screen
- `lib/src/features/auth/data/auth_usecase.dart` — `add`: `updateProfile`
- `lib/src/features/auth/data/auth_usecase_impl.dart` — `add`: `updateProfile` (patches only the edited columns); `fix`: avatar upload moved to `_uploadAvatar`, shared with setup
- `lib/src/features/auth/presentation/providers/auth_providers.dart` — `add`: `EditProfileNotifier` / `editProfileProvider`
- `lib/src/routing/app_routes.dart` — `add`: `editProfile` (`/edit-profile`)
- `lib/src/routing/app_router.dart` — `fix`: editProfile route; profile tab wires `onEditProfile`
- `lib/src/features/profile/presentation/screens/settings_screen.dart` — `fix`: Edit Profile row opens the screen
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `edit_profile.*` strings
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Needs an RLS update policy on `profiles` allowing `auth.uid() = id`.
- The "+" chip (custom specialty) from the design is not built; picks come from the preset list plus whatever the user already has.

**Commit:** `feat: add edit profile screen`

### fix: follower/following RPC param names
`list_followers` / `list_following` calls failed with PGRST202 because the client sent `p_uid/p_limit/p_offset`; the DB functions expect `uid/page_limit/page_offset`.

- `lib/src/features/discover/data/discover_usecase_impl.dart` — `fix`: use `uid`, `page_limit`, `page_offset` in `_followList`

**Notes:**
- Assumes `list_following` has the same signature as `list_followers` (not verified; only the followers error was reported)

**Commit:** `fix: match follow list rpc param names`

### feat: Activity screen design
The notifications screen is now the "Activity" design: title, All / Likes / Comments / Follows chips with a tune button, rows grouped under Today / Yesterday, artwork thumbnails, comment text, and outlined Follow Back buttons.

- `lib/src/features/notifications/presentation/screens/notifications_screen.dart` — `fix`: rebuilt to the design (filters are client-side; the tune button offers Mark all read; no back arrow, the bottom nav is shown)
- `lib/src/features/notifications/model/notification_model.dart` — `fix`: `artworkThumbUrl`, `commentText`
- `lib/src/features/notifications/data/notifications_service.dart` — `fix`: also embeds the artwork's images and the comment text
- `assets/translations/en.json`, `assets/translations/ja.json` — `fix`: Activity title, filter, day and time-ago strings
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Rows show the username (as in the design), not the display name

**Commit:** `feat: build activity screen design`

### feat: realtime notifications
Likes, comments and new followers create notifications automatically (database triggers); the app listens in real time, shows a dot on the bell and a Notifications screen. Follow notifications have a Follow Back button.

- `supabase/notifications.sql` — `add`: `notifications` table, RLS (read / mark read / delete only your own, no client insert), triggers on likes, comments and follows (and removal on unlike / unfollow), realtime publication
- `lib/src/features/notifications/model/notification_model.dart` — `add`: `NotificationModel`, `NotificationType`
- `lib/src/features/notifications/data/notifications_service.dart` — `add`: list, markRead, markAllRead, realtime `subscribe`
- `lib/src/features/notifications/presentation/providers/notification_providers.dart` — `add`: `notificationsProvider` (loads, then refetches on every realtime change; follows sign-in / sign-out), `unreadNotificationsProvider`
- `lib/src/features/notifications/presentation/screens/notifications_screen.dart` — `add`: the screen
- `lib/src/routing/app_routes.dart`, `lib/src/routing/app_router.dart` — `add`: `/notifications` route
- `lib/src/features/discover/presentation/screens/home_feed_screen.dart`, `lib/src/features/discover/presentation/screens/explore_screen.dart` — `fix`: bell opens Notifications and shows the unread dot
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `notifications` strings
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Run `supabase/notifications.sql` after explore / comments / follows. If a `notifications` table already exists with other columns, drop it first
- The unread dot counts the latest 50 notifications only
- No notification for replies to someone else's comment, comment likes, or collection likes / saves yet

**Commit:** `feat: add realtime notifications`

### fix: search scope tabs use Material TabBar
The five search tabs are a scrollable Material `TabBar`, since five labels no longer fit evenly.

- `lib/src/features/discover/presentation/screens/search_screen.dart` — `fix`: both the scope tabs and the result-type tabs under All are now `TabBar(isScrollable: true)` with their own `TabController`; `removed`: unused `UnderlineTabs` import

**Commit:** `fix: use scrollable material tabbar in search`

### feat: collections in search results
Search now also returns public collections, with a new Collections tab next to All / Artwork / Artists / Tags.

- `lib/src/features/discover/model/discover_models.dart` — `fix`: `SearchResults.collections`; `SearchScope.collections`
- `lib/src/features/discover/data/discover_helper.dart` — `fix`: `search` also calls the `search_collections` RPC (empty if it fails, so search still works)
- `lib/src/features/discover/presentation/screens/search_screen.dart` — `fix`: Collections tab, a count in the All results tabs, cover cards for results

**Notes:**
- Needs `supabase/collections.sql` applied
- Tapping a result opens the owner's profile until a collection detail screen exists

**Commit:** `feat: return collections in search results`

### feat: collections tab on explore
Explore now has two swipeable tabs, Explore and Collections; the Collections tab lists trending public collections as cover cards.

- `lib/src/features/discover/presentation/screens/explore_screen.dart` — `fix`: top bar, search and a Material `TabBar` stay fixed above a `TabBarView`; `add`: `_CollectionsTab`
- `lib/src/features/discover/presentation/providers/collection_providers.dart` — `add`: `trendingCollectionsProvider`; `fix`: creating a collection refreshes it

**Notes:**
- Needs `supabase/collections.sql` (the `trending_collections` function)
- Tapping a card opens its owner's profile until a collection detail screen exists

**Commit:** `feat: add collections tab to explore`

### feat: swipe between profile tabs
Artwork and Collections are now a `TabBarView`, so you can swipe between them; the header still collapses and the avatar still docks.

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: `CustomScrollView` → `NestedScrollView` (header in a `SliverOverlapAbsorber`) with a `TabBarView` body and a `TabController` driving the tab strip; `removed`: short-profile bottom padding (no longer needed)

**Notes:**
- Each tab keeps its own scroll position
- Pull-to-refresh is triggered from inside either tab

**Commit:** `feat: swipe between artwork and collections on profile`

### feat: create collection screen
Create a collection with a name, optional cover and a pick of your own artworks; the profile Collections tab now lists collections as cover cards.

- `lib/src/features/discover/presentation/screens/create_collection_screen.dart` — `add`: the screen and the artwork picker sheet
- `lib/src/features/discover/presentation/providers/collection_providers.dart` — `add`: `userCollectionsProvider`, `createCollectionProvider`
- `lib/src/shared/widgets/ui/artora/app_collection_widgets.dart` — `add`: `AppDashedBox`, `AppDashedBorderPainter`, `AppStackedCardsArt`, `AppCollectionCard`
- `lib/src/shared/widgets/ui/artora/artora.dart` — `fix`: export the new widgets
- `lib/src/features/discover/data/discover_usecase.dart` — `fix`: `createCollection` takes `cover` and `artworkIds`
- `lib/src/features/discover/data/discover_usecase_impl.dart` — `fix`: uploads the cover, adds artworks in order, rolls back on failure; name limit 60
- `lib/src/features/discover/presentation/screens/artwork_editor_screen.dart` — `removed`: private dashed painter (uses the shared one)
- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: Collections tab lists collections; empty-state button opens Create Collection; illustration uses `AppStackedCardsArt`
- `lib/src/routing/app_routes.dart`, `lib/src/routing/app_router.dart` — `add`: `/collection/new` route
- `lib/src/theme/app_icons.dart` — `add`: `imageAdd`, `layers`
- `supabase/collections.sql` — `fix`: `collection_cards.cover_url` falls back to the first artwork's thumbnail
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: `collection` strings
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Re-run `supabase/collections.sql` (view change)
- New collections are created public (the design has no visibility toggle)
- Collection cards don't open anything yet (no detail screen)

**Commit:** `feat: add create collection screen and profile collections`

### feat: profile empty states
Your own empty Artwork and Collections tabs show a stacked-cards illustration, a hint and a big create button; other people's profiles keep the plain message.

- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `add`: `_ProfileEmpty` widget; `fix`: both tabs use it on your own profile
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: empty hint / button / collections_soon strings
- `lib/src/core/i18n/locale_keys.g.dart` — `fix`: regenerated

**Notes:**
- Artwork button opens the create-artwork screen; the Collections button shows a "coming soon" toast until a create-collection screen exists
- The collection card UI (Ethereal Worlds) is not built yet

**Commit:** `feat: add profile empty states for artworks and collections`

### feat: user collections
Owner-made folders of artworks that the public can search, like and save. Data layer only (SQL + usecase methods), with no UI or providers yet.

- `supabase/collections.sql` — `add`: owner_id / description columns on `collections`, `collection_likes`, `collection_saves`, RLS policies, `collection_cards` view, search / list / `trending_collections` RPCs
- `lib/src/features/discover/model/collection_model.dart` — `add`: `CollectionModel` for `collection_cards` rows
- `lib/src/features/discover/data/discover_usecase.dart` — `add`: createCollection, addToCollection, removeFromCollection, deleteCollection, getUserCollections, searchCollections, getTrendingCollections
- `lib/src/features/discover/data/discover_usecase_impl.dart` — `add`: implementations of the collection methods
- `lib/src/network/constants/supabase_tables.dart` — `fix`: collection table and RPC names

**Notes:**
- Run `supabase/collections.sql` after `explore.sql`
- It extends the existing editorial `collections` table, so public user collections can show in the Explore strip (filter on `owner_id is null` in `explore.sql` to prevent that)
- Not run against Supabase yet

**Commit:** `feat: add user collections sql and rls`

### feat: followers & following screen
Two-tab list (Followers / Following) with search and Follow, Follow Back and Following buttons; opened from the counts on a profile.

- `lib/src/features/profile/presentation/screens/follow_list_screen.dart` — `add`: the screen
- `lib/src/routing/app_router.dart` — `fix`: added artistConnections route
- `lib/src/routing/app_routes.dart` — `fix`: artistConnections path and builder
- `lib/src/features/profile/presentation/screens/profile_screen.dart` — `fix`: Followers / Following counts are tappable
- `lib/src/features/discover/presentation/providers/follow_providers.dart` — `fix`: refresh profile counts after follow / unfollow
- `lib/src/features/discover/model/follow_model.dart` — `fix`: added bio
- `supabase/follows.sql` — `fix`: list_followers / list_following now return bio
- `assets/translations/en.json`, `assets/translations/ja.json` — `add`: follow_list strings

**Notes:**
- Re-run `supabase/follows.sql` in Supabase (functions are dropped and recreated)
- Not run on a device yet

**Commit:** `feat: add followers & following screen`
