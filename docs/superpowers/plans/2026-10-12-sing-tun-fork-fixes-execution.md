# sing-tun fork repair: local execution record

Date: 2026-10-12. Approved spec/plan implemented in the existing checkout.
The initial local handoff below preceded source publication. Publication was
subsequently authorized as recorded in the final section. No local Android build
or manual remote workflow dispatch is part of that publication request.

## Source identity and delivery boundary

- Fork: `https://github.com/yamixdev/sing-tun`, branch `codex/etonify-nat-fixes`.
- Fork base: `5c2edb183cc92eb190d41c04dedfa5519ca3e78c`.
- Final fork source: `3692459a3211ad692b83580cd4c95e1ff4e20080`.
- Core implementation range: `0fe9bbb66cbe998d6ca22a53e3d3a807c3a148f7` through `2a6c7e2ad2561edc05668f5bd6378e06d4ddd122`.
- Core source version: `v1.15.0-alpha.10-etonify.3`.
- Client remains `0.3.9+39`. At the local handoff its core gitlink was delivered
  `69425e4fbe5d3c67b692226dabc6f11ffe20072c`, matching unchanged bundled AAR.
- Existing AAR SHA256: `3815aa8b11bf9669aff19b55a6ef32a97a2b5bd3feb477d7c46a919524e2df9a`.

## Implemented and verified

Single-owner dispatcher Close; bounded unique fragment coverage; four-minute UDP
selector quarantine; active expiry without traffic; serialized physical final
release; shared/retired owner and timer-generation guards; strict nested Git/Go
source selection; selective CI initialization; complete nested source archive;
matching provenance schemas for both AAR producers and committed-tree verifier.
Public libbox/Port contracts, Android API24/ARM tags, native recovery/UI/routing
code and bundled binary were not modified by this plan.

- Fork: `go test -race -count=20 -run '^TestEtonify' .` passed on final runtime.
- Core packet suite: `go test -race -count=10 ./common/forwardnat` passed.
- 14 runtime packages passed race tests; tagged configuration corpus passed;
  six optional-feature consumers compiled (compile-only, not protocol acceptance).
- TLS/uTLS race tests and build-libbox version tests passed; QUIC compile gates passed.
- 26 Python tests passed: pin8, overlay runner4, CI2, archive4, client8.
- Strict pin/baseline selected the actual fork submodule; all five edited workflows
  parsed as YAML. The real fresh client checkout failed without core objects and
  passed after selective initialization. Legacy AAR verified against its recorded
  core checkout, not the newer working core.
- Same-config archives matched SHA256; extracted archive resolved Go to its included
  fork. Git checkout conversion changes line endings: raw cross-config equality is
  not claimed (see deferred minor).

## Fresh review and one fix pass

One read-only fresh reviewer checked all three exact repository ranges. No Critical;
three Important findings were reproduced and repaired:

1. Missing core Git objects in three client verifier jobs: workflow regression RED;
   selective checkout plus real fresh-clone verification GREEN.
2. Expired final Close could erase a new physical reservation: real Go-reservation
   barrier regression RED3/3; retaining retirement identity through callbacks and
   reacquisition serialization GREEN, including race20.
3. Live expired reservations had no production cleanup: real Go-reservation timed
   regression RED; one guarded active timer frees the port without traffic GREEN.

The full Windows suites were rerun after repair and are NOT green: core has the same
eight administrative SCM failures in tlsspoof/windivert; fork has privileged TUN
tests, upstream winipcfg test vet errors (`%w`), and IPv6 privileged ping timeouts.
No tests were silently skipped. Remote Linux full/race gates remain fail-closed and
unexecuted; phone behavior is not declared verified.

## Rulings and costs

- Honor current-checkout preference instead of a worktree; cost: nested checkout is
  ahead of delivered gitlink until artifact delivery, protected by exact bases/staging.
- Continue through requested baseline REDs without asking again; cost: unrelated
  failures still need separate classification and reporting.
- Installed gh rejected explicit-repository `--remote`; use `--clone=false` alone.
  Cost if wrong: unexpected local remote mutation; remotes/status were checked unchanged.
- Preserve upstream fragment expiry boundary `<`, using valid aligned expiry fixtures.
  Cost: association remains valid at the exact deadline tick, as before.
- Reserve 1024 registry slots for active plus retired allocators to guarantee retirement
  capacity. Cost: more than 1024 distinct live Ports are refused rather than evicting
  protected entries; normal Android builds expose far fewer.
- Leave unrelated Windows privilege/vet/IPv6 failures explicit. Cost: Linux CI may
  still reveal platform failures and will block delivery rather than waive them.
- Legacy upstream stable/testing/unstable workflows are not the supported fork delivery
  path; preserve their files. Cost: manual legacy workflow use can fail without init.
- Linux CI/AAR/device acceptance require the next approved stage. Cost: local tests
  cannot establish those external/device properties.
- Four-minute/same-live-Port UDP protection is finite. Cost: arbitrarily late packets
  after reuse, or unrelated replacement Port objects, are outside its guarantee.

## Deferred minor

Normalize Git archive conversion configuration across Windows/Linux. Same-config
archives are deterministic, but `core.autocrlf` changes LF/CRLF archive bytes for
the same commit. Reproduced; Go source behavior is unchanged. Not mixed into the
Important repair pass.

## Next stage, only after separate authorization

Push the fork branch first and verify the exact SHA is reachable. Then push core
and await actual Linux full/race/configuration/AAR gates. Only then deliver matching
client core gitlink plus verified AAR/provenance through the artifact workflow.
Run SHA256, API, ABI, source/core/fork checks. Do not start release APK implicitly.
Phone acceptance: UDP/calls/game, repeated start/stop, Wi-Fi/LTE, sleep/wake,
quick-settings tile and both URLTest modes.

## Authorized source publication

The user subsequently requested publishing all core/client changes without waiting
for builds, with further checking handled by them. Publish the corrected fork branch
first, core `etonify-dev` second, then client `master` with its core gitlink advanced
to `2a6c7e2ad2561edc05668f5bd6378e06d4ddd122`.

The bundled AAR still records `.2`/`69425e4` until the existing automatic sync job
successfully rebuilds and commits matching artifacts. The client binary verifier
will correctly reject that intermediate mismatch; do not waive or disable it.
Push-triggered workflows may run automatically. No extra dispatch, monitoring,
APK build, or assertion of remote CI/device success is authorized by this step.
