#ifndef CONSTANTS_H
#define CONSTANTS_H

// GPIO定义
#define PIN_OLED_SDA      21
#define PIN_OLED_SCL      22
#define PIN_STOP_BUTTON   18
#define PIN_PIR           19
#define PIN_LED           5   // 只接 G（绿）。共阴：公共脚接 GND；共阳：公共脚接 3.3V
// true = 共阳（低电平点亮）；false = 共阴（高电平点亮）。接错会导致「有人灭、无人亮」
#define LED_RGB_COMMON_ANODE 0

#define PIN_DHT           4   // DHT11 数据线（与 DHT22 引脚兼容）

// I2S引脚 (MAX98357A)
#define PIN_I2S_BCLK      26
#define PIN_I2S_WS        25
#define PIN_I2S_DIN       33

// 硬件配置
#define I2S_SAMPLE_RATE   16000
#define DHT_TYPE          DHT11

// AP 配网 HTTP 端口（避免与 STA 下 REST 的 80 端口冲突）
#define WIFI_AP_HTTP_PORT 81

// 时间配置
#define NTP_SERVER        "ntp.aliyun.com"
#define NTP_TIMEZONE      8  // UTC+8
#define NTP_SYNC_INTERVAL 3600  // 每小时校正

// 运动检测超时(秒)
#define MOTION_TIMEOUT    30   // 30秒无运动关闭LED

#endif
