import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../utils/logger.dart';
import '../../utils/task_runner.dart';
import '../failures/failure.dart';
import '../resource/resource.dart';

/// A row as returned by PostgREST.
typedef SBRow = Map<String, dynamic>;

/// Adds extra PostgREST filters (`.gt`, `.inFilter`, `.ilike`, `.or`…) on top of
/// the simple `eq` map.
typedef SBFilter<T> = PostgrestFilterBuilder<T> Function(
  PostgrestFilterBuilder<T> query,
);

/// Single entry point for Supabase data access.
///
/// Every call returns a [Resource] — errors are mapped to typed `Failure`s,
/// logged and network-checked by `runTask`, and never thrown.
///
/// ```dart
/// final res = await SBClient.instance.get(
///   SupabaseTables.artworks,
///   eq: {'user_id': uid},
///   orderBy: 'created_at',
///   limit: 20,
/// );
/// res.when(loading: ..., success: (rows) => ..., error: (f) => ...);
/// ```
class SBClient {
  SBClient._();
  static final SBClient instance = SBClient._();

  SupabaseClient get _client => AppConfig.supabase;

  // ── GET ───────────────────────────────────────────────────────────────────

  /// Selects rows from [table].
  ///
  /// [eq] adds equality filters; [filter] adds any other PostgREST filter.
  /// Use [limit] with [offset] for pagination.
  Future<Resource<List<SBRow>>> get(
    String table, {
    String columns = '*',
    Map<String, Object?>? eq,
    SBFilter<PostgrestList>? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int offset = 0,
  }) {
    return _run(
      'get',
      table,
      () async {
        var query = _applyEq(_client.from(table).select(columns), eq);
        if (filter != null) query = filter(query);

        PostgrestTransformBuilder<PostgrestList> ordered = query;
        if (orderBy != null) {
          ordered = query.order(orderBy, ascending: ascending);
        }
        if (limit != null) {
          ordered = ordered.range(offset, offset + limit - 1);
        }

        final rows = await ordered;
        return List<SBRow>.from(rows);
      },
      {'columns': columns, 'eq': eq, 'limit': limit, 'offset': offset},
    );
  }

  /// Selects a single row. Yields a `NotFoundFailure` when nothing matches.
  Future<Resource<SBRow>> getOne(
    String table, {
    String columns = '*',
    required Map<String, Object?> eq,
    SBFilter<PostgrestList>? filter,
  }) {
    return _run(
      'getOne',
      table,
      () async {
        var query = _applyEq(_client.from(table).select(columns), eq);
        if (filter != null) query = filter(query);

        final row = await query.maybeSingle();
        if (row == null) {
          throw const NotFoundFailure(
            "We couldn't find what you were looking for.",
            statusCode: 404,
          );
        }
        return SBRow.from(row);
      },
      {'columns': columns, 'eq': eq},
    );
  }

  /// Counts rows matching [eq] / [filter] without fetching them.
  Future<Resource<int>> count(
    String table, {
    Map<String, Object?>? eq,
    SBFilter<PostgrestList>? filter,
  }) {
    return _run(
      'count',
      table,
      () async {
        var query = _applyEq(_client.from(table).select(), eq);
        if (filter != null) query = filter(query);
        return query.count(CountOption.exact).then((r) => r.count);
      },
      {'eq': eq},
    );
  }

  // ── POST (insert) ─────────────────────────────────────────────────────────

  /// Inserts one row and returns it.
  Future<Resource<SBRow>> post(String table, SBRow values) {
    return _run(
      'post',
      table,
      () async => SBRow.from(
        await _client.from(table).insert(values).select().single(),
      ),
      {'keys': values.keys.toList()},
    );
  }

  /// Inserts many rows and returns them.
  Future<Resource<List<SBRow>>> postMany(String table, List<SBRow> values) {
    return _run(
      'postMany',
      table,
      () async => List<SBRow>.from(
        await _client.from(table).insert(values).select(),
      ),
      {'count': values.length},
    );
  }

  // ── PUT (upsert) ──────────────────────────────────────────────────────────

  /// Inserts or updates a row, resolving conflicts on [onConflict]
  /// (comma-separated column names; defaults to the primary key).
  Future<Resource<SBRow>> put(
    String table,
    SBRow values, {
    String? onConflict,
  }) {
    return _run(
      'put',
      table,
      () async => SBRow.from(
        await _client
            .from(table)
            .upsert(values, onConflict: onConflict)
            .select()
            .single(),
      ),
      {'keys': values.keys.toList(), 'onConflict': onConflict},
    );
  }

  // ── PATCH (update) ────────────────────────────────────────────────────────

  /// Updates rows matching [eq] / [filter] and returns them.
  ///
  /// At least one filter is required so a bug can never update a whole table.
  Future<Resource<List<SBRow>>> patch(
    String table,
    SBRow values, {
    Map<String, Object?>? eq,
    SBFilter<dynamic>? filter,
  }) {
    _requireFilter(eq, filter);
    return _run(
      'patch',
      table,
      () async {
        var query = _applyEq(_client.from(table).update(values), eq);
        if (filter != null) query = filter(query);
        return List<SBRow>.from(await query.select());
      },
      {'keys': values.keys.toList(), 'eq': eq},
    );
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  /// Deletes rows matching [eq] / [filter] and returns the deleted rows.
  ///
  /// At least one filter is required so a bug can never wipe a whole table.
  Future<Resource<List<SBRow>>> delete(
    String table, {
    Map<String, Object?>? eq,
    SBFilter<dynamic>? filter,
  }) {
    _requireFilter(eq, filter);
    return _run(
      'delete',
      table,
      () async {
        var query = _applyEq(_client.from(table).delete(), eq);
        if (filter != null) query = filter(query);
        return List<SBRow>.from(await query.select());
      },
      {'eq': eq},
    );
  }

  // ── RPC ───────────────────────────────────────────────────────────────────

  /// Calls a Postgres function and returns its result as [T]
  /// (a row, a list of rows, or a scalar).
  Future<Resource<T>> rpc<T>(
    String function, {
    Map<String, dynamic>? params,
  }) {
    return _run(
      'rpc',
      function,
      () async => await _client.rpc<dynamic>(function, params: params) as T,
      {'params': params?.keys.toList()},
    );
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<Resource<T>> _run<T>(
    String operation,
    String target,
    Future<T> Function() action,
    Map<String, Object?> context,
  ) async {
    final result = await runTask(
      action,
      operation: 'sb.$operation',
      category: LogCategory.database,
      context: {'target': target, ...context},
      requiresNetwork: true,
    );
    return Resource.fromEither(result);
  }

  static B _applyEq<B extends PostgrestFilterBuilder<dynamic>>(
    B query,
    Map<String, Object?>? eq,
  ) {
    var q = query;
    eq?.forEach((column, value) => q = q.eq(column, value as Object) as B);
    return q;
  }

  static void _requireFilter(Map<String, Object?>? eq, Object? filter) {
    assert(
      (eq != null && eq.isNotEmpty) || filter != null,
      'SBClient: patch/delete require at least one filter.',
    );
  }
}
