import 'package:collection/collection.dart';
import 'package:sentry/sentry.dart';
import 'package:test/test.dart';

import '../mocks.dart';

void main() {
  final sentryUser = SentryUser(
    id: 'id',
    username: 'username',
    email: 'email',
    ipAddress: 'ipAddress',
    data: {'key': 'value'},
    unknown: testUnknown,
  );

  final sentryUserJson = <String, dynamic>{
    'id': 'id',
    'username': 'username',
    'email': 'email',
    'ip_address': 'ipAddress',
    'data': {'key': 'value'},
  };
  sentryUserJson.addAll(testUnknown);

  group('json', () {
    test('toJson', () {
      final json = sentryUser.toJson();

      print("$json");

      expect(
        DeepCollectionEquality().equals(sentryUserJson, json),
        true,
      );
    });
    test('fromJson', () {
      final sentryUser = SentryUser.fromJson(sentryUserJson);
      final json = sentryUser.toJson();

      expect(
        DeepCollectionEquality().equals(sentryUserJson, json),
        true,
      );
    });

    test('toJson only serialises non-null values', () {
      var data = SentryUser(id: 'id');

      var json = data.toJson();

      expect(json.containsKey('id'), true);
      expect(json.containsKey('username'), false);
      expect(json.containsKey('email'), false);
      expect(json.containsKey('ip_address'), false);
      expect(json.containsKey('extras'), false);

      data = SentryUser(ipAddress: 'ip');

      json = data.toJson();

      expect(json.containsKey('id'), false);
      expect(json.containsKey('username'), false);
      expect(json.containsKey('email'), false);
      expect(json.containsKey('ip_address'), true);
      expect(json.containsKey('extras'), false);
    });
  });

  group('copyWith', () {
    test('copyWith keeps unchanged', () {
      final data = sentryUser;

      // ignore: deprecated_member_use_from_same_package
      final copy = data.copyWith();

      expect(data.toJson(), copy.toJson());
    });

    test('copyWith takes new values', () {
      final data = sentryUser;
      // ignore: deprecated_member_use_from_same_package
      final copy = data.copyWith(
        id: 'id1',
        username: 'username1',
        email: 'email1',
        ipAddress: 'ipAddress1',
        data: {'key1': 'value1'},
      );

      expect('id1', copy.id);
      expect('username1', copy.username);
      expect('email1', copy.email);
      expect('ipAddress1', copy.ipAddress);
      expect({'key1': 'value1'}, copy.data);
    });
  });
}
