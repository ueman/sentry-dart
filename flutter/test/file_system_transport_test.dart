import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry/sentry.dart';
import 'package:sentry_flutter/src/file_system_transport.dart';

void main() {
  const MethodChannel _channel = MethodChannel('sentry_flutter');

  TestWidgetsFlutterBinding.ensureInitialized();

  Fixture fixture;

  setUp(() {
    fixture = Fixture();
  });

  tearDown(() {
    _channel.setMockMethodCallHandler(null);
  });

  test('FileSystemTransport wont throw', () async {
    _channel.setMockMethodCallHandler((MethodCall methodCall) async {});

    final transport = fixture.getSut(_channel);
    final event = SentryEvent();

    final sentryId = await transport.send(event);

    expect(sentryId, sentryId);
  });

  test('FileSystemTransport returns emptyId if channel throws', () async {
    _channel.setMockMethodCallHandler((MethodCall methodCall) async {
      throw null;
    });

    final transport = fixture.getSut(_channel);

    final sentryId = await transport.send(SentryEvent());

    expect(SentryId.empty(), sentryId);
  });

  test('FileSystemTransport asserts the event', () async {
    dynamic arguments;
    _channel.setMockMethodCallHandler((MethodCall methodCall) async {
      arguments = methodCall.arguments;
    });

    final transport = fixture.getSut(_channel);

    final event = SentryEvent();
    await transport.send(event);

    final envelopeList = arguments as List;
    final envelopeString = envelopeList.first as String;
    final lines = envelopeString.split('\n');
    final envelopeHeader = lines.first;
    final itemHeader = lines[1];
    final item = lines[2];

    final envelopeHeaderMap =
        jsonDecode(envelopeHeader) as Map<String, dynamic>;
    expect(event.eventId.toString(), envelopeHeaderMap['event_id']);

    // just checking its there, the sdk serialization is already unit tested on
    // the dart module
    expect(envelopeHeaderMap.containsKey('sdk'), isNotNull);

    final itemHeaderMap = jsonDecode(itemHeader) as Map<String, dynamic>;

    final eventString = jsonEncode(event.toJson());

    expect('application/json', itemHeaderMap['content_type']);
    expect('event', itemHeaderMap['type']);
    expect(eventString.length, itemHeaderMap['length']);

    expect(item, eventString);
  });
}

class Fixture {
  FileSystemTransport getSut(MethodChannel channel) {
    final options = SentryOptions();
    return FileSystemTransport(channel, options);
  }
}
