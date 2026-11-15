# Changelog

Maintained by Claude Code after each task; format is defined in [CLAUDE.md](CLAUDE.md#changelog-changelogmd).

## Unreleased

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
