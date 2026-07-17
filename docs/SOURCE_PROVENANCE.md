# 源码来源与权威副本裁决

> 状态日期：2026-07-17

## 只读来源

```text
/home/rongyi/桌面/esp32_alarm_clock
/mnt/shared/2026项目/esp32_alarm_clock.zip
```

历史 ZIP SHA-256：

```text
e8a457031cd3f194ca18dd096aaff433998a27765432da440650efec709b391b
```

整理时排除了 `.pio`、`.gradle`、`.dart_tool`、`build`、`dist`、`.idea`、Flutter `ephemeral`、`.iml` 与其他生成物。两个来源的 180 个有效文件逐文件内容清单一致，manifest SHA-256 为：

```text
cea0eb2af1cfbd90ee15f1a901f1246faee4519b6822fa624c394ea34c67e6bb
```

## 裁决

- 桌面目录与历史 ZIP 的选定有效源码文件相同；
- ZIP 是只读历史封存基线；
- 桌面目录是本轮整理的权威源码来源；
- 以上路径仅用于来源审计，不是公开仓库的构建依赖；原目录和 ZIP 不由公开候选反向覆盖或删除。

## 公开候选的可审计改动

公开候选目录是：

```text
/home/rongyi/桌面/esp32-smart-alarm-clock
```

在不改动来源目录的前提下：

1. 将固件与 Flutter 客户端重组为 `firmware/` 和 `app/`；
2. 排除 APK、`.pio`、`.gradle`、`.dart_tool`、IDE 状态、Flutter ephemeral 文件和所有构建产物；
3. 不分发来源/许可未逐一确认的 WAV；只保留用户自备素材的文件名与格式说明；
4. 将客户端默认地址改为中性的 AP 配网地址 `http://192.168.4.1`，并明确其不是已连接的 REST 设备；
5. 固定 ESP32 PlatformIO 平台、补充中文 README、BOM、接线边界图、网络/音频安全边界、协议、验证、许可证、第三方声明和 CI；
6. 修复 Flutter widget 测试的标题断言，使其与实际界面 `ESP32 智能闹钟` 一致。

这些属于公开前的可审计整理与构建加固，不得表述为当前硬件、网络、音频或 App 已完成重新真机验证。
