# Исправленный sing-tun: наш fork, submodule и фактическое подключение

## Цель и согласованный выбор

Исправить три воспроизведённых дефекта sing-tun из переноса forward NAT:
поздний UDP-ответ после reset, преждевременное завершение fragment association
из-за дубликатов и повторное освобождение общего NAT при Close.

Пользователь выбрал собственный fork, подключённый submodule, и требует,
чтобы ядро действительно использовало его. Это заменяет предложение хранить
обычную копию исходников в репозитории. Отдельное сопровождение полностью
устранить нельзя: наша ветка содержит только необходимые исправления и тесты,
upstream-обновления не выполняются автоматически.

## База и границы

- Клиент: master, версия 0.3.9+39, рабочий AAR пока не меняется.
- Рабочее ядро: etonify-dev, HEAD `0fe9bbb66cbe998d6ca22a53e3d3a807c3a148f7`.
- Публичная доставленная база ядра: `69425e4fbe5d3c67b692226dabc6f11ffe20072c`.
- Upstream sing-tun: `5c2edb183cc92eb190d41c04dedfa5519ca3e78c`,
  module version `v0.9.7-0.20261009022811-5c2edb183cc9`.
- Fork: `yamixdev/sing-tun`, источник `SagerNet/sing-tun`.
  Аккаунт yamixdev подтверждён read-only проверкой; fork ещё не создан.
- Путь внутри ядра: `third_party/sing-tun`; в клиенте это
  `etonify-core/third_party/sing-tun`.
- Работать в текущем checkout. Не менять UI, Android network recovery,
  правила трафика, публичный libbox API, другие Go-зависимости и Android tags.
- Сохранить два незакоммиченных файла с reproducer-тестами, не ослаблять их.
  Локальные кеши и мусор не коммитить. Module cache не редактировать.
- Host-тесты разрешены. APK/AAR/Android-core на ПК не собирать.

## Подключение и фиксация исходников

Fork создаётся после согласования письменной спецификации и плана. Исправления
делаются от точного upstream SHA, а не от движущегося HEAD. Рабочая ветка
fork: `codex/etonify-nat-fixes`; gitlink ядра всегда закрепляет полный commit.
Обновление submodule с `--remote` не является частью сборки.

В core go.mod сохраняются upstream module path и точный require. Для этой
версии задаётся local replacement:

```go
replace github.com/sagernet/sing-tun v0.9.7-0.20261009022811-5c2edb183cc9 => ./third_party/sing-tun
```

Module path внутри fork остаётся `github.com/sagernet/sing-tun`; импортам
не требуется переименование. Submodule без replace недостаточен: Go продолжил
бы использовать скачанный upstream. При отсутствующем checkout сборка должна
завершаться понятной ошибкой, без fallback к исходной зависимости.

Проверочный gate сверяет gitlink, checkout SHA, URL fork, точный require и
фактический Dir/Replace из `go list -m -json`. CI проверяет чистый checkout;
локальные RED/GREEN тесты могут выполняться во время редактирования fork.
Существующий overlay runner адаптируется к нашему replacement, но не разрешает
произвольные сторонние replacement или незаметную смену базовой версии.

## Семантика исправлений

1. **Однократный Close.** Только один вызов становится владельцем shutdown:
   конкурентные и повторные вызовы не повторяют detach, releasePortNAT или
   закрытие flows. Общий allocator сохраняется, пока им владеет другой
   dispatcher. Проверяются Start/Close окружающих устройств и отсутствие гонок
   между регистрацией return path и закрытием.
2. **Фрагменты.** Завершение определяется покрытием уникальных диапазонов,
   а не суммой длин пришедших пакетов. Дубликат/перекрытие не заменяет пропущенный
   диапазон. IPv4/IPv6, transport checksum и изоляция fragment keys сохраняются.
   TTL 30 секунд и capacity 4096 остаются; новое состояние ограничено по памяти,
   некорректные offsets/lengths не вызывают panic или неограниченную аллокацию.
3. **Поздние UDP-ответы.** После закрытия последнего flow его NAT selector
   нельзя немедленно отдавать новой сессии. Предусматривается ограниченный
   карантин на существующий flow tombstone window 4 минуты, общий для владельцев
   одного Port. Во время карантина ответы не доставляются и selector не
   переиспользуется; после истечения он возвращается в allocator. Исчерпание
   обрабатывается существующим отказом/расширением диапазона, не обходом защиты.
   Живые mappings сохраняют reference ownership и заданные mapping/filtering
   режимы. TCP и ICMP не получают UDP-карантин. Последний Close освобождает
   kernel reservations, закрытые return paths не принимают пакеты.

Карантин даёт ограниченное окно защиты, а не доказательство распознавания
произвольно поздней UDP-датаграммы: в UDP нет идентификатора поколения сети.
Проверяется нагрузка при частых resets/коротких диапазонах, чтобы защита не
превратилась в скрытое исчерпание портов или постоянное удержание ресурсов.

## CI, источник сборки и provenance

В jobs ядра, использующих Go или формирующих source archive, явно инициализировать
закреплённый `third_party/sing-tun`. Не клонировать ненужные clients submodules
только ради этого изменения. Добавить `.gitmodules` и gitlink нового submodule
в push path filters. Workflow клиента уже использует recursive checkout;
его production path дополнить проверкой фактической зависимости.

Обычный git archive не доставляет исходники nested submodule. Архив ядра должен
включать дерево нашего fork в `third_party/sing-tun/` ровно из закреплённого
gitlink, включая лицензии. Проверка извлечённого архива подтверждает полноту
и возможность разрешения local replacement без module cache sing-tun.

Provenance обоих AAR workflows дополняется repository URL, исправленным SHA и
upstream base SHA sing-tun. Client validator сверяет новый SHA с gitlink ядра;
старый подтверждённый AAR не перестаёт приниматься только из-за новых полей.
API hash, ARM/ARM64 ABI и SHA256 бинарника проверяются прежними gates.

## Проверки и доставка

Сначала RED для каждого дефекта, затем минимальный fix и GREEN. Три текущих
reproducer сохраняются; добавить shared-owner concurrent Close, IPv4/IPv6
duplicate/out-of-order/overlap/expiry/capacity, UDP quarantine expiry,
reservation release, repeated reset, reuse после TTL и exhaustion.

Гонять tests самого fork (отдельный Go module), packet/lifecycle/race suites
ядра, tagged Android corpus и host-consumer compile gates. `go test ./...`
из ядра не заменяет запуск тестов nested module. Ограничения Windows
WinDivert/SCM отражать явно; Linux CI и телефон не объявлять проверенными заранее.

После одного независимого review подготовить core revision
`v1.15.0-alpha.10-etonify.3`. Создание fork пользователь предложил, но доставка
исправленных commits отдельно согласуется: сначала fork commit, затем core
gitlink, затем client core pointer и verified AAR. Core push автоматически
запускает AAR/draft-release workflow; APK workflow без разрешения не запускать.

## Статус и основания

Направление fork + submodule выбрано пользователем. Документ представлен для
проверки; продуктовый код, submodule и внешние репозитории пока не изменяются.
После одобрения документа составляется письменный implementation plan.

Официальные контракты:
- [Go local replace](https://go.dev/ref/mod#go-mod-file-replace).
- [Git pinned submodule update](https://git-scm.com/docs/git-submodule).
- [Git archive](https://git-scm.com/docs/git-archive).
