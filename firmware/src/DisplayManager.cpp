#include "DisplayManager.h"
#include "constants.h"

DisplayManager::DisplayManager() : display(nullptr), ntpStatus(false), alarmActive(false) {}

void DisplayManager::begin() {
    Wire.begin(PIN_OLED_SDA, PIN_OLED_SCL);
    display = new Adafruit_SSD1306(128, 64, &Wire, -1);
    display->begin(SSD1306_SWITCHCAPVCC, 0x3C);
    display->setTextSize(2);
    display->setTextColor(SSD1306_WHITE);
    clear();
    update();
}

void DisplayManager::clear() {
    if (display) {
        display->clearDisplay();
    }
}

void DisplayManager::update() {
    if (!display) {
        return;
    }
    display->clearDisplay();

    // 时间 (大字)
    display->setTextSize(2);
    display->setCursor(0, 0);
    display->println(currentTime);

    // 日期 (小字)
    display->setTextSize(1);
    display->setCursor(0, 24);
    display->println(currentDate);

    // 状态行
    display->setCursor(0, 40);
    display->println(statusLine);

    // NTP状态指示
    display->setCursor(100, 56);
    display->print(ntpStatus ? "N" : "n");

    // 闹钟状态指示
    display->setCursor(112, 56);
    display->print(alarmActive ? "A" : "-");

    display->display();
}

void DisplayManager::showTime(const String& timeStr) {
    currentTime = timeStr;
}

void DisplayManager::showDate(const String& dateStr) {
    currentDate = dateStr;
}

void DisplayManager::showStatus(const String& status) {
    statusLine = status;
}

void DisplayManager::showAlarm(bool isActive) {
    alarmActive = isActive;
}

void DisplayManager::showNTPStatus(bool connected) {
    ntpStatus = connected;
}
