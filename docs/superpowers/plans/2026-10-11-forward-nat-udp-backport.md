# Forward NAT / UDP Backport Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перенести upstream `d2a4dc29faee6f6f9ec5f3cbcb5435df1c67f91f`, сохранив исправления Etonify и доказав совместимость тестами.

**Architecture:** Точечный backport 24 файлов sing-box с закреплением совместимого `sing-tun`. Контракт `UpstreamPort()` раскрывает возможности резервирования selector через обёртки; пул принадлежит устройству. Проверки пакетов работают с fake ports, без реального VPN; внутренний fragment cache проверяется через test-only Go overlay, не редактируя module cache.

**Tech Stack:** Go 1.27.1, sing-box 1.15.0-alpha.10, sing-tun, Go race detector, Python 3 для test overlay, GitHub Actions.

**Spec:** `docs/superpowers/specs/2026-10-11-forward-nat-udp-backport-design.md` (одобрена пользователем).

## Global Constraints

- Текущие checkout и ветки: клиент `master`, ядро `etonify-dev`; без worktree.
- База ядра: `69425e4fbe5d3c67b692226dabc6f11ffe20072c`.
- Только `sing-tun` меняется с `v0.9.7-0.20261002083955-3f8acd9da65b` на `v0.9.7-0.20261009022811-5c2edb183cc9`; `sing` остаётся `v0.9.7-0.20260929150544-6f21f2425a95`.
- Сохраняются scoped shutdown, реальные ошибки закрытия, lifecycle WireGuard, маршрутизация групп, URLTest и фоновое восстановление Android.
- На ПК не собирать APK, AAR или Android-ядро; host-тесты разрешены.
- Не менять UI, `.RU без VPN`, батарею, версию клиента `0.3.9+39`, экспортируемый libbox API или Android build tags.
- Не выполнять push, запуск CI-сборки, публикацию релиза, замену AAR или откат без отдельного решения пользователя.
- Не коммитить кеши, логи, временные overlays, скачанные модули и бинарники.
- Все пути ниже относятся к `etonify-core`, кроме явно обозначенных путей клиента. Команды Go выполняются из `etonify-core`; в Windows использовать `C:/Program Files/Go/bin/go.exe`.

## Review Focus

1. Повторный Start при уже созданном устройстве: остаётся тот же пул, Close освобождает его однократно (Task 2).
2. Поздний UDP-ответ после ResetNetwork/Close: не попадёт в новую сессию и не оживит старую (Task 3).
3. Несколько назначений/отправителей при коротком диапазоне selector: корректное совместное использование mapping, без присвоения чужого ответа (Task 3).
4. Перестановка/дублирование фрагментов и заполненный cache: нет падения, неверного rewrite и неограниченного роста (Task 3).
5. Не включённый в Android протокол всё равно реализует новый Go-контракт; Android DNS остаётся рабочим (Tasks 1, 4).

## File Map

- Dependency: `go.mod`, `go.sum`.
- Новый pool: `common/kernelports/pool.go`, `pool_darwin.go`, `pool_linux.go`, `pool_unix.go`, `pool_unix_other.go`, `pool_windows.go`.
- Device contract: `transport/device/device.go`, `stack.go`, `system.go`; `system_stack.go` проверить на корректное наследование capability, менять только при доказанной необходимости.
- WireGuard contract: `transport/wireguard/device.go`, `device_stack.go`, `device_system.go`, `port.go`; `protocol/wireguard/endpoint.go`.
- Consumers: `protocol/masque/client.go`, `server.go`; `protocol/openconnect/client.go`; `protocol/openvpn/client.go`, `server.go`; `protocol/tailscale/port.go`.
- Windows bridge: `protocol/bridge/backend_windows.go`, `outbound.go`; удалить заменённый upstream файл `reservation_windows.go` после проверки отсутствия потребителей.
- Route: `route/route.go`, только upstream logging hunk.
- Новые тесты: `common/forwardnat/dependency_test.go`, `fixtures_test.go`, `mapping_test.go`, `fragment_test.go`; `common/kernelports/pool_test.go`, `pool_unix_test.go`, `pool_windows_test.go`; `transport/device/system_lifecycle_test.go`, `transport/wireguard/device_system_lifecycle_test.go`.
- Internal dependency tests: `release/testdata/singtun/fragment_overlay_test.go`, `release/verify_forward_nat.py`.
- CI: `.github/workflows/etonify-libbox.yml`.
- При подготовке исходников к доставке: `release/ETONIFY_VERSION`, `release/ETONIFY_RELEASE_NOTES.md`. Не менять `release/ETONIFY_BASELINE`: это backport, не новый полный upstream baseline.

### Task 1: Совместимый backport и контракт зависимости

**Files:** dependency, pool, device/WireGuard/consumer/bridge/route paths из File Map; создать `common/forwardnat/dependency_test.go`.

**Interfaces:**
- Produce: `device.Device.UpstreamPort() any` и соответствующий метод WireGuard Device; forwarding wrappers делегируют нижележащему устройству.
- Consume: `tun.PortWithSelectorRange`, `tun.PortWithSelectorReservation`, `tun.PortWithUpstream` из целевой версии.
- Pool: `New() (*Pool, error)`, `Acquire(protocol uint8) (tun.SelectorRange, error)`, `PortSelectorRanges(protocol uint8) []tun.SelectorRange`, `ExpandSelectorRanges(protocol uint8) bool`, `ReserveSelector(protocol uint8, address netip.AddrPort) bool`, `ReleaseSelector(protocol uint8, address netip.AddrPort)`, `Close() error`.

- [ ] **1. Зафиксировать базу и baseline результаты.** `git status --short`, `git rev-parse HEAD`; выполнить `go test ./adapter ./route ./protocol/group ./transport/device ./transport/wireguard ./protocol/wireguard`. Сохранить вывод в игнорируемом scratch, отдельно записать существующие сбои.
- [ ] **2. Добавить red-test `TestForwardNATDependencyDNSDefault`.** Table: `tun.Options{}` → `tun.DNSModeDisabled`; `{AutoRoute:true}` → `tun.DNSModeHijack`; явно заданные `DNSModeDisabled`/`DNSModeHijack` не зависят от AutoRoute. Assertion: `require.Equal(t, want, options.DNSModeOrDefault())`.
- [ ] **3. Проверить red.** `go test -count=1 -run '^TestForwardNATDependencyDNSDefault$' ./common/forwardnat`; ожидать assertion failure на default без AutoRoute, не ошибку тестовой инфраструктуры.
- [ ] **4. Перенести точные hunks `d2a4dc2` и закрепить dependency.** Читать `git show d2a4dc2 -- <path>` и текущий исходник перед каждым изменением; применять через patch, не заменять файлы деревом upstream. В `route.go` сохранить `registerInterrupt(chain, network, ...)`, `leaf` и `newFlowInterrupter(chain, metadataCopy.Network)`; в WireGuard сохранить `lifecycleAccess`, `closing`, `beginClose()` и scoped `w.Close`. Не использовать общий `go get -u`.
- [ ] **5. Получить только checksum нужной версии и проверить module diff.** `go mod download github.com/sagernet/sing-tun@v0.9.7-0.20261009022811-5c2edb183cc9`; `go mod verify`; `go list -m github.com/sagernet/sing-tun github.com/sagernet/sing`. Обе версии должны точно соответствовать Global Constraints. Непредвиденные изменения других модулей требуют объяснения до продолжения.
- [ ] **6. Запустить red-test и затронутые пакеты.** `go test -count=1 ./common/forwardnat ./common/kernelports ./transport/device ./transport/wireguard ./protocol/bridge ./protocol/masque ./protocol/openconnect ./protocol/openvpn ./protocol/tailscale ./protocol/wireguard ./route`. Ожидать PASS или явно диагностированный platform/build-tag предел; не маскировать compile failure skip-ом.
- [ ] **7. Проверить diff и закоммитить совместимый backport.** `git diff --check`, сверка каждого path с upstream hunks и сохранёнными отличиями Etonify. Stage только перечисленные исходники, модули и новый тест; commit `feat: backport forward NAT UDP mapping and fragments`.

### Task 2: Владение пулом и lifecycle устройств

**Files:** pool тесты, lifecycle тесты device/WireGuard; менять `transport/device/system.go`, `transport/wireguard/device_system.go` и pool только если тест доказал нарушение.

**Interfaces:** использовать Task 1 контракт. Fake TUN в тестах встраивает `tun.Tun`, переопределяет `Close() error` и хранит число закрытий; не открывать системный интерфейс. Runtime synchronization принадлежит конкретному устройству, не глобальной переменной.

- [ ] **1. Написать регрессии.** `TestSystemDeviceRepeatedStartKeepsPool`: preseed fake TUN и pool, вызвать Start дважды, `require.Same(t, pool, d.UpstreamPort())`. `TestSystemDeviceCloseReleasesPool`: после Close `require.Nil(t, d.UpstreamPort())`, fake TUN закрыт один раз, повторный Close не закрывает повторно. `TestSystemDeviceStartAfterClose`: `require.ErrorIs(t, d.Start(), net.ErrClosed)`. Добавить гонку Start/Close/UpstreamPort со всеми завершёнными goroutine.
- [ ] **2. Добавить аналогичные проверки WireGuard.** `TestWireGuardSystemDeviceStartAfterClose`, `TestWireGuardSystemDeviceCloseClearsUpstreamPort`, `TestWireGuardSystemDeviceConcurrentStartClose`; отсутствие physical network manager не должно успеть вызвать panic после уже выполненного Close.
- [ ] **3. Добавить pool tests.** `TestPoolContainsRangeBoundaries` для start, last, outside и zero-count; `TestPoolProtocolRangesIndependent` для разных TCP/UDP ranges; `TestPoolReserveOccupiedSocket` на Unix: TCP listener на loopback запрещает TCP selector, но не UDP на том же числе; `TestPoolCloseIdempotent` и `TestPoolConcurrentRangesAndClose`. Windows-specific ranges/Close тестируются без обязательного WinDivert driver. Фактическую OS reservation проверять отдельным тестом с явным отчётом об ограничении прав, не выдавая skip за PASS.
- [ ] **4. Проверить red после чистого upstream backport.** `go test -race -count=1 ./common/kernelports ./transport/device ./transport/wireguard`; зафиксировать конкретные ошибки ownership/lifecycle, если они воспроизводятся. Уже работающие случаи остаются regression coverage.
- [ ] **5. Исправить только доказанные нарушения.** Start проверяет closed/уже созданное устройство до создания второго pool; доступ и Close используют тот же lifecycle lock. Close очищает ссылку pool, агрегирует реальные ошибки TUN/pool и не публикует готовое capability после закрытия. В WireGuard учесть closeOnce и вызывающий Endpoint lifecycle, не заменять существующие защиты.
- [ ] **6. Проверить green и существующий endpoint test.** `go test -race -count=10 ./common/kernelports ./transport/device ./transport/wireguard ./protocol/wireguard`; `TestEndpointStartRefusesPendingClose` должен сохраняться. Закоммитить тесты и минимальный fix: `fix: retain selector pool ownership across device lifecycle`.

### Task 3: Пакетные регрессии UDP и фрагментов

**Files:** `common/forwardnat/fixtures_test.go`, `mapping_test.go`, `fragment_test.go`; `release/testdata/singtun/fragment_overlay_test.go`, `release/verify_forward_nat.py`.

**Interfaces:**
- Fixture: `newForwardFixture(t *testing.T, options tun.UDPNatOptions) *forwardFixture`; хранит dispatcher, stage, fake port, captured forward/return packets и captured `tun.FlowHandle`.
- Fake port реализует `tun.Port`, reservation и ranges; handler возвращает `tun.FlowVerdict{Action:tun.ActionFlow, Port:fakePort}`. `UpstreamPort() any` позволяет тестировать несколько обёрток.
- Packet helper: `udpPacket(t *testing.T, source, destination netip.AddrPort, payload []byte) []byte`; checksum валидируется независимо от dispatcher helper. Stage: `Dispatch(packet []byte) bool`, затем `Flush()`.
- Overlay runner: `python release/verify_forward_nat.py [--race]`; определяет target module через `go list -m -json`, создаёт JSON overlay в TemporaryDirectory, запускает `go test -count=1 -overlay=<json> [-race] -run '^TestEtonifyForwardFragment' github.com/sagernet/sing-tun`, возвращает настоящий exit code. Не редактирует/удаляет module cache, проверяет целевую версию до запуска.

- [ ] **1. Написать fixture и mapping tests.** `TestForwardNATMappingModes`: table для `tun.NATMappingEndpointIndependent` (одно mapping для разных назначений), `tun.NATMappingAddressDependent` (одно для одного адреса с разными портами) и `tun.NATMappingAddressAndPortDependent` (разные для разных AddrPort). Assertion: `require.Equal(t, wantSameMapping, selectorA == selectorB)`. `TestForwardNATSeparatesClients`: ответы доставлены исходным клиентам, нет смешения payload. `TestForwardNATFilteringModes`: при `tun.NATFilteringEndpointIndependent` допускается новый источник; при `tun.NATFilteringAddressDependent` допускается новый порт известного адреса, но не новый адрес; при `tun.NATFilteringAddressAndPortDependent` допускается только известный AddrPort. Enum-имена взяты из закреплённого `udp_nat.go`.
- [ ] **2. Написать exhaustion/release/wrapper/reset тесты.** Диапазон из двух selector и занятые fake reservations: `TestForwardNATSelectorExhaustion` не отправляет пакет с занятым selector; `TestForwardNATReleasesReservations` подтверждает освобождение после Close. `TestForwardNATNestedUpstreamCapability` использует два wrapper и занятый selector нижнего port. `TestForwardNATRejectsLateReturnsAfterReset` и `TestForwardNATRejectsLateReturnsAfterClose` закрывают capture handle, сбрасывают/закрывают dispatcher и проверяют отсутствие доставки позднего ответа.
- [ ] **3. Написать fragment integration tests.** `TestForwardNATIPv4FragmentReturn` и IPv6 counterpart: первый фрагмент создаёт association, следующие получают тот же address rewrite, восстановленные UDP/IP checksums верны. `TestForwardNATFragmentBeforeFirst` не применяет чужой rewrite. `TestForwardNATMalformedFragments` не падает. `TestForwardNATFragmentAfterFlowClose` не доставляет хвост закрытого flow. Проверять returned leftovers отдельно от packets, реально доставленных writeback.
- [ ] **4. Написать internal fragment overlay tests.** Package `tun`, использовать `fragmentTable` напрямую с управляемым `now`: TTL ровно `30*time.Second`, предел `4096`, sweep interval `time.Second`. `TestEtonifyForwardFragmentExpiry`: lookup после TTL удаляет entry. `TestEtonifyForwardFragmentCapacity`: 4097-й live key не увеличивает len выше 4096, после expiry возможна новая insert. `TestEtonifyForwardFragmentOrderAndDuplicates`: хвосты после первого в переставленном порядке и повторы не дают panic или rewrite другого key; завершённый/истёкший association не остаётся бессрочно. Проверить отдельность source/destination/protocol/id.
- [ ] **5. Проверить тесты и baseline sensitivity.** `go test -race -count=10 ./common/forwardnat`; `python release/verify_forward_nat.py --race`. Минимальный `TestForwardNATIPv4FragmentReturn` повторить в изолированном временном Go-модуле с прежним sing-tun pin и старой constructor signature (UDP timeout вместо UDPNatOptions): ожидать отсутствие корректного rewrite хвоста. Probe использует старый `tun.Port` без новых selector interfaces и не импортирует рабочий sing-box, которому уже нужен новый контракт. Не переключать рабочую dependency назад. Зафиксировать какие assertions отличают старую версию, какие лишь защищают инварианты.
- [ ] **6. При новом дефекте остановить перенос и локализовать.** Не редактировать module cache. Если требуется изменение семантики зависимости сверх backport, согласовать отдельное исправление и способ закрепления перед его внесением. Тесты нельзя ослаблять только ради green.
- [ ] **7. Закоммитить green regression suite и overlay runner.** `test: cover forward NAT mapping fragments and cleanup`.

### Task 4: Совместимость конфигураций и CI gate

**Files:** `.github/workflows/etonify-libbox.yml`; расширить `common/forwardnat/dependency_test.go`, при необходимости `experimental/libbox/etonify_schema114_test.go` только тестами.

**Interfaces:** Task 3 runner exit code является gate. Release tags остаются `with_quic,with_utls,with_naive_outbound,with_clash_api,badlinkname,tfogo_checklinkname0`; Android targets остаются `android/arm,android/arm64`. No new exported libbox API.

- [ ] **1. Дополнить DNS/corpus regression tests.** Default AutoRoute=true и explicit modes из Task 1; Android physical-interface forwarder binding сохраняет прежний результат. Проверить generated Android corpus против ядра, а не только JSON синтаксис.
- [ ] **2. Запустить локальные gate.** `go test -count=1 ./...`; `go test -race -count=1 ./adapter ./common/interrupt ./common/urltest ./daemon ./experimental/libbox ./protocol/group ./route ./transport/device ./transport/wireguard ./common/kernelports ./common/forwardnat`; `go test -tags 'with_quic,with_utls' -run 'TestEtonify(AndroidConfigCorpus|NaiveConfigSchema)' ./experimental/libbox`. Вывод и exit codes обязательны; unsupported Windows paths вынести в CI, не объявлять clean при незавершённом запуске.
- [ ] **3. Добавить CI шаги в job test до AAR job.** Установить Python через уже доступный runner runtime, запустить `python3 release/verify_forward_nat.py --race` и `go test -race -count=1 ./common/kernelports ./common/forwardnat ./transport/device ./transport/wireguard ./protocol/wireguard ./route`. Сохранить существующие full test, corpus, URLTest/TLS/QUIC/resource gates.
- [ ] **4. Добавить не-Android consumers gate с feature tags в Linux CI.** Host `go test -run '^$' -tags 'with_quic,with_utls,with_wireguard,with_tailscale,with_openvpn,with_openconnect' ./protocol/masque ./protocol/openvpn ./protocol/openconnect ./protocol/tailscale ./protocol/wireguard ./transport/wireguard`; это compile-only gate, не утверждение о runtime этих протоколов. Android config corpus оставляет текущие production tags. До разрешённого push этот CI gate остаётся настроенным, но не выполненным.
- [ ] **5. Зафиксировать review evidence.** Diff Android Kotlin/Flutter и `experimental/libbox` production API отсутствует; `git diff --check`; baseline shell validator выполняется на GitHub, без локальной Android сборки. Закоммитить CI/test изменения: `ci: gate NAT backport on packet and lifecycle regressions`.

### Task 5: Финальный review и подготовка к доставке

**Files:** `release/ETONIFY_VERSION`, `release/ETONIFY_RELEASE_NOTES.md`; клиент `docs/superpowers/plans/2026-10-11-forward-nat-udp-backport.md` для отметок исполнения. Submodule/AAR остаются отдельным этапом.

**Interfaces:** следующий core source revision `v1.15.0-alpha.10-etonify.3`; клиент остаётся `0.3.9+39`. Отчёт различает source tests, CI tests, binary validation и проверку на телефоне.

- [ ] **1. Провести один свежий whole-diff review.** По executing-plans/requesting-code-review: проверить сохранение Etonify hunks, locks/ownership, deadlocks, ошибочные success/fallback, фрагменты и ошибки закрытия. При найденном дефекте сначала воспроизводящий тест, затем исправление и повтор соответствующего gate.
- [ ] **2. Обновить core revision/notes после локальной проверки.** `ETONIFY_VERSION` → `v1.15.0-alpha.10-etonify.3`; notes прямо указывают upstream SHA, sing-tun pin, сопутствующий DNS default и пределы применимости. Не писать, что исправлены Doze или конкретные сервисы. `go test ./cmd/internal/build_libbox`; commit `docs: prepare NAT backport core revision`.
- [ ] **3. Выдать итоговый отчёт до push.** Перечень коммитов и точные результаты команд, warnings/skips/непроверенные платформы, что сохранилось неизменным. Отдельно запросить разрешение на push, поскольку push core автоматически запускает тесты, AAR build и draft release.
- [ ] **4. Только после разрешения на доставку:** push core, получить результат всех gates и verified ARM/ARM64 AAR; затем обновить client submodule и синхронизировать artifact штатным workflow. Проверить `python scripts/verify_libbox.py`, SHA256, source_commit, version, API hash и ABI. Изменения API не принимать молча. Не запускать release APK workflow без разрешения пользователя.
- [ ] **5. Передать пользователю приёмку на телефоне:** UDP/звонки/игра, Start/Stop, Wi-Fi/LTE, сон/возврат, плитка и оба режима URLTest. Не ставить галочку за ручные тесты до фактического результата. При регрессии предложить адресный revert данного этапа, не выполнять его автоматически.

## Execution Handoff

План составлен для последовательной работы: dependency и consumers образуют один
контракт, разделять их между одновременно редактирующими workers не рекомендуется.
Рекомендуемый вариант Native: основная реализация здесь, один свежий reviewer после
всех задач. Альтернатива Subagent-driven: отдельные последовательные workers с
review каждого task; выше расход контекста. Код не меняется до проверки плана
пользователем и выбора способа исполнения.

## Результат исполнения 2026-10-11

Пункты 1–4 реализованы локально, но финальное ревью открыло три дефекта
в закреплённой зависимости. Пункт 3 повторно открыт, пункт 5 остановлен
на границе согласованного объёма (Task 3 step 6). Перенос не готов к доставке.

Core base: `69425e4fbe5d3c67b692226dabc6f11ffe20072c`.
Локальные коммиты:

- `07288cf70`: backport `d2a4dc2`, точный sing-tun pin, DNS default regression.
- `9c9f1c626`: доказанные TDD исправления владения пулом и Start/Close.
- `d2f060e30`: UDP mapping/filtering, пакетные и fragment tests, overlay runner.
- `0fe9bbb66`: DNS corpus и CI gates.

Подтверждённые блокеры в sing-tun:

1. Поздний ответ старого сервера после ResetNetwork попадает в новую сессию
   другого клиента, если selector был переиспользован. Новый
   `TestForwardNATRejectsLateReturnsIntoNewClientAfterReset` падает: вместо одной
   доставки получены две, старый payload попал на `10.0.0.3`.
2. Дубликаты фрагментов учитываются как новые байты. Для offsets
   `0,16,16,48(final),32` запись удаляется раньше прихода нужного offset32.
   `TestEtonifyForwardFragmentDuplicateDoesNotDiscardUniqueTail` воспроизводит FAIL.
3. Повторный Close dispatcher повторно освобождает общий refcounted NAT.
   `TestEtonifyForwardFragmentDispatcherDoubleCloseKeepsSharedNAT` воспроизводит
   удаление allocator, которым ещё владеет другой dispatcher.

Новые reproducer-тесты оставлены незакоммиченными; зависимость и её кеш не
редактировались. Требуется отдельное согласование минимальных исправлений
sing-tun и способа закрепления исправленной версии. Версия ядра остаётся `.2`,
клиента `0.3.9+39`; submodule/AAR/provenance не доставлены и не обновлены.

Выполненные проверки до новых reproducer:

- `go test -race -count=10 ./common/forwardnat`: PASS.
- `python -B release/verify_forward_nat.py --race`: PASS; после расширения
  reproducer suite ожидаемый FAIL на двух новых случаях.
- `python -B release/verify_forward_nat_test.py`: 2 PASS.
- `python -B release/probe_forward_nat_baseline.py`: старый pin падает на
  пакетном assertion IPv4 fragments, чувствительность проверки подтверждена.
- `go test -race -count=1 ./adapter ./common/interrupt ./common/urltest ./daemon
  ./experimental/libbox ./protocol/group ./route ./transport/device
  ./transport/wireguard ./common/kernelports ./common/forwardnat ./protocol/tun`:
  12 пакетов PASS до добавления нового reset-reproducer.
- `go test -tags 'with_quic,with_utls' -run
  'TestEtonify(AndroidConfigCorpus|NaiveConfigSchema)' ./experimental/libbox`: PASS.
- Host compile-only consumers с шестью feature tags: PASS; runtime этих
  протоколов этим не подтверждён.
- `bash release/verify_etonify_baseline.sh`, `go mod verify`, `git diff --check`: PASS.
- Фактический Windows pool reservation test в последнем запуске PASS;
  ранее наблюдался skip с WSAENOBUFS, он не скрыт.
- `go test -count=1 ./...`: FAIL только в восьми Windows административных
  интеграционных тестах WinDivert/TLS-spoof с SCM `Access is denied`.
  Это не чистый полный suite; тесты не изменены для подавления ошибок.

Linux CI, Unix OS reservation, ARM/ARM64 AAR, бинарный API/provenance и
ручная проверка на телефоне пока не выполнены. Ничего не пушилось и не собиралось
для Android. Свежий reviewer: три Important, ноль Critical/Minor, список
Declined to judge пуст. Прежние scoped shutdown, route chain и WireGuard
lifecycle исправления сохранены по review текущего diff.
