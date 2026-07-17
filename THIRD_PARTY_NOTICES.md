# 第三方声明

仓库中的 Rongyi 原创固件、Flutter 客户端和文档以根目录 [MIT License](LICENSE) 公开。构建依赖由 PlatformIO、Flutter 或包管理器按需下载；本仓库不复制第三方框架、工具链、数据手册、厂商 Logo、音频、固件二进制或 EDA 文件。

## 固件构建与库

| 组件 | 公开工程中的版本/约束 | 用途 | 许可来源 |
| :-- | :-- | :-- | :-- |
| PlatformIO Core | 6.1.19 | 固件构建与包管理 | [Apache-2.0](https://github.com/platformio/platformio-core/blob/develop/LICENSE) |
| Espressif32 Platform | `espressif32@6.13.0`（由 `platformio.ini` 固定） | ESP32 平台定义 | [Apache-2.0](https://github.com/platformio/platform-espressif32/blob/develop/LICENSE) |
| Arduino-ESP32 framework | PlatformIO 解析的 2.0.17 | Wi-Fi、WebServer、Preferences、SPIFFS、I²S | [LGPL-2.1](https://github.com/espressif/arduino-esp32/blob/master/LICENSE.md)（以上游为准） |
| Adafruit GFX Library | `^1.11.9` | OLED 绘制 | [BSD-3-Clause](https://github.com/adafruit/Adafruit-GFX-Library/blob/master/license.txt) |
| Adafruit SSD1306 | `^2.0.0` | SSD1306 驱动 | [BSD-3-Clause](https://github.com/adafruit/Adafruit_SSD1306/blob/master/license.txt) |
| Adafruit DHT sensor library | `^1.4.4` | DHT 读取 | [MIT](https://github.com/adafruit/DHT-sensor-library/blob/master/license.txt) |
| ArduinoJson | `^6.21.3` | JSON 编解码 | [MIT](https://github.com/bblanchon/ArduinoJson/blob/6.x/LICENSE.md) |

包管理器会按兼容版本解析实际依赖；构建日志中的解析版本是构建证据，不等于上游长期支持承诺。

## Flutter 客户端

| 组件 | `app/pubspec.yaml` 约束 | 用途 | 许可来源 |
| :-- | :-- | :-- | :-- |
| Flutter / Dart SDK | 本机验证 Flutter 3.41.2 / Dart 3.11.0 | 客户端框架和工具链 | [BSD-3-Clause](https://github.com/flutter/flutter/blob/master/LICENSE) |
| provider | `^6.1.1` | 状态管理 | [MIT](https://github.com/rrousselGit/provider/blob/master/LICENSE) |
| http | `^1.1.0` | HTTP 客户端 | [BSD-3-Clause](https://github.com/dart-lang/http/blob/master/LICENSE) |
| shared_preferences | `^2.3.3` | 本地保存设备地址 | [BSD-3-Clause](https://github.com/flutter/packages/blob/main/packages/shared_preferences/shared_preferences/LICENSE) |
| intl / cupertino_icons | `^0.19.0` / `^1.0.8` | 格式化与图标 | 以各包随附许可为准 |

ESP32、SSD1306、DHT11、PIR、MAX98357A 和相关名称/商标属于各自权利人。列出兼容模块不表示厂商背书。

## 不随仓库分发的素材

原始项目目录中存在的 WAV 无法在公开前逐个确认来源与再分发许可，故未包含在本仓库、CI Artifact 或 Release。使用者应自行准备可合法使用的音频，详见 [`firmware/data/audio/README.md`](firmware/data/audio/README.md)。
