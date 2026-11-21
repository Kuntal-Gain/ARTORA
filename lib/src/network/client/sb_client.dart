
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';
import '../../utils/logger.dart';
import '../../utils/task_runner.dart';
import '../failures/failure.dart';
import '../resource/resource.dart';

/// A row as returned by PostgREST.
typedef SBRow = Map<String, dynamic>;

/// Adds extra PostgREST filters (`.gt`, `.inFilter`, `.ilike`, `.or`…)
/// on top of the simple `eq` map.
typedef SBFilter<T> = PostgrestFilterBuilder<T> Function(
  PostgrestFilterBuilder<T> query,
);

/// Adds additional filters to a Supabase Realtime stream.
typedef SBStreamFilter = SupabaseStreamFilterBuilder Function(
  SupabaseStreamFilterBuilder query,
);

/// Callback for a Postgres database change.
typedef SBChangeCallback = void Function(
  PostgresChangePayload payload,
);

/// Callback for Realtime subscription status changes.
typedef SBStatusCallback = void Function(
  RealtimeSubscribeStatus status,
  Object? error,
);

/// Single entry point for Supabase data access.
///
/// CRUD and RPC calls return [Resource].
/// Errors are mapped to typed Failures and handled through runTask.
///
/// Realtime operations expose native Streams and RealtimeChannels.
///
/// Example:
///
/// final result = await SBClient.instance.get(
///   SupabaseTables.artworks,
///   eq: {'user_id': uid},
///   orderBy: 'created_at',
///   limit: 20,
/// );
///
/// result.when(
///   loading: ...,
///   success: (rows) => ...,
///   error: (failure) => ...,
/// );
///
/// Realtime:
///
/// final stream = SBClient.instance.watch(
///   SupabaseTables.artworks,
///   primaryKey: ['id'],
///   eq: {'user_id': uid},
/// );
class SBClient {
  SBClient._();

  static final SBClient instance = SBClient._();

  SupabaseClient get _client => AppConfig.supabase;

  int _realtimeChannelId = 0;

  // ── GET ─────────────────────────────────────────────────────

  /// Selects rows from [table].
  ///
  /// [eq] adds equality filters.
  /// [filter] adds additional PostgREST filters.
  /// [limit] with [offset] supports pagination.
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
        var query = _applyEq(
          _client.from(table).select(columns),
          eq,
        );

        if (filter != null) {
          query = filter(query);
        }

        PostgrestTransformBuilder<PostgrestList> ordered = query;

        if (orderBy != null) {
          ordered = query.order(
            orderBy,
            ascending: ascending,
          );
        }

        if (limit != null) {
          ordered = ordered.range(
            offset,
            offset + limit - 1,
          );
        }

        final rows = await ordered;

        return List<SBRow>.from(rows);
      },
      {
        'columns': columns,
        'eq': eq,
        'limit': limit,
        'offset': offset,
      },
    );
  }

  /// Selects a single row.
  ///
  /// Returns NotFoundFailure when no matching row exists.
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
        var query = _applyEq(
          _client.from(table).select(columns),
          eq,
        );

        if (filter != null) {
          query = filter(query);
        }

        final row = await query.maybeSingle();

        if (row == null) {
          throw const NotFoundFailure(
            "We couldn't find what you were looking for.",
            statusCode: 404,
          );
        }

        return SBRow.from(row);
      },
      {
        'columns': columns,
        'eq': eq,
      },
    );
  }

  /// Counts matching rows.
  Future<Resource<int>> count(
    String table, {
    Map<String, Object?>? eq,
    SBFilter<PostgrestList>? filter,
  }) {
    return _run(
      'count',
      table,
      () async {
        var query = _applyEq(
          _client.from(table).select(),
          eq,
        );

        if (filter != null) {
          query = filter(query);
        }

        final response = await query.count(
          CountOption.exact,
        );

        return response.count;
      },
      {'eq': eq},
    );
  }

  // ── POST (INSERT) ───────────────────────────────────────────

  /// Inserts one row and returns the inserted row.
  Future<Resource<SBRow>> post(
    String table,
    SBRow values,
  ) {
    return _run(
      'post',
      table,
      () async {
        final row = await _client
            .from(table)
            .insert(values)
            .select()
            .single();

        return SBRow.from(row);
      },
      {'keys': values.keys.toList()},
    );
  }

  /// Inserts multiple rows and returns the inserted rows.
  Future<Resource<List<SBRow>>> postMany(
    String table,
    List<SBRow> values,
  ) {
    return _run(
      'postMany',
      table,
      () async {
        final rows = await _client
            .from(table)
            .insert(values)
            .select();

        return List<SBRow>.from(rows);
      },
      {'count': values.length},
    );
  }

  // ── PUT (UPSERT) ────────────────────────────────────────────

  /// Inserts or updates a row.
  ///
  /// [onConflict] specifies conflict columns.
  /// Defaults to the table's primary key.
  Future<Resource<SBRow>> put(
    String table,
    SBRow values, {
    String? onConflict,
  }) {
    return _run(
      'put',
      table,
      () async {
        final row = await _client
            .from(table)
            .upsert(
              values,
              onConflict: onConflict,
            )
            .select()
            .single();

        return SBRow.from(row);
      },
      {
        'keys': values.keys.toList(),
        'onConflict': onConflict,
      },
    );
  }

  // ── PATCH (UPDATE) ─────────────────────────────────────────

  /// Updates rows matching [eq] or [filter].
  ///
  /// Requires at least one filter to prevent accidental
  /// updates across the entire table.
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
        var query = _applyEq(
          _client.from(table).update(values),
          eq,
        );

        if (filter != null) {
          query = filter(query);
        }

        final rows = await query.select();

        return List<SBRow>.from(rows);
      },
      {
        'keys': values.keys.toList(),
        'eq': eq,
      },
    );
  }

  // ── DELETE ─────────────────────────────────────────────────

  /// Deletes rows matching [eq] or [filter].
  ///
  /// Requires at least one filter to prevent accidental
  /// deletion of the entire table.
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
        var query = _applyEq(
          _client.from(table).delete(),
          eq,
        );

        if (filter != null) {
          query = filter(query);
        }

        final rows = await query.select();

        return List<SBRow>.from(rows);
      },
      {'eq': eq},
    );
  }

  // ── RPC ────────────────────────────────────────────────────

  /// Calls a PostgreSQL function.
  ///
  /// [T] can be a row, list of rows, or scalar value.
  Future<Resource<T>> rpc<T>(
    String function, {
    Map<String, dynamic>? params,
  }) {
    return _run(
      'rpc',
      function,
      () async {
        final result = await _client.rpc<dynamic>(
          function,
          params: params,
        );

        return result as T;
      },
      {'params': params?.keys.toList()},
    );
  }

  /// Calls a function that returns `setof <table>` and shapes the rows with
  /// [columns], so embeds (`images:artwork_images(...)`) work like in [get].
  Future<Resource<List<SBRow>>> rpcRows(
    String function, {
    Map<String, dynamic>? params,
    String columns = '*',
  }) {
    return _run(
      'rpcRows',
      function,
      () async {
        final rows = await _client
            .rpc<List<dynamic>>(function, params: params)
            .select(columns);
        return List<SBRow>.from(rows);
      },
      {'params': params?.keys.toList()},
    );
  }

  // ── REALTIME: WATCH ────────────────────────────────────────

  /// Watches a table and emits its current rows and future changes.
  ///
  /// Fetches initial data automatically.
  ///
  /// Realtime changes are reflected in subsequent stream emissions.
  ///
  /// [primaryKey] identifies records for update/delete reconciliation.
  /// [eq] applies equality filters.
  /// [filter] applies additional supported stream filters.
  ///
  /// Important:
  /// The stream must be created once and reused rather than
  /// recreated during every Flutter widget rebuild.
  ///
  /// Example:
  ///
  /// final stream = SBClient.instance.watch(
  ///   'artworks',
  ///   primaryKey: ['id'],
  ///   eq: {'user_id': userId},
  ///   orderBy: 'created_at',
  ///   ascending: false,
  ///   limit: 20,
  /// );
  Stream<List<SBRow>> watch(
    String table, {
    required List<String> primaryKey,
    Map<String, Object?>? eq,
    SBStreamFilter? filter,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) {
    if (primaryKey.isEmpty) {
      throw ArgumentError(
        'SBClient.watch requires at least one primary key.',
      );
    }

    if (limit != null && limit <= 0) {
      throw ArgumentError.value(
        limit,
        'limit',
        'Limit must be greater than zero.',
      );
    }

    var query = _client.from(table).stream(
      primaryKey: primaryKey,
    );

    if (eq != null) {
      for (final entry in eq.entries) {
        final value = entry.value;

        query = value == null
            ? query.isFilter(entry.key, null)
            : query.eq(entry.key, value);
      }
    }

    if (filter != null) {
      query = filter(query);
    }

    SupabaseStreamBuilder result = query;

    if (orderBy != null) {
      result = result.order(
        orderBy,
        ascending: ascending,
      );
    }

    if (limit != null) {
      result = result.limit(limit);
    }

    return result;
  }

  // ── REALTIME: SUBSCRIBE ────────────────────────────────────

  /// Subscribes to PostgreSQL database changes.
  ///
  /// Supported events:
  /// - PostgresChangeEvent.all
  /// - PostgresChangeEvent.insert
  /// - PostgresChangeEvent.update
  /// - PostgresChangeEvent.delete
  ///
  /// [onChange] receives database change payloads.
  /// [onStatus] receives subscription lifecycle events.
  ///
  /// Returns a [RealtimeChannel] which must be removed
  /// using [unsubscribeChanges] when no longer required.
  ///
  /// Unlike [watch], this does not fetch initial rows.
  ///
  /// Example:
  ///
  /// final channel = SBClient.instance.subscribeChanges(
  ///   'artworks',
  ///   event: PostgresChangeEvent.insert,
  ///   onChange: (payload) {
  ///     print(payload.newRecord);
  ///   },
  /// );
  RealtimeChannel subscribeChanges(
    String table, {
    String schema = 'public',
    String? channelName,
    PostgresChangeEvent event = PostgresChangeEvent.all,
    PostgresChangeFilter? filter,
    required SBChangeCallback onChange,
    SBStatusCallback? onStatus,
  }) {
    final topic = channelName ??
        'sb:$schema:$table:${_realtimeChannelId++}';

    final channel = _client.channel(topic);

    channel
        .onPostgresChanges(
          event: event,
          schema: schema,
          table: table,
          filter: filter,
          callback: onChange,
        )
        .subscribe((status, [error]) {
          onStatus?.call(status, error);
        });

    return channel;
  }

  // ── REALTIME: UNSUBSCRIBE ──────────────────────────────────

  /// Unsubscribes and removes a Realtime channel.
  ///
  /// Call this when a screen/controller is disposed.
  Future<void> unsubscribeChanges(
    RealtimeChannel channel,
  ) async {
    await _client.removeChannel(channel);
  }

  /// Removes all Realtime channels belonging to the client.
  ///
  /// Useful during logout or a full application reset.
  ///
  /// Warning:
  /// This also removes channels created outside SBClient,
  /// including active watch() stream channels.
  Future<void> unsubscribeAll() async {
    await _client.removeAllChannels();
  }

  // ── INTERNALS ──────────────────────────────────────────────

  /// Executes a one-shot Supabase operation through runTask.
  ///
  /// Maps failures, checks connectivity and records logs.
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
      context: {
        'target': target,
        ...context,
      },
      requiresNetwork: true,
    );

    return Resource.fromEither(result);
  }

  /// Applies equality filters to a PostgREST query.
  ///
  /// Supports null using SQL IS NULL semantics.
  static B _applyEq<B extends PostgrestFilterBuilder<dynamic>>(
    B query,
    Map<String, Object?>? eq,
  ) {
    var q = query;

    if (eq == null || eq.isEmpty) {
      return q;
    }

    for (final entry in eq.entries) {
      final value = entry.value;

      if (value == null) {
        q = q.isFilter(entry.key, null) as B;
      } else {
        q = q.eq(entry.key, value) as B;
      }
    }

    return q;
  }

  /// Prevents unfiltered update/delete operations.
  ///
  /// Uses a runtime validation rather than assert so the
  /// protection also works in release builds.
  static void _requireFilter(
    Map<String, Object?>? eq,
    Object? filter,
  ) {
    final hasEq = eq != null && eq.isNotEmpty;
    final hasFilter = filter != null;

    if (!hasEq && !hasFilter) {
      throw ArgumentError(
        'SBClient: patch/delete require at least one filter.',
      );
    }
  }
}
