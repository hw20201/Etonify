# Pinned sing-tun Fork Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Исправить три доказанных дефекта NAT/фрагментов в нашем fork sing-tun и гарантировать, что ядро, CI и source archive используют его закреплённый submodule.

**Architecture:** `yamixdev/sing-tun` подключается в core как `third_party/sing-tun`; exact-version local replace сохраняет upstream module path. Fork содержит только исправления, тесты и пояснение отличий. Pin validator, архиватор и provenance связывают фактические Go-исходники с gitlink.

**Tech Stack:** Git nested submodules, Go 1.27.1/race, Python unittest, GitHub Actions, existing Android libbox pipeline.

**Spec:** `docs/superpowers/specs/2026-10-12-sing-tun-fork-fixes-design.md`.

## Global Constraints

- Client master, `0.3.9+39`; core etonify-dev, base `0fe9bbb66cbe998d6ca22a53e3d3a807c3a148f7`. Current checkout, no worktree.
- Fork owner/name `yamixdev/sing-tun`, upstream `SagerNet/sing-tun`, base `5c2edb183cc92eb190d41c04dedfa5519ca3e78c`, branch `codex/etonify-nat-fixes`.
- Require stays `github.com/sagernet/sing-tun v0.9.7-0.20261009022811-5c2edb183cc9`; replace only that version with `./third_party/sing-tun`.
- Fork module path stays `github.com/sagernet/sing-tun`; no other dependency upgrades, no module-cache edits, no `submodule update --remote` in build.
- UDP quarantine `4*time.Minute`; fragment TTL `30*time.Second`, sweep interval `time.Second`, capacity `4096`.
- Preserve uncommitted core reproducer files `common/forwardnat/mapping_test.go` and `release/testdata/singtun/fragment_overlay_test.go`. They are currently RED, not unrelated dirt.
- Preserve previous client/native recovery, scoped shutdown, route-chain and WireGuard fixes. No public libbox API, UI, routing-rule or battery changes.
- Android API 24, targets `android/arm,android/arm64`, tags `with_quic,with_utls,with_naive_outbound,with_clash_api,badlinkname,tfogo_checklinkname0` unchanged.
- No local APK/AAR/Android-core builds. Host tests permitted. Fork creation is requested; publishing our corrected commits, core/client push and release workflows remain separate delivery approval.
- Record actual fork/core/client commit ranges in ledger. Scripts run from client do not correctly infer nested-repository ranges themselves.
- Known RED until owner tasks finish: late reset response (Task 4), duplicate fragments (Task 3), dispatcher double Close (Task 2). Do not call earlier whole-suite runs green by excluding these.

## Review Focus

1. Close overlaps blocked AttachReturn: no late registration, leaked owner, duplicate detach or lock cycle (Task 2 test).
2. All owners close and a new dispatcher uses the same live Port before TTL: logical quarantine survives, closed OS reservations do not (Task 4 test).
3. Malformed/overlapping IPv6 fragments and duplicate first fragments: bounded memory, fixed expiry, valid datagrams remain deliverable (Task 3 tests).
4. Missing/wrong/dirty submodule or changed require: gates fail instead of silently compiling cached upstream (Tasks 1, 5 tests).
5. Source archive and client rebuild must use the same fork SHA as core AAR; legacy `.2` artifact verification remains compatible (Task 6 tests).

## File Map

- Core integration: `.gitmodules`, `go.mod`, gitlink `third_party/sing-tun`, `release/SING_TUN_PIN.json`, `release/sing_tun_pin.py`, `release/sing_tun_pin_test.py`.
- Fork close: `flow_dispatch.go`, `etonify_flow_close_test.go`.
- Fork fragments: `flow_fragment.go`, new `flow_fragment_coverage.go`, `etonify_flow_fragment_test.go`.
- Fork UDP: `flow_nat.go`, new `flow_nat_quarantine.go`, `flow_dispatch.go`, `etonify_flow_nat_test.go`.
- Core regression suite/runner: existing `common/forwardnat/*_test.go`, `release/verify_forward_nat.py`, `release/verify_forward_nat_test.py`, overlay test.
- Core delivery plumbing: `.github/workflows/etonify-libbox.yml`, `release/verify_etonify_baseline.sh`, `release/source_archive.py`, `release/source_archive_test.py`.
- Client plumbing: `.github/workflows/sync-etonify-core.yml`, `scripts/verify_libbox.py`, new `scripts/verify_libbox_test.py`.
- Final source notes: fork `ETONIFY_PATCHES.md`, core `release/ETONIFY_VERSION`, `release/ETONIFY_RELEASE_NOTES.md`.

### Task 1: Fork, submodule and verifiable local replacement

**Files:** core integration/pin files and existing overlay runner/tests. Do not change NAT code yet.

**Interfaces:** `dependency_metadata(root: Path, *, require_clean: bool = False) -> dict[str, str]` in `release/sing_tun_pin.py`; keys `repository`, `commit`, `upstream_commit`, `module_version`. CLI `python -B release/sing_tun_pin.py [--strict]` emits that JSON; nonzero on mismatch. Manifest `release/SING_TUN_PIN.json` has the same keys. Strictness applies to checkout cleanliness, not to pin/path/source identity.

- [ ] **1. Capture baseline.** Check client/core status and SHAs, save all three current RED outputs and baseline full core suite into this plan's ignored scratch. Expected: only documented reproducer failures and platform restrictions; list any additional failures before proceeding.
- [ ] **2. Create requested fork.** Recheck account `gh api user --jq .login` = yamixdev; recheck existing repository. If absent, `gh repo fork SagerNet/sing-tun --clone=false --remote=false`. If present, validate `isFork` and parent rather than overwrite. Expected: public fork parent SagerNet/sing-tun; no corrected-commit push or upstream PR. Verify creation response before continuing.
- [ ] **3. Add exact submodule.** In core, `git submodule add https://github.com/yamixdev/sing-tun.git third_party/sing-tun`; fetch the base SHA if needed, create branch `codex/etonify-nat-fixes` from that exact SHA. Preserve existing clients entries in `.gitmodules`. Expected: module HEAD = base, `module github.com/sagernet/sing-tun`, original LICENSE present. Go replacement/business logic not changed yet.
- [ ] **4. Write pin-validator tests against real temporary local Git repositories.** Test names: `test_exact_checkout_is_used`, `test_missing_submodule_fails`, `test_wrong_url_fails`, `test_checkout_sha_mismatch_fails`, `test_wrong_require_fails`, `test_cached_upstream_or_other_replace_fails`, `test_strict_rejects_dirty_checkout`. Seed child fixture history from the now-available exact local fork base, without network or changes to the real checkout; create a parent gitlink and invoke actual Go module resolution. Example assertion: `self.assertEqual(fixture.child_commit, dependency_metadata(fixture.root)['commit'])`; rejected fixtures must raise `RuntimeError`, not return plausible metadata. Dirty fork allowed only with `require_clean=False` while SHA/path still match.
- [ ] **5. Verify RED.** `python -B release/sing_tun_pin_test.py`; expected missing implementation/explicit unimplemented behavior, then meaningful mismatch failures during incremental implementation. Do not assert source-text presence instead of executing validator.
- [ ] **6. Implement replacement and validator.** Apply exact replace; implement Task 1 interface. Compare manifest against Git index gitlink, child HEAD, `.gitmodules` URL, resolved Go Dir/Replace and require. Resolve paths before comparison; reject a sibling checkout, cache module, wildcard replace or different version. Read-only validation never repairs a mismatch.
- [ ] **7. Adapt overlay runner.** Preserve scratch-copy overlay for Go 1.27, excluding `.git` metadata from the copy; validate the real selected submodule first. Temporary modfile replaces the same exact version, not a second wildcard override. Gate's strict option is separate from developer RED/GREEN testing. Extend runner tests for accepted local replace and rejection of unexpected replacement/exit-code propagation. Existing old-pin baseline probe stays isolated and unchanged.
- [ ] **8. Verify GREEN integration.** `python -B release/sing_tun_pin_test.py`, `python -B release/verify_forward_nat_test.py`, `python -B release/sing_tun_pin.py --strict`, `go list -m -json github.com/sagernet/sing-tun`. Expected: actual Dir ends in core/third_party/sing-tun; URL and commit match gitlink. Runtime bug reproducers remain RED and are explicitly recorded, not hidden.
- [ ] **9. Commit integration.** Core commit `build: pin sing-tun fork through a verified submodule`. Stage only intended files and gitlink; no client core-pointer or binary update.

### Task 2: Single-owner dispatcher teardown

**Files:** fork `flow_dispatch.go`, `etonify_flow_close_test.go`; retain core shared-NAT overlay reproducer.

**Interfaces:** public `(*ForwardDispatcher).Close()` and `natFor(port Port) *portNAT` signatures unchanged; closed natFor returns nil without AttachReturn. Internal one-time close guard must cover registration, not only releasePortNAT.

- [ ] **1. Add fork regressions.** `TestEtonifyDispatcherDoubleCloseSharedNAT`: two dispatchers share Port, close first twice, third joins the same allocator as second. `TestEtonifyDispatcherConcurrentClose`: join 32 goroutines, assert one detach/release and surviving owner. `TestEtonifyDispatcherCloseDuringAttachReturn`: fake blocks AttachReturn on a channel, overlap Close, release barrier, join both and assert no attached path/owner remains; subsequent natFor returns nil and attach counter does not change. Fake callbacks exercise external I/O boundaries, not mock-only bookkeeping.
- [ ] **2. Observe RED.** Inside fork `go test -race -count=1 -run '^TestEtonifyDispatcher' .`; core overlay reproducer must also fail before fix. Expected: shared identity/count failure or late registration, not a hung test without diagnosis.
- [ ] **3. Implement minimum lifecycle guard.** Win shutdown with atomic CompareAndSwap before teardown. Serialize port-registration snapshot via portsAccess and recheck closed under that lock in natFor. Preserve stage locking/order and close reports. Do not hold registry/port locks across external DetachReturn callbacks or invent a second owner.
- [ ] **4. Verify GREEN.** Fork `go test -race -count=20 -run '^TestEtonifyDispatcher' .`; core `python -B release/verify_forward_nat.py --race` now has only known fragment failure. Core device/WireGuard race suite stays green. Record all known not-yet-fixed RED separately.
- [ ] **5. Commit fork and repin core.** Fork `fix: make forward dispatcher teardown single-owner`; update gitlink and manifest to exact local commit using patch, run pin-validator tests, core `build: pin dispatcher lifecycle fix`. No push yet.

### Task 3: Unique fragment coverage with bounded state

**Files:** fork fragment files; expand core `common/forwardnat/fragment_test.go` and retain original overlay regression.

**Interfaces:** internal `fragmentCoverage` tracks a fixed `[128]uint64` bitmap (8192 eight-byte cells, 1024 bytes). `add(offset, length int, more bool) bool` returns false for invalid ranges; `complete(total int) bool` requires all cells up to final length. Existing fragmentTable insert/lookup signatures remain. Nonfinal fragment lengths and offsets must be eight-byte aligned; final partial cell is allowed. Max reconstructed payload 65535 bytes, no unbounded range list.

- [ ] **1. Add behavior tests.** Original offsets `0,16,16,48(final),32` must retain association until offset32. Add out-of-order and overlaps covering the same bytes twice; duplicate first fragment must not erase received coverage or extend TTL. Invalid negative/nonaligned/overflow offsets and nonfinal lengths are rejected without new allocation/state mutation. Conflicting final lengths cannot declare completion. Add fixed-expiry and 4096-capacity checks.
- [ ] **2. Add packet-level regression for IPv4 and IPv6.** Four 16-byte regions, first/middle/duplicate/final/missing-middle order. Assert every unique required fragment is rewritten to the original client, leftovers and writeback are distinguished, and independently reassembled UDP checksum/payload match. Existing malformed/after-flow-close tests stay.
- [ ] **3. Verify RED.** Fork `go test -race -count=1 -run '^TestEtonifyFragment' .`, core fragment test and overlay runner. Expected: missing offset32/coverage loss, not compilation-only failure. Bitmap helper unit tests may initially have no implementation; integration regression proves actual old bug.
- [ ] **4. Implement coverage.** Add the fixed bitmap helper and integrate it in fragmentEntry. Retain TTL 30s, sweep 1s, capacity4096. Completion counts unique cells only after consistent final length; duplicate same-flow first preserves coverage/deadline, different-flow first replaces association deliberately. Invalid association data cannot cross a flow/key or create an unlimited payload allocation.
- [ ] **5. Verify GREEN/bounds.** Fork `go test -race -count=20 -run '^TestEtonifyFragment' .`; core packet fragment suite and overlay pass. Benchmark repeated duplicates and full cache; record allocations/cache high-water mark, no duplicate-driven growth. Bitmap budget at 4096 entries is 4MiB plus existing entry/map overhead, not 32MiB byte bitmap or unbounded intervals.
- [ ] **6. Commit/repin.** Fork `fix: track unique fragment coverage without early completion`; core regression changes, gitlink and manifest commit `test: pin fragment coverage fixes and packet regressions`.

### Task 4: UDP selector quarantine and safe reuse

**Files:** fork `flow_nat.go`, `flow_nat_quarantine.go`, `flow_dispatch.go`, `etonify_flow_nat_test.go`; core mapping fixture/tests.

**Interfaces:** public dispatcher/Port contracts unchanged. `natSelector` gains quarantine deadline and a flag identifying whether a real reservation is still held. Helpers: `reserveAt(dispatcher *ForwardDispatcher, protocol uint8, portAddress netip.Addr, client, server netip.AddrPort, now int64) (natReservation, bool)`, `releaseAt(flow *forwardFlow, now int64)`, `sweepQuarantine(now int64)`, `selectorQuarantined(key natSelectorKey, now int64) bool`. Production wrappers use one package-wide monotonic epoch; tests pass literal time. All dispatchers sharing a Port use the same time base.

- [ ] **1. Add deterministic quarantine tests.** Two selectors50000/50001: close/reset A on50000 at time0; B uses50001, old reply is dropped and not written to B. At `4*time.Minute-1` selector50000 still blocked; at `4*time.Minute` it can be reserved again. Multiple flows sharing a UDP mapping quarantine only after last owner releases. TCP/ICMP release immediately. Release callback occurs exactly once at expiry or final teardown, never twice.
- [ ] **2. Test shared/retired owners.** Close all dispatchers on the same still-live Port, free physical reservations, create a new dispatcher before TTL; old selector stays logically blocked. Reacquiring an idle allocator cancels stale cleanup eligibility; a late cleanup callback must not erase live state. Add repeated reset, one-slot exhaustion, expansion failure/success, IPv4/IPv6 and concurrent reserve/release/Close.
- [ ] **3. Observe RED.** Core `go test -race -count=1 -run '^TestForwardNATRejectsLateReturnsIntoNewClientAfterReset$' ./common/forwardnat` plus fork `go test -race -count=1 -run '^TestEtonifyNAT' .`. Expected: late payload reaches B or selector reused before expiry.
- [ ] **4. Implement bounded quarantine.** Last UDP flow release removes reverse/mapping references, retains the selector with a deadline for4min. Allocation refuses quarantined entries and lazily sweeps expired ones. Return path drops known quarantined UDP destinations before permissive mapping fallback. Reservation callbacks are not repeated and stale owner/generation cannot free current ownership. Keep existing mapping/filtering modes; do not replace EIF with a stricter global mode merely to pass tests.
- [ ] **5. Implement final-owner retention safely.** Global shared-NAT registry retains only logical quarantine for zero-owner Ports; real reservations are released on last Close. Schedule one guarded cleanup timer per retired allocator, expiring at its last quarantine deadline. Guard callback by map identity/owner count/generation. Bound zero-owner registry to1024 entries; prune expired first, then refuse new allocations when retaining protection would exceed the bound rather than evict unexpired protection. natFor handles nil acquisition with diagnostic/controlled refusal, not panic. Lock order registry→NAT→shard, no external port callback while registry is held. Empty allocators are removed immediately.
- [ ] **6. Verify GREEN and pressure behavior.** Fork targeted race count20; core `go test -race -count=10 ./common/forwardnat`; full overlay green. Verify reuse after TTL without sleep, ≤1024 retired records, no active entry evicted, no indefinite timer/handle retention. Benchmark short-range reset/exhaustion and allocation sweep; report explicit backpressure rather than claiming unlimited capacity. Test losing Close caller plus timer overlap.
- [ ] **7. Commit/repin.** Fork `fix: quarantine released UDP selectors across network resets`; core `fix: pin reset-safe NAT and retain late-response regressions`. Strict pin metadata matches committed fork SHA; no delivery push.

### Task 5: CI gates must compile the pinned fork

**Files:** core workflow/baseline script, optional fork regression-only workflow; pin validator tests from Task1.

**Interfaces:** strict pin CLI is the gate; fork Go module is a separate test root. Core Android build tags remain unchanged.

- [ ] **1. Add controlled gate tests.** In Python Git fixtures, uninitialized submodule, wrong gitlink, dirty code, missing replacement and replacement redirected to cache each produce nonzero exit before a build command is invoked. Valid fixture emits expected repo/commit JSON. Verify helper exit propagation, not exact YAML text alone.
- [ ] **2. Integrate selective checkout.** After checkout in relevant core jobs run `git submodule update --init -- third_party/sing-tun`; add `.gitmodules` and `third_party/sing-tun` to push path filters. Baseline validator runs strict pin check before compilation and confirms upstream base ancestry in fork. Do not initialize unrelated clients solely for this gate.
- [ ] **3. Add fork gates before AAR.** `(cd third_party/sing-tun && go test -race -count=1 -run '^TestEtonify' .)`; standalone fork full `go test -count=1 ./...` and root integration tests using existing upstream `make test` convention where platform privileges are required. Linux runner may use `go test -exec sudo .` for existing namespace tests; it is not an Android build. Fork workflow can be regression-only on codex branch with Linux/Windows/macOS; preserve upstream workflows/licenses and do not add privileged production jobs there.
- [ ] **4. Run locally available gates.** Core full `go test -count=1 ./...`, existing 12-package race suite, tagged Android corpus, six feature-tag compile-only consumers, fork full and targeted race. Record actual administrative/network integration restrictions by test name; do not turn them into silent skips. Run Python pin/runner tests and strict pin CLI.
- [ ] **5. Commit gates.** Core `ci: verify fork pin and run nested NAT regression gates`; fork CI changes separate optional commit with repin. CI configured does not mean executed until approved delivery.

### Task 6: Source archive and both AAR provenance paths

**Files:** core source archive helper/tests and workflow; client sync workflow and verifier/tests.

**Interfaces:** `create_source_archive(root: Path, output: Path) -> None` in `release/source_archive.py`, CLI `python -B release/source_archive.py OUTPUT`; reads only committed root/fork sources and strict pin metadata. Provenance keys: `sing_tun_repository`, `sing_tun_commit`, `sing_tun_upstream_commit`, `sing_tun_module_version`. Client helper `verify_sing_tun_provenance(provenance: dict, expected_pin: dict | None) -> None` raises RuntimeError for missing/mismatched fork metadata when expected_pin exists; legacy pin absent permits the old artifact contract.

- [ ] **1. Write archive tests with real temporary Git parent/child.** `test_archive_contains_pinned_child_and_license`, `test_archive_is_deterministic`, `test_archive_rejects_wrong_child`, `test_extracted_archive_resolves_local_module`. Build twice→identical bytes; archive contains child's go.mod, a Go fixture and LICENSE; wrong or dirty source rejected. Safe extraction fixture runs `go list -m -json` from archive and confirms replacement Dir is the included child, not GOMODCACHE. No recursive arbitrary symlink traversal.
- [ ] **2. Write client metadata tests.** New pinned core with correct four keys accepted; old fork SHA, upstream URL, absent fields rejected; legacy `.2` without nested gitlink keeps passing existing contract. Read expected pin/gitlink from committed core tree, not untrusted provenance alone. Test no-initialized-child case via core Git objects; preserve source_commit, API hash, SHA256 and ABI checks.
- [ ] **3. Observe RED.** `python -B release/source_archive_test.py` and client `python -B scripts/verify_libbox_test.py`; expected missing new helper/actual metadata mismatch until implementation. Existing plain git archive demonstrably omits child code.
- [ ] **4. Implement complete deterministic source archive.** Require a clean tracked parent tree/index and child; compare HEAD manifest/gitlink with resolved metadata rather than trusting only staged pins. Combine exact core git archive with exact child git archive under `third_party/sing-tun/`; normalise gzip timestamp/filename. Include manifest, code and original license. Verify extracted Go resolution. Do not archive working dirt or unrelated uninitialized client repositories.
- [ ] **5. Update core and client workflows.** Core AAR and client rebuild provenance both take Task1 checked metadata, write the same four keys, run strict pin check before build. Core archive uses helper. Client core rebuild checkout already recursive; add missing nested-module regression gate. Old binary isn't replaced by these source edits; validate before workflow's artifact-commit step.
- [ ] **6. Verify GREEN.** Both Python suites plus runner/pin tests; rebuild test archive twice, inspect child source presence/Go resolution. Run current legacy verifier against its recorded core checkout only; current working core differs from old AAR, so do not expect blanket `verify_libbox.py` PASS before delivery. Review all manifest-producing paths for schema parity.
- [ ] **7. Commit separately.** Core `build: include pinned sing-tun sources and provenance`; client `build: verify nested fork provenance when syncing libbox`. Client core gitlink stays on delivered old base until verified AAR stage; no artifact changes now.

### Task 7: Whole-diff review, revision and delivery handoff

**Files:** fork ETONIFY_PATCHES.md; core version/release notes; client plan execution notes. Binaries unchanged before approved remote workflows.

**Interfaces:** next source revision `v1.15.0-alpha.10-etonify.3`, client `0.3.9+39`. Delivery must order fork→core→client so every remote gitlink resolves.

- [ ] **1. Collect full evidence.** Re-run fork/core full suites and relevant race/tagged/Python gates on final source; read complete results. Compare diff to exact bases; ensure public libbox API/Android tags/native client fixes unchanged. Explicitly list skips/privilege failures and pending Linux CI/device tests.
- [ ] **2. Dispatch one fresh whole-diff reviewer.** Preserved Native execution: main agent implements sequentially, one most-capable fresh reviewer at end, no per-task workers. Reviewer receives fork/base/head, core/base/head, client/base/head, spec/plan/ledger rulings and Review Focus verbatim. Review quarantined-state lifetime, timer/global-lock ordering, fixed fragment memory and real replacement/provenance. Reproduce Important findings RED→GREEN in one fix pass; no silent scope expansion.
- [ ] **3. Prepare version and honest notes after source fixes.** Document exact upstream base, actual fork SHA, three repairs, finite four-minute quarantine/backpressure and remaining platform limits. Core version `.3`; fork notes list patch inventory without promising every network issue fixed. `go test ./cmd/internal/build_libbox`, baseline/pin strict gate, `git diff --check` pass; commit `docs: prepare verified sing-tun fork core revision`.
- [ ] **4. Report before publication.** Summarize local commits/tests and unresolved limitations. Fork created but our corrected branch commits not yet pushed; core/client not delivered. Ask approval for push sequence that triggers AAR/draft-release and client artifact sync; do not silently start release APK workflow.
- [ ] **5. After separate approval only:** push exact fork branch, verify corrected SHA reachable; push core with pin, await actual Linux/full/race/AAR gates; then deliver matching client core gitlink and verified AAR through normal sync workflow. Run client verifier (SHA256, API, ABI, core+fork SHA), not merely assume CI artifact matched. Phone acceptance: UDP/calls/game, repeated start/stop, Wi-Fi/LTE, sleep/return, tile, both URLTest modes. Do not mark device checks passed before user result.

## Self-Review / Handoff

Spec coverage: fork/replacement and provenance Tasks1/5/6, close Task2, fragments Task3, quarantine Task4, limits/tests/review/delivery Task7. Review Focus cases have owning tests. New helpers have exact signatures; no public API change. Initial known REDs are carried until their fix tasks. All SHA changes repin both gitlink and manifest; no task depends on a moving remote branch.

Use preserved Native method in current checkout. The previous design/backport plan is not re-executed; this plan continues its three confirmed blockers and delivery plumbing. Written-plan review is still required before implementation. Fork creation and submodule changes have not occurred during planning.
