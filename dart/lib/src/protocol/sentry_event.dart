import 'package:collection/collection.dart';
import 'package:meta/meta.dart';

import '../protocol.dart';
import '../throwable_mechanism.dart';
import '../utils.dart';
import 'access_aware_map.dart';

/// An event to be reported to Sentry.io.
class SentryEvent with SentryEventLike<SentryEvent> {
  /// Creates an event.
  SentryEvent({
    SentryId? eventId,
    DateTime? timestamp,
    Map<String, String>? modules,
    Map<String, String>? tags,
    @Deprecated(
        'Additional Data is deprecated in favor of structured [Contexts] and should be avoided when possible')
    Map<String, dynamic>? extra,
    List<String>? fingerprint,
    List<Breadcrumb>? breadcrumbs,
    List<SentryException>? exceptions,
    List<SentryThread>? threads,
    this.sdk,
    this.platform,
    this.logger,
    this.serverName,
    this.release,
    this.dist,
    this.environment,
    this.message,
    this.transaction,
    dynamic throwable,
    this.level,
    this.culprit,
    this.user,
    Contexts? contexts,
    this.request,
    this.debugMeta,
    this.type,
    this.unknown,
  })  : eventId = eventId ?? SentryId.newId(),
        timestamp = timestamp ?? getUtcDateTime(),
        contexts = contexts ?? Contexts(),
        modules = modules != null ? Map.from(modules) : null,
        tags = tags != null ? Map.from(tags) : null,
        // ignore: deprecated_member_use_from_same_package
        extra = extra != null ? Map.from(extra) : null,
        fingerprint = fingerprint != null ? List.from(fingerprint) : null,
        breadcrumbs = breadcrumbs != null ? List.from(breadcrumbs) : null,
        exceptions = exceptions != null ? List.from(exceptions) : null,
        threads = threads != null ? List.from(threads) : null,
        _throwable = throwable;

  /// Refers to the default fingerprinting algorithm.
  ///
  /// You do not need to specify this value unless you supplement the default
  /// fingerprint with custom fingerprints.
  static const String defaultFingerprint = '{{ default }}';

  /// The ID Sentry.io assigned to the submitted event for future reference.
  SentryId eventId;

  /// A timestamp representing when the event occurred.
  DateTime? timestamp;

  /// A string representing the platform the SDK is submitting from. This will be used by the Sentry interface to customize various components in the interface.
  String? platform;

  /// The logger that logged the event.
  String? logger;

  /// Identifies the server that logged this event.
  String? serverName;

  /// The version of the application that logged the event.
  String? release;

  /// The distribution of the application.
  String? dist;

  /// The environment that logged the event, e.g. "production", "staging".
  String? environment;

  /// A list of relevant modules and their versions.
  Map<String, String>? modules;

  /// Event message.
  ///
  /// Generally an event either contains a [message] or [exceptions].
  SentryMessage? message;

  dynamic _throwable;

  /// An object that was thrown.
  ///
  /// It's `runtimeType` and `toString()` are logged.
  /// If it's an Error, with a stackTrace, the stackTrace is logged.
  /// If this behavior is undesirable, consider using a custom formatted
  /// [message] instead.
  dynamic get throwable =>
      (_throwable is ThrowableMechanism) ? _throwable.throwable : _throwable;

  /// A throwable decorator that holds a [Mechanism] related to the decorated
  /// [throwable]
  ///
  /// Use the [throwable] directly if you don't want the decorated throwable
  dynamic get throwableMechanism => _throwable;

  /// One or multiple chained (nested) exceptions that occurred in a program.
  List<SentryException>? exceptions;

  /// The Threads Interface specifies threads that were running at the time an
  /// event happened. These threads can also contain stack traces.
  /// Typically not needed in Dart applications.
  List<SentryThread>? threads;

  /// The name of the transaction which generated this event,
  /// for example, the route name: `"/users/<username>/"`.
  String? transaction;

  /// How important this event is.
  SentryLevel? level;

  /// What caused this event to be logged.
  String? culprit;

  /// Name/value pairs that events can be searched by.
  Map<String, String>? tags;

  /// Arbitrary name/value pairs attached to the event.
  ///
  /// Sentry.io docs do not talk about restrictions on the values, other than
  /// they must be JSON-serializable.
  @Deprecated(
      'Additional Data is deprecated in favor of structured [Contexts] and should be avoided when possible')
  Map<String, dynamic>? extra;

  /// List of breadcrumbs for this event.
  ///
  /// See also:
  /// * https://docs.sentry.io/platforms/dart/enriching-events/breadcrumbs/
  /// * https://docs.sentry.io/platforms/flutter/enriching-events/breadcrumbs/
  List<Breadcrumb>? breadcrumbs;

  /// Information about the current user.
  ///
  /// The value in this field overrides the user context
  /// set in [Scope.user] for this logged event.
  SentryUser? user;

  /// The context interfaces provide additional context data.
  /// Typically this is data related to the current user,
  /// the current HTTP request.
  Contexts contexts;

  /// Used to deduplicate events by grouping ones with the same fingerprint
  /// together.
  ///
  /// If not specified a default deduplication fingerprint is used. The default
  /// fingerprint may be supplemented by additional fingerprints by specifying
  /// multiple values. The default fingerprint can be specified by adding
  /// [defaultFingerprint] to the list in addition to your custom values.
  ///
  /// Examples:
  /// ```dart
  /// // A completely custom fingerprint:
  /// var custom = ['foo', 'bar', 'baz'];
  /// // A fingerprint that supplements the default one with value 'foo':
  /// var supplemented = [SentryEvent.defaultFingerprint, 'foo'];
  /// ```
  List<String>? fingerprint;

  /// The SDK Interface describes the Sentry SDK and its configuration used
  /// to capture and transmit an event.
  SdkVersion? sdk;

  /// Contains information on a HTTP request related to the event.
  /// In client, this can be an outgoing request, or the request that rendered
  /// the current web page.
  /// On server, this could be the incoming web request that is being handled
  SentryRequest? request;

  /// The debug meta interface carries debug information for processing errors
  /// and crash reports.
  DebugMeta? debugMeta;

  /// The event type determines how Sentry handles the event and has an impact
  /// on processing, rate limiting, and quotas.
  /// defaults to 'default'
  String? type;

  @internal
  final Map<String, dynamic>? unknown;

  @Deprecated('Assign values directly to the instance.')
  @override
  SentryEvent copyWith({
    SentryId? eventId,
    DateTime? timestamp,
    String? platform,
    String? logger,
    String? serverName,
    String? release,
    String? dist,
    String? environment,
    Map<String, String>? modules,
    SentryMessage? message,
    String? transaction,
    dynamic throwable,
    SentryLevel? level,
    String? culprit,
    Map<String, String>? tags,
    @Deprecated(
        'Additional Data is deprecated in favor of structured [Contexts] and should be avoided when possible')
    Map<String, dynamic>? extra,
    List<String>? fingerprint,
    SentryUser? user,
    Contexts? contexts,
    List<Breadcrumb>? breadcrumbs,
    SdkVersion? sdk,
    SentryRequest? request,
    DebugMeta? debugMeta,
    List<SentryException>? exceptions,
    List<SentryThread>? threads,
    String? type,
  }) =>
      SentryEvent(
        eventId: eventId ?? this.eventId,
        timestamp: timestamp ?? this.timestamp,
        platform: platform ?? this.platform,
        logger: logger ?? this.logger,
        serverName: serverName ?? this.serverName,
        release: release ?? this.release,
        dist: dist ?? this.dist,
        environment: environment ?? this.environment,
        modules: (modules != null ? Map.from(modules) : null) ?? this.modules,
        message: message ?? this.message,
        transaction: transaction ?? this.transaction,
        throwable: throwable ?? _throwable,
        level: level ?? this.level,
        culprit: culprit ?? this.culprit,
        tags: (tags != null ? Map.from(tags) : null) ?? this.tags,
        // ignore: deprecated_member_use_from_same_package
        extra: (extra != null ? Map.from(extra) : null) ?? this.extra,
        fingerprint: (fingerprint != null ? List.from(fingerprint) : null) ??
            this.fingerprint,
        user: user ?? this.user,
        contexts: contexts ?? this.contexts,
        breadcrumbs: (breadcrumbs != null ? List.from(breadcrumbs) : null) ??
            this.breadcrumbs,
        sdk: sdk ?? this.sdk,
        request: request ?? this.request,
        debugMeta: debugMeta ?? this.debugMeta,
        exceptions: (exceptions != null ? List.from(exceptions) : null) ??
            this.exceptions,
        threads: (threads != null ? List.from(threads) : null) ?? this.threads,
        type: type ?? this.type,
        unknown: unknown,
      );

  /// Deserializes a [SentryEvent] from JSON [Map].
  factory SentryEvent.fromJson(Map<String, dynamic> data) {
    final json = AccessAwareMap(data);

    final breadcrumbsJson = json['breadcrumbs'] as List<dynamic>?;
    final breadcrumbs = breadcrumbsJson
        ?.map((e) => Breadcrumb.fromJson(e))
        .toList(growable: false);

    final threadValues = json['threads']?['values'] as List<dynamic>?;
    final threads = threadValues
        ?.map((e) => SentryThread.fromJson(e))
        .toList(growable: false);

    final exceptionValues = json['exception']?['values'] as List<dynamic>?;
    final exceptions = exceptionValues
        ?.map((e) => SentryException.fromJson(e))
        .toList(growable: false);

    final modules = json['modules']?.cast<String, String>();
    final tags = json['tags']?.cast<String, String>();

    final timestampJson = json['timestamp'];
    final levelJson = json['level'];
    final fingerprintJson = json['fingerprint'] as List<dynamic>?;
    final sdkVersionJson = json['sdk'] as Map<String, dynamic>?;
    final messageJson = json['message'] as Map<String, dynamic>?;
    final userJson = json['user'] as Map<String, dynamic>?;
    final contextsJson = json['contexts'] as Map<String, dynamic>?;
    final requestJson = json['request'] as Map<String, dynamic>?;
    final debugMetaJson = json['debug_meta'] as Map<String, dynamic>?;

    var extra = json['extra'];
    if (extra != null) {
      extra = Map<String, dynamic>.from(extra as Map);
    }

    return SentryEvent(
      eventId: SentryId.fromId(json['event_id']),
      timestamp:
          timestampJson != null ? DateTime.tryParse(timestampJson) : null,
      modules: modules,
      tags: tags,
      // ignore: deprecated_member_use_from_same_package
      extra: extra,
      fingerprint:
          fingerprintJson?.map((e) => e as String).toList(growable: false),
      breadcrumbs: breadcrumbs,
      sdk: sdkVersionJson != null && sdkVersionJson.isNotEmpty
          ? SdkVersion.fromJson(sdkVersionJson)
          : null,
      platform: json['platform'],
      logger: json['logger'],
      serverName: json['server_name'],
      release: json['release'],
      dist: json['dist'],
      environment: json['environment'],
      message: messageJson != null && messageJson.isNotEmpty
          ? SentryMessage.fromJson(messageJson)
          : null,
      transaction: json['transaction'],
      threads: threads,
      level: levelJson != null ? SentryLevel.fromName(levelJson) : null,
      culprit: json['culprit'],
      user: userJson != null && userJson.isNotEmpty
          ? SentryUser.fromJson(userJson)
          : null,
      contexts: contextsJson != null && contextsJson.isNotEmpty
          ? Contexts.fromJson(contextsJson)
          : null,
      request: requestJson != null && requestJson.isNotEmpty
          ? SentryRequest.fromJson(requestJson)
          : null,
      debugMeta: debugMetaJson != null && debugMetaJson.isNotEmpty
          ? DebugMeta.fromJson(debugMetaJson)
          : null,
      exceptions: exceptions,
      type: json['type'],
      unknown: json.notAccessed(),
    );
  }

  /// Serializes this event to JSON.
  Map<String, dynamic> toJson() {
    var messageMap = message?.toJson();
    final contextsMap = contexts.toJson();
    final userMap = user?.toJson();
    final sdkMap = sdk?.toJson();
    final requestMap = request?.toJson();
    final debugMetaMap = debugMeta?.toJson();
    final exceptionsJson = exceptions
        ?.map((e) => e.toJson())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    // Thread serialization is tricky:
    // - Thread should not have a stacktrace when an exception is connected to it
    // - Thread should serializae a stacktrace when no exception is connected to it

    // These are the thread ids with a connected exception
    final threadIds = exceptions
        ?.map((element) => element.threadId)
        .where((element) => element != null)
        .toSet();

    final threadJson = threads
        ?.map((element) {
          if (threadIds?.contains(element.id) ?? false) {
            // remove thread.stacktrace if a connected exception exists
            final json = element.toJson();
            json.remove('stacktrace');
            return json;
          }
          return element.toJson();
        })
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    return {
      ...?unknown,
      'event_id': eventId.toString(),
      if (timestamp != null)
        'timestamp': formatDateAsIso8601WithMillisPrecision(timestamp!),
      if (platform != null) 'platform': platform,
      if (logger != null) 'logger': logger,
      if (serverName != null) 'server_name': serverName,
      if (release != null) 'release': release,
      if (dist != null) 'dist': dist,
      if (environment != null) 'environment': environment,
      if (modules != null && modules!.isNotEmpty) 'modules': modules,
      if (transaction != null) 'transaction': transaction,
      if (level != null) 'level': level!.name,
      if (culprit != null) 'culprit': culprit,
      if (tags?.isNotEmpty ?? false) 'tags': tags,
      // ignore: deprecated_member_use_from_same_package
      if (extra?.isNotEmpty ?? false) 'extra': extra,
      if (type != null) 'type': type,
      if (fingerprint?.isNotEmpty ?? false) 'fingerprint': fingerprint,
      if (breadcrumbs?.isNotEmpty ?? false)
        'breadcrumbs':
            breadcrumbs?.map((b) => b.toJson()).toList(growable: false),
      if (messageMap?.isNotEmpty ?? false) 'message': messageMap,
      if (contextsMap.isNotEmpty) 'contexts': contextsMap,
      if (userMap?.isNotEmpty ?? false) 'user': userMap,
      if (sdkMap?.isNotEmpty ?? false) 'sdk': sdkMap,
      if (requestMap?.isNotEmpty ?? false) 'request': requestMap,
      if (debugMetaMap?.isNotEmpty ?? false) 'debug_meta': debugMetaMap,
      if (exceptionsJson?.isNotEmpty ?? false)
        'exception': {'values': exceptionsJson},
      if (threadJson?.isNotEmpty ?? false) 'threads': {'values': threadJson},
    };
  }

  // Returns first non-null stack trace of this event
  @internal
  SentryStackTrace? get stacktrace =>
      exceptions?.firstWhereOrNull((e) => e.stackTrace != null)?.stackTrace ??
      threads?.firstWhereOrNull((t) => t.stacktrace != null)?.stacktrace;
}
