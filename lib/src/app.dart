import 'package:artora/src/imports/core_imports.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    Widget current = _buildMaterialApp(context);
    current = AppPlatformScope(
      style: AppPlatformStyle.adaptive,
      child: current,
    );
    return ScreenUtilWrapper(child: current);
  }


  Widget _buildMaterialApp(BuildContext context) {
    return MaterialApp.router(
      title: 'ARTORA',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      builder: (context, child) {
        Widget current = child!;
        current = SkeletonWrapper(child: current);
        // current = SessionListenerWrapper(child: current);
        return current;
      },
    );
  }
}
