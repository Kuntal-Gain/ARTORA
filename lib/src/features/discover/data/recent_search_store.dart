import 'package:artora/src/services/hive_service.dart';

/// Keeps the user's recent search queries on the device.
class RecentSearchStore {
  static const String _key = 'recent_searches';
  static const int maxEntries = 10;

  List<String> read() => List<String>.from(
    HiveService.instance.get<List<dynamic>>(_key) ?? const <dynamic>[],
  );

  Future<void> write(List<String> entries) =>
      HiveService.instance.put(_key, entries);
}
