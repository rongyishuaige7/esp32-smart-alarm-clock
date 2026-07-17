#include "TimeManager.h"
#include "constants.h"
#include <WiFi.h>

TimeManager::TimeManager() : ntpConnected(false), lastSyncMs(0) {}

bool TimeManager::syncFromNTP() {
    if (!WiFi.isConnected()) {
        return false;
    }

    configTime(NTP_TIMEZONE * 3600, 0, NTP_SERVER);

    int retry = 0;
    while (retry < MAX_RETRY) {
        time_t now = time(nullptr);
        if (now > 1000000000) {  // 合理时间戳检查
            ntpConnected = true;
            lastSyncMs = millis();
            return true;
        }
        delay(1000);
        retry++;
    }

    return false;
}

void TimeManager::forceSync() {
    ntpConnected = false;
    syncFromNTP();
}

bool TimeManager::update() {
    if (!ntpConnected) {
        return false;
    }

    // 每小时重新同步
    if (millis() - lastSyncMs > NTP_SYNC_INTERVAL * 1000) {
        syncFromNTP();
    }

    return true;
}

int TimeManager::getHour() {
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    return t->tm_hour;
}

int TimeManager::getMinute() {
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    return t->tm_min;
}

int TimeManager::getSecond() {
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    return t->tm_sec;
}

String TimeManager::getDateString() {
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    char buf[16];  // 增大缓冲区
    strftime(buf, sizeof(buf), "%Y-%m-%d", t);
    return String(buf);
}

String TimeManager::getTimeString() {
    time_t now = time(nullptr);
    struct tm* t = localtime(&now);
    char buf[16];  // 增大缓冲区
    strftime(buf, sizeof(buf), "%H:%M:%S", t);
    return String(buf);
}

bool TimeManager::isNTPConnected() {
    return ntpConnected;
}