#ifndef DISPLAY_MANAGER_H
#define DISPLAY_MANAGER_H

#include <Adafruit_SSD1306.h>
#include <Wire.h>

class DisplayManager {
public:
    DisplayManager();
    void begin();
    void clear();
    void update();  // 由loop调用刷新

    void showTime(const String& timeStr);
    void showDate(const String& dateStr);
    void showStatus(const String& status);  // 温湿度、闹钟状态
    void showAlarm(bool isActive);
    void showNTPStatus(bool connected);

private:
    Adafruit_SSD1306* display;
    bool ntpStatus;
    bool alarmActive;
    String currentTime;
    String currentDate;
    String statusLine;
};

#endif
