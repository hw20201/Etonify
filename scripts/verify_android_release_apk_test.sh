#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
verifier="$script_dir/verify_android_release_apk.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

expected_sha256='f1e431ddbefe3496db75f264a0dd02472c7a4be704f8f78c7bd834c146f9f665'
different_sha256='0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
sdk_root="$tmp_dir/android-sdk"
build_tools="$sdk_root/build-tools/37.0.0"
apk="$tmp_dir/fixture.apk"
mkdir -p "$build_tools"
printf 'fixture apk\n' > "$apk"

cat > "$build_tools/aapt" <<'AAPT'
#!/usr/bin/env bash
set -euo pipefail
printf "%s\n" "package: name='com.etonify.meow_client' versionCode='${FAKE_APK_VERSION_CODE:-4048}' versionName='${FAKE_APK_VERSION_NAME:-0.3.101}' platformBuildVersionName='16' platformBuildVersionCode='36'"
AAPT

cat > "$build_tools/apksigner" <<'APKSIGNER'
#!/usr/bin/env bash
set -euo pipefail
case "${FAKE_APKSIGNER_FORMAT:?FAKE_APKSIGNER_FORMAT is required}" in
  legacy)
    printf '%s\n' 'Verifies' 'Signer #1 certificate SHA-256 digest: F1:E4:31:DD:BE:FE:34:96:DB:75:F2:64:A0:DD:02:47:2C:7A:4B:E7:04:F8:F7:8C:7B:D8:34:C1:46:F9:F6:65'
    ;;
  v2)
    printf '%s\n' 'Verifies' 'V2 Signer: certificate SHA-256 digest: f1e431ddbefe3496db75f264a0dd02472c7a4be704f8f78c7bd834c146f9f665'
    ;;
  mismatch)
    printf '%s\n' 'Verifies' 'V2 Signer: certificate SHA-256 digest: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    ;;
  missing)
    printf '%s\n' 'Verifies'
    ;;
  multiple)
    printf '%s\n' \
      'V2 Signer: certificate SHA-256 digest: f1e431ddbefe3496db75f264a0dd02472c7a4be704f8f78c7bd834c146f9f665' \
      'V3 Signer: certificate SHA-256 digest: 0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
    ;;
  *)
    echo "Unknown fake apksigner output format." >&2
    exit 2
    ;;
esac
APKSIGNER
chmod +x "$build_tools/aapt" "$build_tools/apksigner"

run_success_case() {
  local format="$1"
  local output="$tmp_dir/${format}.out"
  ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT="$format" FAKE_APK_VERSION_CODE=4048 \
    bash "$verifier" "$apk" '0.3.101' '4048' '4047' "$expected_sha256" > "$output"
  grep -Fq 'versionCode=4048' "$output"
  grep -Fq "certificateSha256=$expected_sha256" "$output"
}

run_success_case legacy
run_success_case v2

ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=v2 FAKE_APK_VERSION_CODE=6054 FAKE_APK_VERSION_NAME=0.3.104 \
  bash "$verifier" "$apk" '0.3.104' '4054' '6053' "$expected_sha256" > "$tmp_dir/upgrade-6054.out"
grep -Fq 'versionCode=6054' "$tmp_dir/upgrade-6054.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=v2 FAKE_APK_VERSION_CODE=6053 FAKE_APK_VERSION_NAME=0.3.104 \
  bash "$verifier" "$apk" '0.3.104' '4054' '6053' "$expected_sha256" > "$tmp_dir/baseline-6053.out" 2>&1; then
  echo 'Expected the installed v0.3.103 versionCode 6053 to be rejected.' >&2
  exit 1
fi
grep -Fq 'APK versionCode 6053 must be greater than installed baseline 6053.' "$tmp_dir/baseline-6053.out"

ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=v2 FAKE_APK_VERSION_CODE=6053 FAKE_APK_VERSION_NAME=0.3.103 \
  bash "$verifier" "$apk" '0.3.103' '4053' '6052' "$expected_sha256" > "$tmp_dir/upgrade-6053.out"
grep -Fq 'versionCode=6053' "$tmp_dir/upgrade-6053.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=v2 FAKE_APK_VERSION_CODE=6052 FAKE_APK_VERSION_NAME=0.3.103 \
  bash "$verifier" "$apk" '0.3.103' '4053' '6052' "$expected_sha256" > "$tmp_dir/old-draft-6052.out" 2>&1; then
  echo 'Expected the old Draft APK versionCode 6052 to be rejected.' >&2
  exit 1
fi
grep -Fq 'APK versionCode 6052 must be greater than installed baseline 6052.' "$tmp_dir/old-draft-6052.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=v2 FAKE_APK_VERSION_CODE=4047 \
  bash "$verifier" "$apk" '0.3.101' '4047' '4047' "$expected_sha256" > "$tmp_dir/baseline.out" 2>&1; then
  echo 'Expected an APK at the installed baseline versionCode to be rejected.' >&2
  exit 1
fi
grep -Fq 'APK versionCode 4047 must be greater than installed baseline 4047.' "$tmp_dir/baseline.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=mismatch \
  bash "$verifier" "$apk" '0.3.101' '4048' '4047' "$expected_sha256" > "$tmp_dir/mismatch.out" 2>&1; then
  echo 'Expected a mismatched certificate to be rejected.' >&2
  exit 1
fi
grep -Fq 'APK signing certificate does not match the existing release certificate.' "$tmp_dir/mismatch.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=missing \
  bash "$verifier" "$apk" '0.3.101' '4048' '4047' "$expected_sha256" > "$tmp_dir/missing.out" 2>&1; then
  echo 'Expected missing certificate metadata to be rejected.' >&2
  exit 1
fi
grep -Fq 'No certificate SHA-256 digest found in apksigner output.' "$tmp_dir/missing.out"

if ANDROID_SDK_ROOT="$sdk_root" FAKE_APKSIGNER_FORMAT=multiple \
  bash "$verifier" "$apk" '0.3.101' '4048' '4047' "$expected_sha256" > "$tmp_dir/multiple.out" 2>&1; then
  echo 'Expected conflicting signer certificates to be rejected.' >&2
  exit 1
fi
grep -Fq 'APK contains multiple distinct signing certificate SHA-256 digests.' "$tmp_dir/multiple.out"

printf '%s\n' 'APK verifier regression tests passed (legacy, apksigner 0.9, upgrade 6054, reject baseline 6053, upgrade 6053, old Draft 6052, baseline, mismatch, missing, multiple).'
