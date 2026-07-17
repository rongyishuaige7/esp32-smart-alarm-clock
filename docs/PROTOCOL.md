# 配网与局域网 REST 协议

## 两个网络阶段

### 阶段 A：AP 配网

当 NVS 中没有已保存的 SSID，或 STA 自动连接失败时，ESP32 创建开放 AP：

```text
SSID: ESP32_Alarm_Config
配置页: http://192.168.4.1:81
```

页面接受 `ssid` 与 `pass`，写入设备本地 Preferences 后自动重启。AP 没有密码或加密，不能把它当作安全管理页面。端口 81 只服务配网页；此时 REST API 不应被视为可用。

### 阶段 B：STA + REST

设备成功连接到用户配置的 Wi-Fi 后，固件启动 NTP 同步和端口 80 的 REST 服务。手机/电脑与设备应在同一个隔离可信局域网。默认回复使用 JSON 信封：

```json
{"success": true, "error": "", "data": {}}
```

部分业务失败会保留 HTTP 200 并在 JSON 中使用 `success: false`；Flutter 客户端必须同时检查 HTTP 状态码和信封字段。未知路径返回：

```text
HTTP 404
{"success":false,"error":"Not Found"}
```

## 端点

| 方法 | 路径 | 请求/响应要点 |
| :-- | :-- | :-- |
| `GET` | `/alarms` | 返回 `data` 数组，每项含 `id`、`hour`、`minute`、`enabled` |
| `POST` | `/alarms` | JSON：`hour` 0–23、`minute` 0–59、`enabled`；返回新对象 |
| `PUT` | `/alarms/{id}` | JSON 字段与 POST 相同；更新指定闹钟 |
| `DELETE` | `/alarms/{id}` | 删除指定闹钟 |
| `POST` | `/alarm/stop` | 停止活动闹钟和音频播放 |
| `GET` | `/status` | `temp`、`humidity`、`motion`、`alarm_active` |
| `GET` | `/time` | `hour`、`minute`、`second`、`date` |
| `OPTIONS` | 任意未注册路径 | CORS 预检，返回 204 |

固件开放 CORS：`Access-Control-Allow-Origin: *`，并且 API 无 TLS、认证、会话、授权、设备身份或请求签名。不得用于公网或不可信网络。

## 客户端地址规则

App 可接受裸 IP 或 `http://` 完整地址，并在本机 `shared_preferences` 保存。请求超时为 10 秒。初始的 `http://192.168.4.1` 是 AP 配网地址：用户必须改为实际的 STA IP 才能调用 REST。请求成功只说明该次 API 请求返回了可解析的成功信封，不是“设备在线”“音频已播放”或“传感器数据准确”的强证明。
