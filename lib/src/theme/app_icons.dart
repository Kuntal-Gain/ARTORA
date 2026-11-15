import 'package:flutter/widgets.dart';
import 'package:hugeicons_pro/hugeicons.dart';

/// The app's icon system. Every icon in the project comes from here, and every
/// entry is a HugeIcons Pro icon:
///
/// ```dart
/// Icon(AppIcons.home)
/// Icon(isLiked ? AppIcons.likeFilled : AppIcons.like)
/// ```
///
/// Never use `Icons.*`, `CupertinoIcons.*` or `HugeIcons*` directly in a
/// widget. To change or add an icon, edit this file only.
///
/// Naming: the plain name is the outlined (stroke) icon; a `...Filled` name is
/// the solid version used for active or selected states.
abstract final class AppIcons {
  AppIcons._();

  // ── Navigation & arrows ──────────────────────────────────
  static const IconData back = HugeIconsStroke.arrowLeft01;
  static const IconData forward = HugeIconsStroke.arrowRight01;
  static const IconData chevronRight = HugeIconsStroke.arrowRight01;
  static const IconData chevronDown = HugeIconsStroke.arrowDown01;
  static const IconData more = HugeIconsStroke.moreVertical;
  

  // ── Tab bar ──────────────────────────────────────────────
  static const IconData home = HugeIconsStroke.home01;
  static const IconData homeFilled = HugeIconsSolid.home01;
  static const IconData person = HugeIconsStroke.user;
  static const IconData personFilled = HugeIconsSolid.user;
  static const IconData people = HugeIconsStroke.userMultiple;

  // ── Actions ──────────────────────────────────────────────
  static const IconData add = HugeIconsStroke.add01;
  static const IconData remove = HugeIconsStroke.remove01;
  static const IconData close = HugeIconsStroke.cancel01;
  static const IconData clearFilled = HugeIconsSolid.cancelCircle;
  static const IconData check = HugeIconsSolid.checkmarkCircle01;
  static const IconData edit = HugeIconsStroke.edit02;
  static const IconData send = HugeIconsStroke.sent;
  static const IconData share = HugeIconsStroke.share01;
  static const IconData link = HugeIconsStroke.link01;
  static const IconData tune = HugeIconsStroke.settings05;
  static const IconData settings = HugeIconsStroke.settings01;
  static const IconData cloudUpload = HugeIconsStroke.cloudUpload;

  // ── Search ───────────────────────────────────────────────
  static const IconData search = HugeIconsStroke.search01;
  static const IconData searchOff = HugeIconsStroke.searchRemove;
  static const IconData savedSearch = HugeIconsStroke.searchList01;
  static const IconData history = HugeIconsStroke.clock02;

  // ── Social ───────────────────────────────────────────────
  static const IconData like = HugeIconsStroke.favourite;
  static const IconData likeFilled = HugeIconsSolid.favourite;
  static const IconData comment = HugeIconsStroke.bubbleChat;
  static const IconData bookmark = HugeIconsStroke.bookmark01;
  static const IconData bookmarkFilled = HugeIconsSolid.bookmark01;
  static const IconData star = HugeIconsStroke.star;
  static const IconData starFilled = HugeIconsSolid.star;
  static const IconData starHalf = HugeIconsSolid.starHalf;
  static const IconData notifications = HugeIconsStroke.notification01;
  static const IconData verified = HugeIconsSolid.checkmarkBadge01;

  // ── Form fields ──────────────────────────────────────────
  static const IconData mail = HugeIconsStroke.mail01;
  static const IconData email = HugeIconsStroke.at;
  static const IconData lock = HugeIconsStroke.lockPassword;
  static const IconData visibility = HugeIconsStroke.view;
  static const IconData visibilityOff = HugeIconsStroke.viewOff;
  static const IconData calendar = HugeIconsStroke.calendar01;
  static const IconData time = HugeIconsStroke.clock01;
  static const IconData radioUnchecked = HugeIconsStroke.circle;

  // ── Media ────────────────────────────────────────────────
  static const IconData image = HugeIconsStroke.image01;
  static const IconData brokenImage = HugeIconsStroke.imageNotFound01;
  static const IconData camera = HugeIconsStroke.camera01;
  static const IconData landscape = HugeIconsStroke.mountain;
  static const IconData palette = HugeIconsStroke.paintBoard;
  static const IconData fit = HugeIconsStroke.fullScreen;
  static const IconData fill = HugeIconsStroke.crop;
  static const IconData original = HugeIconsStroke.image02;
  static const IconData triangle = HugeIconsStroke.triangle;
  static const IconData imageAdd = HugeIconsStroke.imageAdd01;
  static const IconData layers = HugeIconsStroke.layers01;

  // ── Status & feedback ────────────────────────────────────
  static const IconData info = HugeIconsStroke.informationCircle;
  static const IconData infoFilled = HugeIconsSolid.informationCircle;
  static const IconData warning = HugeIconsStroke.alert02;
  static const IconData error = HugeIconsStroke.alertCircle;
  static const IconData errorFilled = HugeIconsSolid.alertCircle;
  static const IconData priorityHigh = HugeIconsStroke.alertDiamond;
  static const IconData checkCircle = HugeIconsStroke.checkmarkCircle02;
  static const IconData checkCircleFilled = HugeIconsSolid.checkmarkCircle02;
  static const IconData cancelFilled = HugeIconsSolid.cancelCircle;
  static const IconData wifiOff = HugeIconsStroke.wifiOff01;
  static const IconData inbox = HugeIconsStroke.inbox;

  // ── Settings ─────────────────────────────────────────────
  static const IconData userEdit = HugeIconsStroke.userEdit01;
  static const IconData block = HugeIconsStroke.unavailable;
  static const IconData appearance = HugeIconsStroke.bulb;
  static const IconData language = HugeIconsStroke.globe02;
  static const IconData help = HugeIconsStroke.helpCircle;
  static const IconData logout = HugeIconsStroke.logout03;
  static const IconData delete = HugeIconsStroke.delete02;
}
