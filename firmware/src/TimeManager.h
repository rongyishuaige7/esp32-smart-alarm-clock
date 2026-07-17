#ifndef TIME_MANAGER_H
#define TIME_MANAGER_H

#include <Arduino.h>
#include <time.h>
#include <sys/time.h>

class TimeManager {
public:
    TimeManager();
    bool syncFromNTP();           // NTP同步
    void forceSync();             // 强制同步
    bool update();                // 更新内部时间

    int getHour();
    int getMinute();
    int getSecond();
    String getDateString();       // "YYYY-MM-DD"
    String getTimeString();       // "HH:MM:SS"

    bool isNTPConnected();

private:
    bool ntpConnected;
    unsigned long lastSyncMs;
    static const int NTP_TIMEOUT = 10000;  // 10秒超时
    static const int MAX_RETRY = 3;       // 最多重试3次
};

#endif