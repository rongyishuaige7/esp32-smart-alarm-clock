# Hardware Lab 索引卡片

```yaml
name: ESP32 智能闹钟
platform: ESP32 · Arduino · PlatformIO · Flutter · OLED · DHT11 · PIR · MAX98357A
summary: 基于 ESP32、OLED、DHT11、PIR、MAX98357A 与 Flutter 局域网客户端的智能闹钟教学原型。
status: 源码来源已确认 · 硬件无关源码契约已通过 · 固件与 Flutter 构建已验证 · 当前端到端链路尚未重新真机复测
media_scope: 当前没有实物照片、演示视频、EDA、PCB 或制造文件；公开 BOM、接线边界图、协议、来源和验证说明。
known_boundaries:
  - AP 配网和 STA REST 都不是安全网络服务；HTTP 无认证和 TLS，只面向隔离可信局域网。
  - 当前未分发 WAV；没有使用者自备的合法音频时，声音功能不会完成。
  - 构建与源码契约不证明 NTP、传感器、OLED、I²S、按钮、Wi-Fi 或 App 端到端行为。
  - Actions Artifact 仅保留 14 天。
```
