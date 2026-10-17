import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meow_client/logging/runtime_diagnostic_log.dart';

void main() {
  group('RuntimeDiagnosticBuffer', () {
    test('compile-time flag matches the requested build define', () {
      const expected = bool.fromEnvironment(
        'ETONIFY_RUNTIME_DIAGNOSTICS',
        defaultValue: false,
      );
      expect(runtimeDiagnosticsBuild, expected);
    });

    test('an explicitly disabled buffer never records', () {
      final buffer = RuntimeDiagnosticBuffer(enabled: false);

      buffer.record('connection.start', fields: {'phase': 'begin'});

      expect(buffer.entries.value, isEmpty);
    });

    test('stores only allow-listed anonymous fields', () {
      final buffer = RuntimeDiagnosticBuffer(enabled: true);
      buffer.record(
        'proxy.selection',
        fields: {
          'phase': 'begin',
          'mode': 'vpn',
          'durationMs': 42,
          'reason': 'vless://uuid@example.invalid?token=secret',
          'subscriptionId': 'private-profile-id',
          'nodeName': 'Tokyo Premium 01',
          'success': true,
        },
      );

      final output = buffer.dump();
      expect(output, contains('"phase":"begin"'));
      expect(output, contains('"durationMs":42'));
      expect(output, contains('"reason":"other"'));
      expect(output, isNot(contains('secret')));
      expect(output, isNot(contains('private-profile-id')));
      expect(output, isNot(contains('Tokyo Premium')));
      expect(output, isNot(contains('subscriptionId')));
    });

    test('keeps only the newest entries when capacity is reached', () {
      final buffer = RuntimeDiagnosticBuffer(enabled: true, maxEntries: 2);
      buffer.record('test.first');
      buffer.record('test.second');
      buffer.record('test.third');

      expect(buffer.entries.value, hasLength(2));
      expect(buffer.dump(), isNot(contains('test.first')));
      expect(buffer.dump(), contains('test.second'));
      expect(buffer.dump(), contains('test.third'));
    });

    test(
      'error summaries retain useful category but not raw host or token',
      () {
        final fields = RuntimeDiagnosticLog.errorFields(
          const SocketException(
            'Failed host lookup: private.example?token=do-not-store',
          ),
        );
        final buffer = RuntimeDiagnosticBuffer(enabled: true);
        buffer.record(
          'native.error',
          fields: fields,
          level: RuntimeDiagnosticLevel.error,
        );

        final output = buffer.dump();
        expect(output, contains('"errorKind":"dns"'));
        expect(output, contains('"errorSummary":"dns_lookup_failed"'));
        expect(output, isNot(contains('private.example')));
        expect(output, isNot(contains('do-not-store')));
      },
    );

    test('classifies common network failures without storing messages', () {
      expect(
        RuntimeDiagnosticLog.errorFields(
          Exception('dial tcp 203.0.113.1:443: i/o timeout'),
        )['errorKind'],
        'timeout',
      );
      expect(
        RuntimeDiagnosticLog.errorFields(
          Exception('connection reset by peer'),
        )['errorSummary'],
        'connection_reset',
      );
      expect(
        RuntimeDiagnosticLog.errorFields(
          Exception('TLS handshake failed for secret.example'),
        )['errorKind'],
        'tls',
      );
    });
  });
}
