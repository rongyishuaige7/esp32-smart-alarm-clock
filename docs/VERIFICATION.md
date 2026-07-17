# 验证说明

> 状态日期：2026-07-17

## 一键本地门禁

```bash
bash scripts/verify.sh
```

门禁依次执行：

1. 敏感信息、私钥、真实 Wi-Fi、个人路径、WAV 和生成物检查；
2. 必需文件、目录结构、BOM、SVG、状态文案和 PlatformIO 固定版本检查；
3. 不依赖硬件的 Python 源码契约测试；
4. 在临时副本中执行 PlatformIO 固件干净构建；
5. `app/` 的 `flutter pub get`、`flutter test`、`flutter analyze`、`flutter build web --release`。

门禁不会烧录 ESP32、连接真实 Wi-Fi、发送配网密码、访问真实 REST 设备、播放音频或启动移动端真机。

## 已验证环境与结果

```text
PlatformIO Core: 6.1.19
Platform: Espressif32 6.13.0
Framework: Arduino-ESP32 2.0.17
Board target: esp32dev
Flutter: 3.41.2
Dart: 3.11.0
```

2026-07-17 的隔离构建结果：

```text
Firmware RAM:   47448 / 327680 bytes (14.5%)
Firmware Flash: 921109 / 1310720 bytes (70.3%)
Flutter: widget test passed; analyze passed; release web build passed
```

这些是构建证据。它们不证明板卡 Flash 实际可用、烧录、音频、Wi-Fi、NTP、传感器、OLED、按钮或 App 与设备的端到端行为。

## 当前真机复测清单

后续复测必须记录日期、完整 Git commit、精确板型、模块/电源事实以及每项通过、失败或未测：

- [ ] 确认 ESP32 开发板型号、Flash、USB 芯片与稳定供电；
- [ ] 确认 OLED 型号/电压/上拉，GPIO21/22 显示正常；
- [ ] 确认 DHT11 供电、GPIO4 和稳定读数；
- [ ] 确认 PIR GPIO19 的触发、保持时间和 LED GPIO5 行为；
- [ ] 确认停止按钮 GPIO18 的接线、去抖和停止逻辑；
- [ ] 确认 MAX98357A、扬声器、电源、I²S GPIO26/25/33；
- [ ] 只使用有再分发权的 WAV，验证缺少素材与存在素材的两条路径；
- [ ] 烧录当前 commit，串口启动、SPIFFS 挂载与异常路径记录；
- [ ] 无保存 Wi-Fi 时确认 AP、端口 81 配网页和重启保存行为；
- [ ] 使用测试 Wi-Fi 完成 STA，记录实际分配 IP；
- [ ] 验证 NTP 成功和失败路径，不将失败写成当前时间准确；
- [ ] 验证 `/alarms`、`/status`、`/time`、`/alarm/stop`、更新/删除与未知路径真实 404；
- [ ] 用 Android/iOS 实机或明确的平台运行 Flutter App，地址配置、超时、错误态和停止指令逐项检查；
- [ ] 进行 30–60 分钟受控运行，记录重启、内存、Wi-Fi、音频和 API 超时；
- [ ] 照片、视频、日志去除 EXIF/GPS、SSID、密码、私网拓扑、账号和个人信息。

只有完成相应清单，才能把“当前硬件尚未重新真机复测”升级为精确、可审计的真机结论。
