# libbox binary

Etonify bundles
[`hw20201/etonify-core`](https://github.com/hw20201/etonify-core/tree/feat/scoped-outbound-http-session)
based on the prerelease sing-box `v1.15.0-alpha.10` tag. The exact fork
version and source commit are recorded in `libbox.provenance.json`. The AAR
exposes Etonify's versioned capability
contract, targeted and bounded asynchronous URLTest sessions with failover,
structured probe failures, bounded XHTTP/SplitHTTP transports, opt-in VLESS
Encryption, resilient per-outbound external IP lookup, and bounded HTTP fetches
through the selected outbound. The sing-tun TCP/IP stack is the default;
the system stack remains available as a compatibility mode. WireGuard is not
included in the Android build.

Public-IP queries use the separate request-scoped API, not the legacy generic
HTTP fetch API. It freezes the outbound/DNS dependency plan, owns its sockets,
rejects redirects and supports request-ID cancellation without disconnecting
the shared command client. The first audited subset is literal-IP SOCKS5 or
HTTP/1 proxies with explicit same-chain literal-IP TCP/UDP DNS and no DNS rules;
unsupported dependencies fail closed. See `etonify-core/common/scopedhttp/README.md`.
Source/socket tests and compilation do not replace actual-device VPN, network
transition and split-route packet-capture validation.

`libbox.sha256` pins the exact AAR and is verified by CI before Android
compilation. `libbox.provenance.json` records the fork commit, upstream commit,
toolchain, Android API, and build tags used by the release workflow. Replacing
the binary requires updating both files and testing the Pigeon/Kotlin API
contract, Android unit tests, lint, assemble, upgrade from the previous release, and a device
soak test.
