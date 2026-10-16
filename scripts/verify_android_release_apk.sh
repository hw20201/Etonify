#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 5 ]]; then
  echo "Usage: $0 APK EXPECTED_VERSION_NAME PUBSPEC_BUILD_NUMBER MINIMUM_VERSION_CODE_EXCLUSIVE EXPECTED_CERTIFICATE_SHA256" >&2
  exit 2
fi

apk="$1"
expected_version_name="$2"
pubspec_build_number="$3"
minimum_version_code="$4"
expected_certificate_sha256="$(printf '%s' "$5" | tr -d ':[:space:]' | tr '[:upper:]' '[:lower:]')"

if [[ ! -s "$apk" ]]; then
  echo "Release APK is missing or empty: $apk" >&2
  exit 1
fi
for value in "$pubspec_build_number" "$minimum_version_code"; do
  if [[ ! "$value" =~ ^[0-9]+$ ]]; then
    echo "Version codes must be non-negative integers." >&2
    exit 1
  fi
done
if [[ ! "$expected_certificate_sha256" =~ ^[0-9a-f]{64}$ ]]; then
  echo "Expected signing certificate fingerprint must be a 64-character SHA-256 hex digest." >&2
  exit 1
fi

sdk_root="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
if [[ -z "$sdk_root" || ! -d "$sdk_root/build-tools" ]]; then
  echo "Android SDK build-tools directory is unavailable." >&2
  exit 1
fi
build_tools_version="$(find "$sdk_root/build-tools" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -n 1)"
aapt="$sdk_root/build-tools/$build_tools_version/aapt"
apksigner="$sdk_root/build-tools/$build_tools_version/apksigner"
if [[ ! -x "$aapt" || ! -x "$apksigner" ]]; then
  echo "aapt or apksigner is unavailable in Android build-tools $build_tools_version." >&2
  exit 1
fi

package_line="$("$aapt" dump badging "$apk" | sed -n '1p')"
package_id="$(sed -nE "s/^package: name='([^']+)'.*/\1/p" <<<"$package_line")"
actual_version_code="$(sed -nE "s/.*versionCode='([0-9]+)'.*/\1/p" <<<"$package_line")"
actual_version_name="$(sed -nE "s/.*versionName='([^']*)'.*/\1/p" <<<"$package_line")"

if [[ "$package_id" != "com.etonify.meow_client" ]]; then
  echo "Unexpected Android package ID: ${package_id:-<missing>}" >&2
  exit 1
fi
if [[ "$actual_version_name" != "$expected_version_name" ]]; then
  echo "APK versionName $actual_version_name does not match expected $expected_version_name." >&2
  exit 1
fi
if [[ ! "$actual_version_code" =~ ^[0-9]+$ ]]; then
  echo "APK has an invalid or missing versionCode." >&2
  exit 1
fi
if (( 10#$actual_version_code < 10#$pubspec_build_number )); then
  echo "APK versionCode $actual_version_code is lower than pubspec build number $pubspec_build_number." >&2
  exit 1
fi
if (( 10#$actual_version_code <= 10#$minimum_version_code )); then
  echo "APK versionCode $actual_version_code must be greater than installed baseline $minimum_version_code." >&2
  exit 1
fi

signature_info="$("$apksigner" verify --verbose --print-certs "$apk" 2>&1)"
actual_certificate_sha256="$(printf '%s\n' "$signature_info" | awk '/Signer #1 certificate SHA-256 digest:/ { sub(/^.*digest:[[:space:]]*/, ""); gsub(/:/, ""); gsub(/[[:space:]]/, ""); print tolower($0); exit }')"
if [[ "$actual_certificate_sha256" != "$expected_certificate_sha256" ]]; then
  echo "APK signing certificate does not match the existing release certificate." >&2
  exit 1
fi

printf 'Verified signed APK: packageId=%s versionName=%s versionCode=%s certificateSha256=%s\n' \
  "$package_id" "$actual_version_name" "$actual_version_code" "$actual_certificate_sha256"
