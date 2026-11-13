import 'package:shared_preferences/shared_preferences.dart';
import '../utils/utils.dart';

/// Every key written to local storage. Add new keys here so the app has one
/// list of what it persists, and use them with [StorageService] instead of
/// creating a store per feature.
abstract final class StorageKeys {
  StorageKeys._();

  /// `List<String>` — the user's last search queries, newest first.
  static const String recentSearches = 'recent_searches';
}

/// The app's single entry point for simple key-value persistence, a wrapper
/// around [SharedPreferences]. Features read and write through this class.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late final SharedPreferences _prefs;

  /// Initialize SharedPreferences instance.
  FutureEither<void> init() async {
    return runTask(
      () async {
        _prefs = await SharedPreferences.getInstance();
      },
      operation: 'sharedPreferences.init',
      category: LogCategory.database,
    );
  }

  // --- SETTERS ---

  FutureEither<bool> setString(String key, String value) async {
    return runTask(
      () => _prefs.setString(key, value),
      operation: 'sharedPreferences.setString',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  FutureEither<bool> setBool(String key, bool value) async {
    return runTask(
      () => _prefs.setBool(key, value),
      operation: 'sharedPreferences.setBool',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  FutureEither<bool> setInt(String key, int value) async {
    return runTask(
      () => _prefs.setInt(key, value),
      operation: 'sharedPreferences.setInt',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  FutureEither<bool> setDouble(String key, double value) async {
    return runTask(
      () => _prefs.setDouble(key, value),
      operation: 'sharedPreferences.setDouble',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  FutureEither<bool> setStringList(String key, List<String> value) async {
    return runTask(
      () => _prefs.setStringList(key, value),
      operation: 'sharedPreferences.setStringList',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  // --- GETTERS ---

  String? getString(String key) {
    return _prefs.getString(key);
  }

  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  // --- COMMON ---

  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  FutureEither<bool> remove(String key) async {
    return runTask(
      () => _prefs.remove(key),
      operation: 'sharedPreferences.remove',
      category: LogCategory.database,
      context: {'key': key},
    );
  }

  FutureEither<bool> clear() async {
    return runTask(
      () => _prefs.clear(),
      operation: 'sharedPreferences.clear',
      category: LogCategory.database,
    );
  }
}
