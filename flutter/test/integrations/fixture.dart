import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_flutter/src/native/sentry_native_binding.dart';

import '../mocks.dart';
import '../mocks.mocks.dart';

class IntegrationTestFixture<T extends Integration> {
  late T sut;
  late Hub hub;
  final options = defaultTestOptions();
  final binding = MockSentryNativeBinding();

  IntegrationTestFixture(T Function(SentryNativeBinding) factory) {
    hub = Hub(options);
    sut = factory(binding);
  }

  Future<void> registerIntegration() async {
    await sut.call(hub, options);
  }
}
