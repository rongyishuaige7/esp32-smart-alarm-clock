# ESP32 智能闹钟

[![验证](https://github.com/rongyishuaige7/esp32-smart-alarm-clock/actions/workflows/validate.yml/badge.svg)](https://github.com/rongyishuaige7/esp32-smart-alarm-clock/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-orange.svg)](LICENSE)

一个基于 ESP32 和 Flutter 的局域网智能闹钟教学原型：ESP32 通过 OLED 显示时间和环境数据，DHT11、PIR、实体停止键、MAX98357A I²S 音频与 NTP 校时由固件协调；Flutter 客户端通过本地 HTTP REST 管理闹钟、读取设备返回的数据并发送停止指令。

> **项目状态（2026-07-17）：** 源码来源已确认，硬件无关源码契约、PlatformIO 固件干净构建、Flutter 客户端测试、静态分析和 Web 构建已验证；**当前 ESP32、OLED、DHT11、PIR、MAX98357A、实体按键及 Flutter App 的端到端链路尚未重新真机复测。** 当前没有公开实物照片、演示视频、EDA、PCB 或制造文件。

## 系统结构

```text
OLED ─ I²C ───────────────────────────┐
DHT11 ─ GPIO4 ─────────────────────────┤
PIR / 单色 LED ─ GPIO19 / GPIO5 ───────┤
停止按钮 ─ GPIO18 ─────────────────────┼─→ ESP32 ── HTTP REST ── Flutter 客户端
MAX98357A ─ I²S GPIO26/25/33 ──────────┤       │
                                        └───────┴── STA + NTP

无已保存 Wi-Fi ─→ 开放 AP 配网：ESP32_Alarm_Config
                   http://192.168.4.1:81
```

这是按源码整理的结构与接线边界，不是 PCB 原理图，也不表示硬件当前在线或已经重新验证。

## 学习内容

- ESP32 STA/AP 配网状态切换、Preferences 保存和 NTP 周期校时；
- SSD1306 OLED、DHT11、PIR、实体中断按键和单色 LED 的协作；
- MAX98357A I²S 与 SPIFFS PCM WAV 文件读取；
- `GET/POST/PUT/DELETE` REST API、JSON 信封和真实 HTTP 404；
- Flutter + Provider + `http` + `shared_preferences` 的局域网客户端；
- 固件和客户端双构建，以及公开前的素材、密钥和构建产物门禁。

## 硬件与引脚

| 模块/信号 | ESP32 GPIO / 接口 | 说明 |
| :-- | :-- | :-- |
| OLED SDA / SCL | GPIO21 / GPIO22 · I²C | SSD1306 显示模块 |
| DHT11 DATA | GPIO4 | 温湿度输入；当前源码默认 `DHT11` |
| 停止按钮 | GPIO18 | 内部上拉、下降沿中断 |
| PIR | GPIO19 | 人体感应输入 |
| RGB 模块的绿灯 | GPIO5 | 当前只用 G 通道，不是完整 RGB PWM |
| MAX98357A BCLK / WS / DIN | GPIO26 / GPIO25 / GPIO33 · I²S | 音频输出 |

接线前请阅读 [HARDWARE.md](HARDWARE.md)、[BOM](hardware/BOM.csv) 和[接线边界图](hardware/wiring-diagram.svg)。ESP32 为 3.3 V 逻辑；所有模块必须共地。GPIO 不能直接驱动大电流扬声器、继电器、电机、灯带或市电负载。

## 网络与 API 边界

- 无已保存 Wi-Fi 时，固件创建开放 AP `ESP32_Alarm_Config`，配网页面是 `http://192.168.4.1:81`；这是本地教学配网入口，不是 REST 服务。
- 设备成功连接到用户自己配置的 Wi-Fi（STA）后，REST 才在端口 80 启动。
- REST API 没有认证、TLS、会话或设备身份，且设置 `Access-Control-Allow-Origin: *`；**只适合隔离可信局域网，绝不能暴露到公网、校园网或不可信网络。**
- Flutter 的 Android 配置允许明文 HTTP、iOS 配置允许本地网络，是为了访问设备本地 API，不表示连接加密或远程服务健康。
- 客户端显示的是某次 HTTP 请求返回的设备数据；请求失败只表示当前请求未完成，不能据此推断设备、电源、传感器或网络整体状态。

| 方法 | 路径 | 作用 |
| :-- | :-- | :-- |
| `GET` | `/alarms` | 获取闹钟列表 |
| `POST` | `/alarms` | 新增闹钟：`hour`、`minute`、`enabled` |
| `PUT` / `DELETE` | `/alarms/{id}` | 更新或删除指定闹钟 |
| `POST` | `/alarm/stop` | 请求停止当前闹钟与音频 |
| `GET` | `/status` | 温度、湿度、PIR 状态和闹钟活动标志 |
| `GET` | `/time` | 固件当前时间字段 |

完整约定见 [协议说明](docs/PROTOCOL.md)。未知路径在 STA REST 服务中返回真实 HTTP `404` JSON。

## 构建

已验证环境：PlatformIO Core 6.1.19、Espressif32 6.13.0、Flutter 3.41.2、Dart 3.11.0。

```bash
git clone https://github.com/rongyishuaige7/esp32-smart-alarm-clock.git
cd esp32-smart-alarm-clock
bash scripts/verify.sh
```

单独构建：

```bash
# 固件
pio run -d firmware

# Flutter 客户端
cd app
flutter pub get
flutter test
flutter analyze
flutter build web --release
```

`verify.sh` 在临时固件副本中构建，避免在仓库工作树留下 `.pio`。CI Artifact 同时包含固件和 Flutter Web 构建证据，保留 14 天；它们不是已烧录、已联网或已真机验证的产品发布包。

## 配网与客户端使用

1. 烧录固件；若没有已保存 Wi-Fi，手机或电脑连接 `ESP32_Alarm_Config`，打开 `http://192.168.4.1:81` 并提交**自己的** Wi-Fi；提交后设备会重启。
2. 从串口日志或路由器 DHCP 列表确认设备实际 IP；REST 仅在 STA 成功后可用。
3. 在 Flutter App 的“设备地址”中填写该实际 IP 或完整 `http://<设备IP>`。App 初始显示的 `192.168.4.1` 是中性配网地址，不是已发现、已连接或可用的 REST 设备地址。
4. 在受控局域网中用 App 或 `curl http://<设备IP>/time` 进行联调。

固件启动和 App 网络请求的验证范围见 [验证说明](docs/VERIFICATION.md)。

## 音频素材

本仓库没有打包现成 TTS 或铃声音频，因为原始 WAV 无法逐一确认再分发许可。若自行启用音频，请只添加你拥有再分发权的 PCM WAV，并遵循 [`firmware/data/audio/README.md`](firmware/data/audio/README.md)。没有这些文件时，固件仍可构建，但闹钟声音不会播放。

## 目录

```text
app/                 Flutter 客户端源码
firmware/            ESP32 + PlatformIO 固件
hardware/            BOM 和源码推导的接线边界图
scripts/             敏感信息、结构与一键验证门禁
tests/               不依赖硬件的源码契约检查
docs/                来源、协议、状态、验证和 GitHub 元数据
```

## 当前公开范围与限制

- 构建和源码契约不证明烧录成功、NTP 可达、OLED 显示、DHT11 精度、PIR 灵敏度、I²S 音量、按钮去抖或 App 真机连接；
- 当前没有公开实物照片、演示视频、EDA、原理图、PCB、Gerber 或制造文件；接线图不是电气审查后的原理图；
- AP 配网是开放网络，STA REST 也没有认证或 TLS；不得复用个人密码、不得暴露公网；
- 单色 LED 只使用 RGB 模块的绿灯通道；固件并未实现多色指示；
- 无公开音频素材时，声音功能不能完成；不能将“编译通过”描述成“已正常播放”；
- App 采用 10 秒请求超时和本地保存的设备地址；它不是远程管理、设备发现、身份认证或离线同步系统；
- 本原型不是消费级闹钟、安防设备、医疗设备或可靠性承诺。

完整状态见 [项目状态](docs/PROJECT_STATUS.md)。

## 许可证与教学使用

Rongyi 原创源码以 [MIT License](LICENSE) 公开。PlatformIO、Arduino、Flutter 和第三方库的来源与许可见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

欢迎用于课程实验、毕业设计参考和个人学习；请遵守许可证并在使用重要代码、结构或文档时保留署名。不要把本仓库或其文档原样冒充为自己的课程设计、毕业设计或竞赛成果。
