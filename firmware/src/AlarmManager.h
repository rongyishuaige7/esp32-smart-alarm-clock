#ifndef ALARM_MANAGER_H
#define ALARM_MANAGER_H

#include <Preferences.h>
#include <ArduinoJson.h>
#include <vector>

struct Alarm {
    int id;
    int hour;
    int minute;
    bool enabled;
};

class AlarmManager {
public:
    AlarmManager();
    void begin();

    std::vector<Alarm> getAlarms();
    Alarm getAlarm(int id);
    int addAlarm(int hour, int minute, bool enabled);
    bool updateAlarm(int id, int hour, int minute, bool enabled);
    bool deleteAlarm(int id);
    bool setAlarmEnabled(int id, bool enabled);

    int checkAlarms();  // 返回触发的闹钟ID，-1表示无触发
    void stopAlarm();
    bool isAlarmActive();

    static bool validateHour(int h) { return h >= 0 && h <= 23; }
    static bool validateMinute(int m) { return m >= 0 && m <= 59; }

private:
    Preferences preferences;
    const char* alarmKey = "alarm_list";
    int nextId;
    int activeAlarmId;

    std::vector<Alarm> alarmCache;
    bool alarmCacheValid = false;

    void saveAlarms(const std::vector<Alarm>& alarms);
    std::vector<Alarm> loadAlarms();
};

#endif