import 'package:meta/meta.dart';

import 'protocol.dart';
import 'scope.dart';
import 'sentry_options.dart';

class SentryBaggage {
  static const String _sampleRateKeyName = 'sentry-sample_rate';
  static const String _sampleRandKeyName = 'sentry-sample_rand';

  static const int _maxChars = 8192;
  static const int _maxListMember = 64;

  SentryBaggage(
    this._keyValues, {
    this.log,
  });

  final Map<String, String> _keyValues;
  final SdkLogCallback? log;

  String toHeaderString() {
    final buffer = StringBuffer();
    var listMemberCount = 0;
    var separator = '';

    for (final entry in _keyValues.entries) {
      if (listMemberCount >= _maxListMember) {
        log?.call(
          SentryLevel.info,
          'Baggage key ${entry.key} dropped because of max list member.',
        );
        break;
      }
      try {
        final encodedKey = _urlEncode(entry.key);
        final encodedValue = _urlEncode(entry.value);
        final encodedKeyValue = '$separator$encodedKey=$encodedValue';

        final totalLengthIfValueAdded = buffer.length + encodedKeyValue.length;

        if (totalLengthIfValueAdded >= _maxChars) {
          log?.call(
            SentryLevel.info,
            'Baggage key ${entry.key} dropped because of max baggage chars.',
          );
          continue;
        }

        listMemberCount++;
        buffer.write(encodedKeyValue);
        separator = ',';
      } catch (exception, stackTrace) {
        log?.call(
          SentryLevel.error,
          'Failed to parse the baggage key ${entry.key}.',
          exception: exception,
          stackTrace: stackTrace,
        );
        // TODO rethrow in options.automatedTestMode (currently not available here to check)
      }
    }

    return buffer.toString();
  }

  factory SentryBaggage.fromHeaderList(
    List<String> headerValues, {
    SdkLogCallback? log,
  }) {
    final keyValues = <String, String>{};

    for (final headerValue in headerValues) {
      final keyValuesToAdd = _extractKeyValuesFromBaggageString(
        headerValue,
        log: log,
      );
      keyValues.addAll(keyValuesToAdd);
    }

    return SentryBaggage(keyValues, log: log);
  }

  factory SentryBaggage.fromHeader(
    String headerValue, {
    SdkLogCallback? log,
  }) {
    final keyValues = _extractKeyValuesFromBaggageString(
      headerValue,
      log: log,
    );

    return SentryBaggage(keyValues, log: log);
  }

  @internal
  void setValuesFromScope(Scope scope, SentryOptions options) {
    final propagationContext = scope.propagationContext;
    setTraceId(propagationContext.traceId.toString());
    setPublicKey(options.parsedDsn.publicKey);
    if (options.release != null) {
      setRelease(options.release!);
    }
    if (options.environment != null) {
      setEnvironment(options.environment!);
    }
    if (scope.user?.id != null) {
      setUserId(scope.user!.id!);
    }
    if (scope.replayId != null && scope.replayId != SentryId.empty()) {
      setReplayId(scope.replayId.toString());
    }
  }

  static Map<String, String> _extractKeyValuesFromBaggageString(
    String headerValue, {
    SdkLogCallback? log,
  }) {
    final keyValues = <String, String>{};

    final keyValueStrings = headerValue.split(',');

    for (final keyValueString in keyValueStrings) {
      // TODO: Note, value MAY contain any number of the equal sign (=) characters.
      // Parsers MUST NOT assume that the equal sign is only used to separate key and value.
      final keyAndValue = keyValueString.split('=');
      if (keyAndValue.length == 2) {
        try {
          final key = _urlDecode(keyAndValue.first.trim());
          final value = _urlDecode(keyAndValue.last.trim());
          keyValues[key] = value;
        } catch (exception, stackTrace) {
          log?.call(
            SentryLevel.error,
            'Failed to parse the baggage entry $keyAndValue.',
            exception: exception,
            stackTrace: stackTrace,
          );
        }
      }
    }

    return keyValues;
  }

  static String _urlDecode(String uri) {
    return Uri.decodeComponent(uri);
  }

  String _urlEncode(String uri) {
    return Uri.encodeComponent(uri);
  }

  String? get(String key) => _keyValues[key];

  void set(String key, String value) {
    _keyValues[key] = value;
  }

  void setTraceId(String value) {
    set('sentry-trace_id', value);
  }

  void setPublicKey(String value) {
    set('sentry-public_key', value);
  }

  void setEnvironment(String value) {
    set('sentry-environment', value);
  }

  void setRelease(String value) {
    set('sentry-release', value);
  }

  void setUserId(String value) {
    set('sentry-user_id', value);
  }

  void setTransaction(String value) {
    set('sentry-transaction', value);
  }

  void setSampleRate(String value) {
    set(_sampleRateKeyName, value);
  }

  void setSampleRand(String value) {
    set(_sampleRandKeyName, value);
  }

  void setSampled(String value) {
    set('sentry-sampled', value);
  }

  double? getSampleRate() {
    final sampleRate = get(_sampleRateKeyName);
    if (sampleRate == null) {
      return null;
    }

    return double.tryParse(sampleRate);
  }

  double? getSampleRand() {
    final sampleRand = get(_sampleRandKeyName);
    if (sampleRand == null) {
      return null;
    }

    return double.tryParse(sampleRand);
  }

  void setReplayId(String value) => set('sentry-replay_id', value);

  SentryId? getReplayId() {
    final replayId = get('sentry-replay_id');
    return replayId == null ? null : SentryId.fromId(replayId);
  }

  Map<String, String> get keyValues => Map.unmodifiable(_keyValues);
}
