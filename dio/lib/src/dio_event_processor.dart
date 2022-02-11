// ignore_for_file: implementation_imports

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry/src/sentry_exception_factory.dart';

/// This is an [EventProcessor], which improves crash reports of [DioError]s.
/// It adds information about [DioError.response] if present and also about
/// the inner exceptions.
class DioEventProcessor implements EventProcessor {
  /// This is an [EventProcessor], which improves crash reports of [DioError]s.
  DioEventProcessor(this._options, this._maxRequestBodySize);

  final SentryOptions _options;
  final MaxRequestBodySize _maxRequestBodySize;

  SentryExceptionFactory get _sentryExceptionFactory =>
      // ignore: invalid_use_of_internal_member
      _options.exceptionFactory;

  @override
  FutureOr<SentryEvent?> apply(SentryEvent event, {dynamic hint}) {
    final dynamic dioError = event.throwable;
    if (dioError is! DioError) {
      return event;
    }

    final innerDioStackTrace = dioError.stackTrace;
    final innerDioErrorException = dioError.error as Object?;

    // Don't override just parts of the original request.
    // Keep the original one or if there's none create one.
    final request = event.request ?? _requestFrom(dioError);

    // If the inner errors stacktrace is null, there's no point in creating
    // a chained exception. We can still add request information, so we do that.
    if (innerDioStackTrace == null) {
      return event.copyWith(request: request);
    }

    try {
      final exception = _sentryExceptionFactory.getSentryException(
        innerDioErrorException ?? 'DioError inner stacktrace',
        stackTrace: innerDioStackTrace,
      );

      final exceptions = _removeDioErrorStackTraceFromValue(event, dioError);

      return event.copyWith(
        exceptions: [
          exception,
          ...exceptions,
        ],
        request: request,
      );
    } catch (e, stackTrace) {
      _options.logger(
        SentryLevel.debug,
        'Could not convert DioError to SentryException',
        exception: e,
        stackTrace: stackTrace,
      );
    }
    return event;
  }

  /// Remove the StackTrace from [dioError] so the message on Sentry looks
  /// much better.
  List<SentryException> _removeDioErrorStackTraceFromValue(
    SentryEvent event,
    DioError dioError,
  ) {
    // Don't edit the original list
    final exceptions = List<SentryException>.from(
      event.exceptions ?? <SentryException>[],
    );

    final dioErrorValue = dioError.toString();

    var dioSentryException = exceptions
        .where((element) => element.value == dioErrorValue)
        .toList()
        .first;

    exceptions.removeWhere((element) => element == dioSentryException);

    // remove stacktrace, so that it looks better on Sentry.io
    dioError.stackTrace = null;
    dioSentryException = dioSentryException.copyWith(
      value: dioError.toString(),
    );

    exceptions.add(dioSentryException);

    return exceptions;
  }

  SentryRequest? _requestFrom(DioError dioError) {
    final options = dioError.requestOptions;
    // As far as I can tell there's no way to get the uri without the query part
    // so we replace it with an empty string.
    final urlWithoutQuery = options.uri.replace(query: '').toString();

    final query = options.uri.query.isEmpty ? null : options.uri.query;

    final headers = options.headers
        .map((key, dynamic value) => MapEntry(key, value?.toString() ?? ''));

    return SentryRequest(
      method: options.method,
      headers: _options.sendDefaultPii ? headers : null,
      url: urlWithoutQuery,
      queryString: query,
      cookies: _options.sendDefaultPii
          ? options.headers['Cookie']?.toString()
          : null,
      data: _getRequestData(dioError.response?.data),
    );
  }

  /// Returns the request data, if possible according to the users settings.
  /// Type checks are based on DIOs [ResponseType].
  Object? _getRequestData(dynamic data) {
    if (!_options.sendDefaultPii) {
      return null;
    }
    if (data is String) {
      if (_maxRequestBodySize.shouldAddBody(data.codeUnits.length)) {
        return data;
      }
    } else if (data is List<int>) {
      if (_maxRequestBodySize.shouldAddBody(data.length)) {
        return data;
      }
    }
    return null;
  }
}
