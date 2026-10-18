import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android workflow builds master artifacts and signed tag drafts', () {
    final workflow = File(
      '.github/workflows/android-release.yml',
    ).readAsStringSync();

    expect(workflow, contains('branches:'));
    expect(workflow, contains('- master'));
    expect(workflow, contains('tags:'));
    expect(workflow, contains('- "v*"'));
    expect(workflow, contains('workflow_dispatch'));
    expect(workflow, contains('release_tag:'));
    expect(workflow, contains('name: Build arm64 APK artifact'));
    expect(workflow, contains('MEOW_ALLOW_DEBUG_RELEASE_SIGNING: "true"'));
    expect(workflow, contains(r'etonify-arm64-v8a-${GITHUB_SHA::7}.apk'));
    expect(workflow, contains('uses: actions/upload-artifact@'));
    expect(workflow, contains('retention-days: 14'));

    expect(workflow, contains('draft-tag-release:'));
    expect(workflow, contains("startsWith(github.ref, 'refs/tags/v')"));
    expect(workflow, contains("inputs.release_tag == ''"));
    expect(workflow, contains("inputs.release_tag != ''"));
    expect(workflow, contains("github.ref == 'refs/heads/release/v0.3.101'"));
    expect(workflow, contains("inputs.release_tag == 'v0.3.101'"));
    expect(workflow, contains(r'ref: ${{ inputs.release_tag || github.ref }}'));
    expect(workflow, contains(r'RELEASE_TAG_INPUT: ${{ inputs.release_tag }}'));
    expect(workflow, contains("github.ref == 'refs/heads/master'"));
    expect(workflow, contains('MINIMUM_UPGRADE_VERSION_CODE: "6051"'));
    expect(
      workflow,
      contains('--dart-define=ETONIFY_RUNTIME_DIAGNOSTICS=false'),
    );
    expect(
      workflow,
      contains(
        'cmp scripts/verify_android_release_apk.sh verifier-fix/scripts/verify_android_release_apk.sh',
      ),
    );
    expect(
      workflow,
      contains('run: bash scripts/verify_android_release_apk_test.sh'),
    );
    final releaseJobStart = workflow.indexOf('  draft-tag-release:');
    final releaseJobEnd = workflow.indexOf('  diagnostic-test-artifact:');
    final releaseJob = workflow.substring(releaseJobStart, releaseJobEnd);
    expect(releaseJob, contains('MINIMUM_UPGRADE_VERSION_CODE: "6054"'));
    expect(releaseJob, contains('Check formatting before signed build'));
    final analyzeIndex = workflow.indexOf(
      '      - name: Analyze and test',
      releaseJobStart,
    );
    final pinnedVerifierIndex = workflow.indexOf(
      '      - name: Checkout pinned APK verifier reference',
      releaseJobStart,
    );
    expect(analyzeIndex, greaterThan(releaseJobStart));
    expect(pinnedVerifierIndex, greaterThan(analyzeIndex));
    expect(workflow, contains('MEOW_ALLOW_DEBUG_RELEASE_SIGNING: "false"'));
    expect(workflow, contains('secrets.ANDROID_KEYSTORE_BASE64'));
    expect(workflow, contains('secrets.ANDROID_KEYSTORE_PASSWORD'));
    expect(workflow, contains('secrets.ANDROID_KEY_ALIAS'));
    expect(workflow, contains('secrets.ANDROID_KEY_PASSWORD'));
    expect(workflow, isNot(contains('ANDROID_RELEASE_')));
    expect(workflow, contains('storeFile=app/etonify-release.jks'));
    expect(workflow, contains('gh release create'));
    expect(workflow, contains(r'gh release create "${RELEASE_TAG}"'));
    expect(workflow, contains('gh release upload'));
    expect(workflow, contains('--draft'));
    expect(
      workflow,
      contains('Add the repository Secret with this exact name'),
    );
    expect(workflow, isNot(contains('x86')));
    expect(
      workflow,
      contains(
        'uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1',
      ),
    );
    expect(
      workflow,
      contains(
        'uses: actions/setup-java@dd06d9cba3e5552c54d9f8ea23572deb30010f7c # v6.0.0',
      ),
    );
    expect(workflow, contains('python3 scripts/verify_libbox.py'));
    expect(workflow, isNot(contains('uses: actions/checkout@v4')));
    expect(workflow, isNot(contains('uses: actions/setup-java@v4')));
  });

  test('Flutter workflows use the release SDK version', () {
    for (final path in const [
      '.github/workflows/ci.yml',
      '.github/workflows/codeql.yml',
      '.github/workflows/android-release.yml',
    ]) {
      final workflow = File(path).readAsStringSync();
      expect(workflow, contains('FLUTTER_VERSION: "3.47.5"'), reason: path);
      expect(workflow, isNot(contains('3.47.0')), reason: path);
    }
  });

  test('core sync workflow uses the release Go toolchain', () {
    final workflow = File(
      '.github/workflows/sync-etonify-core.yml',
    ).readAsStringSync();
    expect(workflow, contains('GO_VERSION: "1.27.1"'));
  });

  test('Debug-signed beta release workflow is removed', () {
    expect(
      File('.github/workflows/android-beta-apk.yml').existsSync(),
      isFalse,
    );
  });
}
