# HTTPS 小响应测量器

这是独立的开发测量工具，不接入 UI、生产下载或自动选路，不修改版本、路由、DNS 或系统代理。它测量小响应 HTTPS GET，不代表浏览器整页加载，也不是纯网络 RTT。

## 两组数字不能混在一起

每个样本对新建一个 `HttpClient`，先请求目标，再在同一个 client 完整消费响应后请求同一个 URL。每对结束关闭 client。

- **new-client**：新 client 的第一次请求；不承诺操作系统 DNS/TLS 缓存已清空。
- **verified-reused**：两次连接信息的 localPort、remoteAddress、remotePort 全部已知且一致，才确认复用，纳入单独的 warm 中位数。
- **reconnected**：信息已知但连接元组不同，不纳入 warm 统计。
- **reuseUnknown**：连接信息缺失，既不宣称复用，也不宣称一定重连。

`headerMs` 是发请求前到收到响应头的耗时；`bodyMs` 是发请求前到响应体完整消费的**总耗时**，不是单独下载 body 的耗时。新连接可能含 DNS、TCP、TLS 与服务端处理时间；复用请求仍含网络传输和服务端处理。JSON 自带计时定义、GET 方法、网络模式和限额元数据。

每个目标分别计算新 client 和确认复用样本的响应头/总耗时中位数，不将失败或重连混进 warm。`failed` 为已尝试但失败的请求总数，`timedOut`、`bodyTooLarge` 是其中的分类；`skipped` 单独统计。首个请求失败时跳过同对第二次请求。小样本不报告夸张的百分位或宣称性能提升。

## 使用

```sh
/opt/flutter/bin/dart run tool/https_latency_probe.dart \
  --context sandbox-control-not-phone \
  --url https://example.com/robots.txt --samples 3 \
  --output /tmp/result.json
```

`--context` 必填，明确测量设备/路径。可重复 `--url`，目标最多 5 个；`--samples` 是每目标样本对数，范围 1–10。每对最多两次请求。`--timeout` 为每请求整体超时，范围 1–30 秒，覆盖响应头和响应体；超时会强制关闭 client。响应体默认上限 64 KiB，`--max-body-bytes` 允许 1–1,048,576 字节，声明长度和流式字节数均受限，发现超限即终止，不继续读完整大响应。

默认保留 Dart client 的环境代理行为，因此不应称默认路径一定是 direct，更不能据此断言用户 VPN 路由。可显式指定 `--http-proxy http://host:port`；IPv6 如 `http://[::1]:8080`。代理仅作用于本次测量 client，使用 HTTP CONNECT，失败不会回退 DIRECT。只接受无凭据、无额外 path/query 的 HTTP authority，端口必须显式提供；不是 SOCKS 代理接口。

只接受 HTTPS 目标，拒绝 userinfo/query/fragment，不跟随重定向，只有 2xx 算成功。严格验证证书，不设置 badCertificateCallback、HttpOverrides 或自定义 DNS。JSON 不额外输出连接 IP/端口、代理地址、响应内容、请求头或原始异常；目标 URL 本身按输入保留。未知选项和越界参数在联网前拒绝。参数错误返回非零，单个请求失败不阻止其他目标。

**沙盒结果只能是沙盒对照，不能代表手机、蜂窝/Wi-Fi 或用户节点链路，不能据此调整生产分流。** 真正链路优化需要在目标设备/明确代理路径上收集相同目标、相同方法的配对数据。不要为测量而把本地代理开放到公网。

## 为什么不直接套用 Clash 字段

[Mihomo 的 `Proxy.URLTest`](https://raw.githubusercontent.com/MetaCubeX/mihomo/Meta/adapter/adapter.go) 在统一延迟打开时，第一次 HEAD 后尝试用同 client 再发 HEAD；第二次成功才从第二次开始计时。它不是减去一个固定常量，失败回退的口径也不同。当前捆绑 sing-box 的 `etonify-core/common/urltest/urltest.go` 另有协议相关的预热和计时边界，不能把 Clash 的 `unified-delay` 原样写进 sing-box。

本工具将 GET 新连接与确认复用结果分别展示，不替换原生 URLTest，也不把两种口径合并用于自动选路。现有中国规则、自定义规则优先级和 Google Play 代理规则均不改。

## 测试

`test/https_latency_probe_test.dart` 使用本地 TLS 服务，覆盖成功与复用、服务端关闭导致重连、拒绝不受信证书、禁止重定向、声明/流式超限、响应头/响应体整体超时及输入边界。`test/fixtures/https_probe/` 的证书和私钥仅为公开的 localhost 测试夹具，绝不能用于生产；只有测试 client 明确信任它，不关闭证书校验。

参考：[Dart HttpClient](https://api.dart.dev/dart-io/HttpClient-class.html)（HTTPS、持久连接与默认环境代理）、[HttpConnectionInfo](https://api.dart.dev/dart-io/HttpConnectionInfo-class.html)（连接信息）。
