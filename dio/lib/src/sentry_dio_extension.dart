import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:sentry/sentry.dart';
import 'dio_event_processor.dart';
import 'sentry_transformer.dart';
import 'sentry_dio_client_adapter.dart';

/// Extension to add performance tracing for [Dio]
extension SentryDioExtension on Dio {
  /// Adds support for automatic spans for http requests,
  /// as well as request and response transformations.
  /// This must be the last initialization step of the [Dio] setup, otherwise
  /// your configuration of Dio might overwrite the Sentry configuration.
  @experimental
  void addSentry({
    bool recordBreadcrumbs = true,
    bool networkTracing = true,
    MaxRequestBodySize maxRequestBodySize = MaxRequestBodySize.never,
    List<SentryStatusCode> failedRequestStatusCodes = const [],
    bool captureFailedRequests = false,
    Hub? hub,
  }) {
    hub = hub ?? HubAdapter();

    // ignore: invalid_use_of_internal_member
    final options = hub.options;

    // Add DioEventProcessor when it's not already present
    if (options.eventProcessors.whereType<DioEventProcessor>().isEmpty) {
      options.sdk.addIntegration('sentry_dio');
      options.addEventProcessor(DioEventProcessor(options, maxRequestBodySize));
    }

    // intercept http requests
    httpClientAdapter = SentryDioClientAdapter(
      client: httpClientAdapter,
      recordBreadcrumbs: recordBreadcrumbs,
      networkTracing: networkTracing,
      maxRequestBodySize: maxRequestBodySize,
      failedRequestStatusCodes: failedRequestStatusCodes,
      captureFailedRequests: captureFailedRequests,
      sendDefaultPii: options.sendDefaultPii,
      hub: hub,
    );

    // intercept transformations
    transformer = SentryTransformer(
      transformer: transformer,
      hub: hub,
    );
  }
}
