# Background VPN recovery implementation plan

> **For agentic workers:** Use superpowers:executing-plans. Track each task with tests before implementation.

**Goal:** Recover the physical Android VPN network without opening Flutter, expose battery optimization settings, and backport scope cleanup filtering.

**Architecture:** The native network monitor owns bounded interface retries. Readiness requires both libbox delivery and Android network binding when a VPN service exists. Battery state is queried from Android, not stored as an app preference.

**Tech Stack:** Kotlin, Robolectric/JUnit, Flutter/Dart, Go.

**Spec:** User-approved in-chat design, 2026-10-11.

## Global constraints

- No APK or native core builds on this PC; host unit tests are allowed.
- Preserve shutdown-race protections and user stop intent.
- NAT commit d2a4dc2 is a separate later stage; Apple cache commit is excluded.
- Initial implementation stays local. User subsequently authorized version 0.3.9+39, pushing verified client/core commits and GitHub release builds. Never publish a mismatched core binary/source pair.

## Review focus

- A VPN may not have established its TUN yet when libbox attaches its listener.
- A successful system-managed fallback must not leave the core ready on a rejected explicit binding.
- Stale retry jobs must not apply an older network or listener after stop/reload.
- No physical network must not trigger endless wake/restart loops.
- Denied battery exemption and missing OEM settings must remain understandable and safe.

### Task 1: Native interface retry and readiness

**Files:** MeowDefaultNetworkMonitor.kt, MeowVpnService.kt, native network tests.

**Interfaces:** Preserve reassertDefaultInterfaceAndWait; require successful Android binding only for VPN, not probe/proxy.

- [x] Add failing Robolectric tests for rejected binding and stale readiness.
- [x] Run :app:testDebugUnitTest against network tests; verify assertion failures.
- [x] Apply bounded retries with cancellation on listener/network generation changes and stop. Retain core initial interface delivery before TUN exists.
- [x] Test late interface availability, successful retry, exhaustion, stop, listener replacement, and handover.
- [x] Run the complete Android host suite.

### Task 2: Battery optimization control

**Files:** BatteryOptimizationSettings.kt, MainActivity.kt, AndroidManifest.xml, battery_optimization.dart, battery_optimization_tile.dart, settings_general_page.dart, English/Russian ARB and tests.

**Interfaces:** Method channel meow_client/battery_optimization: getStatus and openSettings. Status is exempt/restricted/unavailable. Opening returns Boolean.

- [x] Add failing native intent/status tests and Flutter channel/widget tests.
- [x] Verify missing-feature failures, then implement the bridge and lifecycle-aware tile.
- [x] Request exemption only after user tap; use system settings fallback. Refresh on resume, prevent duplicate settings opens and ignore stale status responses, do not fake success after a denial.
- [x] Run Flutter tests, localization generation, and flutter analyze --no-pub.

### Task 3: Core scope cleanup filtering

**Files:** etonify-core/adapter/lifecycle.go and lifecycle_test.go.

**Interfaces:** Scope.Close continues returning real cleanup failures and running every cleanup in reverse order.

- [x] Add failing tests for canceled/closed errors, wrapped multi-errors and real failures; characterize existing late cleanup logging.
- [x] Run go test ./adapter -count=1; verify errors currently leak.
- [x] Port 3ad7a42 filtering without removing late-resource and concurrent-start protections.
- [x] Run adapter tests and race checks if available; do not claim a built libbox artifact until GitHub builds it.

### Task 4: Verification and review

- [x] Run full Flutter suite, full Android host suite, analyze, and git diff --check.
- [x] Fresh whole-change review; fix important findings through regression tests.
- [ ] Report exact results, remaining device-only validation, and deferred NAT work.

### Authorized delivery

- [ ] Commit and push core cleanup fix as v1.15.0-alpha.10-etonify.2.
- [ ] Commit and push client 0.3.9+39 with the verified core gitlink, excluding caches and local test output.
- [ ] Wait for GitHub libbox sync, then launch Android release APK workflow from the binary-synchronized revision.
