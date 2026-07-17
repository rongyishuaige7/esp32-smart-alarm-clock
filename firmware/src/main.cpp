#include <Arduino.h>
#include "constants.h"
#include "WiFiManager.h"
#include "TimeManager.h"
#include "DisplayManager.h"
#include "AlarmManager.h"
#include "DHTManager.h"
#include "MotionDetector.h"
#include "AudioManager.h"
#include "WebServerManager.h"

WiFiManager wifiManager;
TimeManager timeManager;
DisplayManager displayManager;
AlarmManager alarmManager;
DHTManager dhtManager;
MotionDetector motionDetector;
AudioManager audioManager;
WebServerManager webServerManager;

// 供AlarmManager使用的外部时间管理器指针
// g_timeManager在AlarmManager.cpp中定义，在setup()中初始化
extern TimeManager* g_timeManager;

// 供WebServerManager使用的外部全局实例指针
extern AlarmManager* g_alarmManager;
extern DHTManager* g_dhtManager;
extern MotionDetector* g_motionDetector;
extern AudioManager* g_audioManager;

// 全局指针定义（在WebServerManager.cpp中使用）
AlarmManager* g_alarmManager = nullptr;
DHTManager* g_dhtManager = nullptr;
MotionDetector* g_motionDetector = nullptr;
AudioManager* g_audioManager = nullptr;

// 停止按钮中断处理
volatile bool stopButtonPressed = false;

void IRAM_ATTR stopButtonISR() {
    stopButtonPressed = true;
}


static String dhtStatusLine() {
    if (!dhtManager.hasReadings()) {
        return "T:-- H:--%";
    }
    return String("T:") + String(dhtManager.getTemperature(), 1) + " H:" +
           String(dhtManager.getHumidity(), 1) + "%";
}

static void refreshDisplayFromTime() {
    displayManager.showTime(timeManager.getTimeString());
    displayManager.showDate(timeManager.getDateString());
    displayManager.showNTPStatus(timeManager.isNTPConnected());
    displayManager.showAlarm(alarmManager.isAlarmActive());
}

void setup() {
    Serial.begin(115200);
    Serial.println("ESP32 Smart Alarm Clock Starting...");

    // 初始化AlarmManager并设置时间管理器指针
    alarmManager.begin();
    g_timeManager = &timeManager;

    // 设置WebServerManager使用的全局指针
    g_alarmManager = &alarmManager;
    g_dhtManager = &dhtManager;
    g_motionDetector = &motionDetector;
    g_audioManager = &audioManager;

    // 停止按钮中断初始化
    pinMode(PIN_STOP_BUTTON, INPUT_PULLUP);
    attachInterrupt(PIN_STOP_BUTTON, stopButtonISR, FALLING);

    // OLED显示屏初始化
    displayManager.begin();

    // DHT11 温湿度传感器初始化
    dhtManager.begin();

    // PIR传感器和LED初始化
    motionDetector.begin();

    // 音频管理器初始化
    audioManager.begin();

    // WiFi连接（REST 仅在 STA 成功后再启动，避免与 AP 配网端口冲突）
    Serial.println("Connecting to WiFi...");
    if (!wifiManager.autoConnect()) {
        Serial.println("Failed to auto-connect, setting up AP mode...");
        wifiManager.setupAP();
        Serial.println("AP mode started. Connect to ESP32_Alarm_Config, open http://192.168.4.1:" +
                       String(WIFI_AP_HTTP_PORT) + " to configure WiFi.");
        displayManager.showStatus("AP Mode");
        displayManager.showNTPStatus(false);
    } else {
        Serial.println("WiFi connected: " + wifiManager.getIP());

        webServerManager.begin();

        // NTP时间同步
        Serial.println("Syncing time from NTP...");
        if (timeManager.syncFromNTP()) {
            Serial.println("NTP sync successful!");
            Serial.println("Current time: " + timeManager.getTimeString());
            Serial.println("Current date: " + timeManager.getDateString());
            displayManager.showNTPStatus(true);
            refreshDisplayFromTime();
        } else {
            Serial.println("NTP sync failed.");
            displayManager.showNTPStatus(false);
            displayManager.showStatus("NTP Failed");
        }
    }

    // 初始 DHT 状态行（无有效读数时显示 --）
    if (wifiManager.isConnected()) {
        displayManager.showStatus(dhtStatusLine());
    }
    displayManager.update();
}

void loop() {
    // 停止按钮中断处理
    if (stopButtonPressed) {
        stopButtonPressed = false;
        alarmManager.stopAlarm();
        audioManager.stop();
    }

    // 更新 DHT11 温湿度数据（用于状态行）
    dhtManager.update();

    // 更新 PIR 传感器状态
    motionDetector.update();

    // NTP 定期重同步（仅 STA 已连接时有效）
    if (wifiManager.isConnected()) {
        timeManager.update();
    }

    // 每秒刷新 OLED 时间与日期（含 AP 模式）
    static int lastDisplayedSecond = -1;
    int sec = timeManager.getSecond();
    if (sec != lastDisplayedSecond) {
        lastDisplayedSecond = sec;
        refreshDisplayFromTime();
        displayManager.showStatus(dhtStatusLine());
    }

    if (wifiManager.isAPMode()) {
        wifiManager.handleAP();
    } else {
        webServerManager.handle();
    }

    // 更新显示（AP 模式下仍刷新 OLED）
    displayManager.update();

    // 闹钟触发检测
    // 每轮序列（TTS + 铃声）播完后等 30 秒再重播，防止用户不操作时无限循环。
    // 按键或 App 调用 stopAlarm() 会把 activeAlarmId 清为 -1，彻底停止。
    static unsigned long lastSequenceEndMs = 0;
    static const unsigned long REPEAT_INTERVAL_MS = 30000UL; // 30 秒

    int triggeredAlarmId = alarmManager.checkAlarms();
    if (triggeredAlarmId == -1) {
        lastSequenceEndMs = 0;
    } else if (!audioManager.isPlaying()) {
        unsigned long now = millis();
        if (lastSequenceEndMs == 0) {
            // 刚触发或刚播完，立即启动
            lastSequenceEndMs = now;
            audioManager.playAlarmSequence();
        } else if (now - lastSequenceEndMs >= REPEAT_INTERVAL_MS) {
            lastSequenceEndMs = now;
            audioManager.playAlarmSequence();
        }
    }
}
