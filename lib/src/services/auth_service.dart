import '../utils/utils.dart';
import '../config/app_config.dart';
import '../network/constants/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  SupabaseClient get _supabaseClient => AppConfig.supabase;

  /// Stream of auth state changes. Emits the current user map or null.
  Stream<Map<String, dynamic>?> get authStateChanges {
    return logAuthStateChanges(
      _supabaseClient.auth.onAuthStateChange.map((data) {
        final session = data.session;
        if (session == null) return null;
        final user = session.user;
        return {
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? '',
          'photoUrl': user.userMetadata?['avatar_url'],
        };
      }),
      userIdOf: (user) => user['id'] as String? ?? '',
    );
  }

  FutureEither<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    return runTask(
      () async {
        final response = await _supabaseClient.auth.signInWithPassword(
          email: email,
          password: password,
        );
        final user = response.user;
        if (user == null) return null;
        return {
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? '',
          'photoUrl': user.userMetadata?['avatar_url'],
        };
      },
      operation: 'auth.login',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<Map<String, dynamic>?> signUp({
    required String name,
    required String email,
    required String password,
    String? username,
  }) async {
    return runTask(
      () async {
        final response = await _supabaseClient.auth.signUp(
          email: email,
          password: password,
          data: {'name': name, if (username != null) 'username': username},
        );
        final user = response.user;
        if (user == null) return null;
        return {
          'id': user.id,
          'email': user.email,
          'name': name,
          'photoUrl': user.userMetadata?['avatar_url'],
        };
      },
      operation: 'auth.signUp',
      category: LogCategory.auth,
      context: {'method': 'email'},
      requiresNetwork: true,
    );
  }

  FutureEither<void> forgotPassword({required String email}) async {
    return runTask(
      () async {
        await _supabaseClient.auth.resetPasswordForEmail(email);
      },
      operation: 'auth.forgotPassword',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> logout() async {
    return runTask(
      () async {
        await _supabaseClient.auth.signOut();
      },
      operation: 'auth.logout',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  /// Whether [password] is the signed-in user's current password
  /// (supabase/account.sql).
  FutureEither<bool> verifyPassword(String password) async {
    return runTask(
      () async {
        final result = await _supabaseClient.rpc<dynamic>(
          SupabaseRpc.verifyMyPassword,
          params: {'p_password': password},
        );
        return result == true;
      },
      operation: 'auth.verifyPassword',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> updatePassword(String newPassword) async {
    return runTask(
      () async {
        await _supabaseClient.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      },
      operation: 'auth.updatePassword',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  /// Signs every device out except this one.
  FutureEither<void> signOutOtherDevices() async {
    return runTask(
      () async {
        await _supabaseClient.auth.signOut(scope: SignOutScope.others);
      },
      operation: 'auth.signOutOthers',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  /// The signed-in user's live sessions (supabase/account.sql).
  FutureEither<List<Map<String, dynamic>>> listSessions() async {
    return runTask(
      () async {
        final rows = await _supabaseClient.rpc<List<dynamic>>(
          SupabaseRpc.listMySessions,
        );
        return [
          for (final row in rows) Map<String, dynamic>.from(row as Map),
        ];
      },
      operation: 'auth.listSessions',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<void> revokeSession(String sessionId) async {
    return runTask(
      () async {
        await _supabaseClient.rpc<dynamic>(
          SupabaseRpc.revokeMySession,
          params: {'p_session_id': sessionId},
        );
      },
      operation: 'auth.revokeSession',
      category: LogCategory.auth,
      requiresNetwork: true,
    );
  }

  FutureEither<Map<String, dynamic>?> getCurrentUser() async {
    return runTask(
      () async {
        final session = _supabaseClient.auth.currentSession;
        if (session == null) return null;
        final user = session.user;
        return {
          'id': user.id,
          'email': user.email,
          'name': user.userMetadata?['name'] ?? '',
          'username': user.userMetadata?['username'],
          'photoUrl': user.userMetadata?['avatar_url'],
        };
      },
      operation: 'auth.getCurrentUser',
      category: LogCategory.auth,
    );
  }

  void dispose() {
    // Supabase manages its own streams
  }
}
