import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:meow_client/data/local/app_settings_store.dart';
import 'package:meow_client/data/routing/custom_routing_rule.dart';
import 'package:meow_client/data/routing/google_play_routing_preset.dart';

void main() {
  group('Google Play routing preset', () {
    test('uses dynamic SagerNet geosites and screenshot app/domain rules', () {
      expect(googlePlayPresetPackageNames, contains('com.android.vending'));
      expect(googlePlayPresetPackageNames, contains('com.google.android.gms'));
      expect(googlePlayPresetDomainSuffixes, contains('googleapis.cn'));
      expect(
        googlePlayPresetDomainSuffixes,
        contains('xn--ngstr-cn-8za9o.com'),
      );
      expect(googlePlayPresetDomainSuffixes, contains('gvt6.com'));
      expect(googlePlayPresetGeositeTags, contains(googlePlayPresetGeositeTag));
      expect(googlePlayPresetGeositeTags, contains(googleCnPresetGeositeTag));
      expect(
        googlePlayGeositeUrl,
        'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-google-play.srs',
      );
      expect(
        googleCnGeositeUrl,
        'https://cdn.jsdelivr.net/gh/SagerNet/sing-geosite@rule-set/geosite-google@cn.srs',
      );
      expect(googlePlayCustomProxyRules.map((rule) => rule.value), [
        'dl.google.com',
        'play.google.com',
        'play.googleapis.com',
      ]);
    });

    test('merges the three proxy domains without dropping existing rules', () {
      final existing = <CustomRoutingRule>[
        CustomRoutingRule.create(
          type: CustomRouteRuleType.domain,
          value: 'dl.google.com',
          action: CustomRouteAction.direct,
        ),
        CustomRoutingRule.create(
          type: CustomRouteRuleType.ip,
          value: '203.0.113.0/24',
          action: CustomRouteAction.direct,
        ),
      ];

      final merged = mergeGooglePlayCustomProxyRules(existing);

      expect(merged, hasLength(4));
      expect(merged.first.key, existing.first.key);
      expect(merged.first.action, CustomRouteAction.proxy);
      expect(merged[1].key, existing[1].key);
      expect(
        merged.skip(2).map((rule) => rule.value),
        containsAll(['play.google.com', 'play.googleapis.com']),
      );
    });

    test('reserves room for all three migrated domains at the old limit', () {
      final existing = List<CustomRoutingRule>.generate(
        256,
        (index) => CustomRoutingRule.create(
          type: CustomRouteRuleType.domain,
          value: 'existing$index.example.com',
          action: index.isEven
              ? CustomRouteAction.direct
              : CustomRouteAction.proxy,
        ),
      );

      final merged = mergeGooglePlayCustomProxyRules(existing);

      expect(merged, hasLength(259));
      expect(
        merged.take(existing.length).map((rule) => rule.key),
        existing.map((rule) => rule.key),
      );
      expect(merged.last.value, 'play.googleapis.com');
      expect(maxCustomRouteRuleCount, 259);
    });
  });

  test('Hive migration is additive and runs only once', () async {
    final directory = await Directory.systemTemp.createTemp(
      'google-play-routing-migration-',
    );
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('settings');
    try {
      await box.put(
        'custom_routing_rules',
        jsonEncode([
          {'type': 'domain', 'value': 'dl.google.com', 'action': 'direct'},
          {'type': 'ip', 'value': '203.0.113.0/24', 'action': 'direct'},
        ]),
      );
      await migrateGooglePlayCustomProxyDomains(box);

      final migrated = CustomRoutingRule.decodeStorage(
        box.get('custom_routing_rules'),
      );
      expect(migrated, hasLength(4));
      expect(migrated.first.value, 'dl.google.com');
      expect(migrated.first.action, CustomRouteAction.proxy);
      expect(migrated[1].value, '203.0.113.0/24');

      await box.put(
        'custom_routing_rules',
        jsonEncode([
          {'type': 'domain', 'value': 'manual.example', 'action': 'direct'},
        ]),
      );
      await migrateGooglePlayCustomProxyDomains(box);
      expect(
        CustomRoutingRule.decodeStorage(
          box.get('custom_routing_rules'),
        ).map((rule) => rule.value),
        ['manual.example'],
      );
      expect(
        AppSettingsStore.safeExportKeys,
        isNot(contains('google_play_custom_rules_migrated_v1')),
      );
    } finally {
      await box.close();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('malformed legacy custom rules are backed up before merge', () async {
    final directory = await Directory.systemTemp.createTemp(
      'google-play-routing-malformed-',
    );
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('settings');
    try {
      await box.put('custom_routing_rules', '{not-json');
      await migrateGooglePlayCustomProxyDomains(box);

      expect(
        box.get('custom_routing_rules_before_google_play_migration_v1'),
        '{not-json',
      );
      expect(
        CustomRoutingRule.decodeStorage(box.get('custom_routing_rules')),
        hasLength(3),
      );
    } finally {
      await box.close();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });

  test('partially malformed rule lists are backed up before merge', () async {
    final directory = await Directory.systemTemp.createTemp(
      'google-play-routing-partial-',
    );
    Hive.init(directory.path);
    final box = await Hive.openBox<dynamic>('settings');
    try {
      final raw = jsonEncode([
        {'type': 'domain', 'value': 'manual.example', 'action': 'direct'},
        'invalid-entry',
      ]);
      await box.put('custom_routing_rules', raw);
      await migrateGooglePlayCustomProxyDomains(box);

      expect(
        box.get('custom_routing_rules_before_google_play_migration_v1'),
        raw,
      );
      expect(
        CustomRoutingRule.decodeStorage(box.get('custom_routing_rules')),
        hasLength(4),
      );
    } finally {
      await box.close();
      await Hive.close();
      await directory.delete(recursive: true);
    }
  });
}
