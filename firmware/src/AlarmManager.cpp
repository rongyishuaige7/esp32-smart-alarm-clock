#include "AlarmManager.h"
#include <ArduinoJson.h>
#include "TimeManager.h"

// 在AlarmManager.cpp中定义，由main.cpp设置
TimeManager* g_timeManager = nullptr;

AlarmManager::AlarmManager() : nextId(1), activeAlarmId(-1) {}

void AlarmManager::begin() {
    alarmCacheValid = false;
    preferences.begin("alarms", true);   // 只读模式读取 next_id
    nextId = preferences.getInt("next_id", 1);
    preferences.end();
}

std::vector<Alarm> AlarmManager::loadAlarms() {
    if (alarmCacheValid) {
        return alarmCache;
    }

    preferences.begin("alarms", true);
    String jsonStr = preferences.getString(alarmKey, "[]");
    preferences.end();

    std::vector<Alarm> alarms;
    DynamicJsonDocument doc(2048);
    DeserializationError error = deserializeJson(doc, jsonStr);
    if (!error) {
        JsonArray arr = doc.as<JsonArray>();
        for (JsonObject obj : arr) {
            Alarm a;
            a.id = obj["id"];
            a.hour = obj["hour"];
            a.minute = obj["minute"];
            a.enabled = obj["enabled"];
            alarms.push_back(a);
        }
    }
    alarmCache = std::move(alarms);
    alarmCacheValid = true;
    return alarmCache;
}

void AlarmManager::saveAlarms(const std::vector<Alarm>& alarms) {
    DynamicJsonDocument doc(2048);
    JsonArray arr = doc.to<JsonArray>();
    for (const auto& a : alarms) {
        JsonObject obj = arr.createNestedObject();
        obj["id"] = a.id;
        obj["hour"] = a.hour;
        obj["minute"] = a.minute;
        obj["enabled"] = a.enabled;
    }
    String output;
    serializeJson(doc, output);

    preferences.begin("alarms", false);
    preferences.putString(alarmKey, output.c_str());
    preferences.putInt("next_id", nextId);  // 一并写入，避免多次开关命名空间
    preferences.end();

    alarmCache = alarms;
    alarmCacheValid = true;
}

std::vector<Alarm> AlarmManager::getAlarms() {
    return loadAlarms();
}

Alarm AlarmManager::getAlarm(int id) {
    auto alarms = loadAlarms();
    for (const auto& a : alarms) {
        if (a.id == id) return a;
    }
    return {-1, 0, 0, false};
}

int AlarmManager::addAlarm(int hour, int minute, bool enabled) {
    if (!validateHour(hour) || !validateMinute(minute)) {
        return -1;
    }

    auto alarms = loadAlarms();
    Alarm newAlarm = {nextId++, hour, minute, enabled};
    alarms.push_back(newAlarm);
    saveAlarms(alarms);  // next_id 已在 saveAlarms 内一并写入

    return newAlarm.id;
}

bool AlarmManager::updateAlarm(int id, int hour, int minute, bool enabled) {
    if (!validateHour(hour) || !validateMinute(minute)) {
        return false;
    }

    auto alarms = loadAlarms();
    for (auto& a : alarms) {
        if (a.id == id) {
            a.hour = hour;
            a.minute = minute;
            a.enabled = enabled;
            saveAlarms(alarms);
            return true;
        }
    }
    return false;
}

bool AlarmManager::deleteAlarm(int id) {
    auto alarms = loadAlarms();
    auto it = std::remove_if(alarms.begin(), alarms.end(),
        [id](const Alarm& a) { return a.id == id; });

    if (it != alarms.end()) {
        alarms.erase(it, alarms.end());
        saveAlarms(alarms);
        return true;
    }
    return false;
}

bool AlarmManager::setAlarmEnabled(int id, bool enabled) {
    auto alarms = loadAlarms();
    for (auto& a : alarms) {
        if (a.id == id) {
            a.enabled = enabled;
            saveAlarms(alarms);
            return true;
        }
    }
    return false;
}

int AlarmManager::checkAlarms() {
    if (activeAlarmId != -1) {
        return activeAlarmId;  // 已有活跃闹钟
    }
    if (g_timeManager == nullptr) {
        return -1;
    }

    auto alarms = loadAlarms();
    int currentHour = g_timeManager->getHour();
    int currentMinute = g_timeManager->getMinute();
    int currentSecond = g_timeManager->getSecond();

    // 只在整点或整分的第一秒检测
    if (currentSecond != 0) return -1;

    for (const auto& a : alarms) {
        if (a.enabled && a.hour == currentHour && a.minute == currentMinute) {
            activeAlarmId = a.id;
            return a.id;
        }
    }

    return -1;
}

void AlarmManager::stopAlarm() {
    activeAlarmId = -1;
}

bool AlarmManager::isAlarmActive() {
    return activeAlarmId != -1;
}
