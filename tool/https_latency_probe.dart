import 'dart:convert';
import 'dart:io';

import 'package:meow_client/core/network/https_latency_probe.dart';

const help = '''HTTPS latency probe (measurement only)
Usage: dart run tool/https_latency_probe.dart --context LABEL --url https://host/path [--url URL] [--samples 3] [--timeout 10] [--max-body-bytes 65536] [--http-proxy http://host:port] [--output FILE]
LABEL is required and identifies the tested context (for example sandbox-control-not-phone).
''';

Future<void> main(List<String> args) async {
  try {
    if (args.isEmpty || args.contains('--help') || args.contains('-h')) {
      stdout.write(help);
      return;
    }
    final values = <String, List<String>>{};
    const allowed = {
      '--context',
      '--url',
      '--samples',
      '--timeout',
      '--max-body-bytes',
      '--http-proxy',
      '--output',
    };
    for (var i = 0; i < args.length; i++) {
      final key = args[i];
      if (!allowed.contains(key) ||
          i + 1 >= args.length ||
          args[i + 1].startsWith('--')) {
        throw FormatException('Invalid arguments');
      }
      (values[key] ??= []).add(args[++i]);
    }
    String one(String key, {String? fallback}) {
      final found = values[key];
      if (found == null) {
        if (fallback != null) return fallback;
        throw FormatException('Missing $key');
      }
      if (found.length != 1) throw FormatException('Repeated $key');
      return found.single;
    }

    final context = one('--context');
    final urls = values['--url'] ?? const <String>[];
    final samples = int.parse(one('--samples', fallback: '3'));
    final seconds = int.parse(one('--timeout', fallback: '10'));
    final maxBytes = int.parse(one('--max-body-bytes', fallback: '65536'));
    if (context.trim().isEmpty ||
        urls.isEmpty ||
        urls.length > 5 ||
        samples < 1 ||
        samples > 10 ||
        seconds < 1 ||
        seconds > 30 ||
        maxBytes < 1 ||
        maxBytes > 1048576) {
      throw FormatException('Argument outside allowed range');
    }
    final targets = urls.map(validateProbeUrl).toList();
    final proxyValues = values['--http-proxy'];
    if (proxyValues != null && proxyValues.length != 1) {
      throw FormatException('Repeated --http-proxy');
    }
    final proxyValue = proxyValues?.single;
    final proxy = proxyValue == null ? null : validateProxy(proxyValue);
    final outputPath = values['--output'] == null ? null : one('--output');
    final output = <String, Object?>{
      'schemaVersion': 1,
      'context': context,
      'method': 'GET',
      'timingDefinitions': {
        'headerMs': 'request start to response headers',
        'bodyMs': 'request start to complete response body; not body-only time',
        'verifiedReused': 'same client and matching known socket tuple',
      },
      'clientProxyMode': proxy == null
          ? 'environment-default'
          : 'explicit-http-connect-no-direct-fallback',
      'samplePairsPerTarget': samples,
      'requestTimeoutSeconds': seconds,
      'maxResponseBodyBytes': maxBytes,
      'targets': <Object>[],
    };
    for (final uri in targets) {
      final clientFactory = proxy == null
          ? null
          : () {
              final c = HttpClient();
              final authority = proxy.hasPort
                  ? proxy.authority
                  : '${proxy.authority}:${proxy.port}';
              c.findProxy = (_) => 'PROXY $authority';
              return c;
            };
      final probe = HttpsLatencyProbe(
        timeout: Duration(seconds: seconds),
        maxBodyBytes: maxBytes,
        clientFactory: clientFactory,
      );
      final pairs = <ProbePair>[];
      for (var i = 0; i < samples; i++) {
        pairs.add(await probe.measurePair(uri));
      }
      final newTimes = pairs
          .where((p) => p.first.outcome == 'success')
          .map((p) => p.first.bodyMs!)
          .toList();
      final newHeaderTimes = pairs
          .where((p) => p.first.outcome == 'success')
          .map((p) => p.first.headerMs!)
          .toList();
      final warmHeaderTimes = pairs
          .where(
            (p) => p.second.outcome == 'success' && p.second.reused == true,
          )
          .map((p) => p.second.headerMs!)
          .toList();
      final warmTimes = pairs
          .where(
            (p) => p.second.outcome == 'success' && p.second.reused == true,
          )
          .map((p) => p.second.bodyMs!)
          .toList();
      int count(String outcome) => pairs.fold<int>(
        0,
        (n, p) =>
            n +
            (p.first.outcome == outcome ? 1 : 0) +
            (p.second.outcome == outcome ? 1 : 0),
      );
      (output['targets'] as List).add({
        'url': uri.toString(),
        'pairs': pairs.map((p) => p.toJson()).toList(),
        'summary': {
          'newClientBodyMedianMs': newTimes.isEmpty ? null : median(newTimes),
          'newClientHeaderMedianMs': newHeaderTimes.isEmpty
              ? null
              : median(newHeaderTimes),
          'verifiedReuseHeaderMedianMs': warmHeaderTimes.isEmpty
              ? null
              : median(warmHeaderTimes),
          'verifiedReuseBodyMedianMs': warmTimes.isEmpty
              ? null
              : median(warmTimes),
          'failed':
              count('transport_error') +
              count('tls_error') +
              count('http_error') +
              count('timeout') +
              count('body_too_large'),
          'timedOut': count('timeout'),
          'successful': count('success'),
          'newClientSuccessful': newTimes.length,
          'bodyTooLarge': count('body_too_large'),
          'skipped': count('skipped'),
          'reconnected': pairs
              .where(
                (p) =>
                    p.second.outcome == 'success' && p.second.reused == false,
              )
              .length,
          'reuseUnknown': pairs
              .where(
                (p) => p.second.outcome == 'success' && p.second.reused == null,
              )
              .length,
          'verifiedReused': warmTimes.length,
        },
      });
    }
    final text = const JsonEncoder.withIndent('  ').convert(output);
    if (outputPath == null) {
      stdout.writeln(text);
    } else {
      await File(outputPath).writeAsString('$text\n');
    }
  } on Object catch (error) {
    stderr.writeln(
      'Argument error: ${error is FormatException ? error.message : 'invalid value'}',
    );
    stderr.write(help);
    exitCode = 2;
  }
}
