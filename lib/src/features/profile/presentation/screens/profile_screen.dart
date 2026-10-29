import 'package:artora/src/imports/imports.dart';

/// Profile tab. The profile page itself hasn't been designed yet.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: AppEmptyState(
            icon: Icons.person_outline_rounded,
            title: LocaleKeys.profile_coming_soon_title.tr(),
            subtitle: LocaleKeys.profile_coming_soon_subtitle.tr(),
          ),
        ),
      ),
    );
  }
}
