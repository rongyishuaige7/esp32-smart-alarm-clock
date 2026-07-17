#include "WebServerManager.h"
#include <cstring>
#include "AlarmManager.h"
#include "DHTManager.h"
#include "MotionDetector.h"
#include "AudioManager.h"
#include "TimeManager.h"

extern AlarmManager* g_alarmManager;
extern DHTManager* g_dhtManager;
extern MotionDetector* g_motionDetector;
extern AudioManager* g_audioManager;

extern TimeManager* g_timeManager;

WebServerManager::WebServerManager() : server(nullptr) {}

void WebServerManager::begin() {
    server = new WebServer(80);

    server->on("/alarms", HTTP_GET, [this]() { handleGetAlarms(); });
    server->on("/alarms", HTTP_POST, [this]() { handlePostAlarms(); });
    server->on("/alarm/stop", HTTP_POST, [this]() { handleStopAlarm(); });
    server->on("/status", HTTP_GET, [this]() { handleGetStatus(); });
    server->on("/time", HTTP_GET, [this]() { handleGetTime(); });

    server->onNotFound([this]() {
        if (server->method() == HTTP_OPTIONS) {
            server->sendHeader("Access-Control-Allow-Origin", "*");
            server->sendHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS");
            server->sendHeader("Access-Control-Allow-Headers", "Content-Type");
            server->send(204);
            return;
        }

        String uri = server->uri();
        if (uri.startsWith("/alarms/")) {
            if (server->method() == HTTP_DELETE) {
                handleDeleteAlarm();
                return;
            }
            if (server->method() == HTTP_PUT) {
                handleUpdateAlarm();
                return;
            }
        }

        server->sendHeader("Access-Control-Allow-Origin", "*");
        server->send(404, "application/json", "{\"success\":false,\"error\":\"Not Found\"}");
    });

    server->begin();
}

void WebServerManager::handle() {
    if (server) {
        server->handleClient();
    }
}

void WebServerManager::sendResponse(bool success, JsonVariant data, const String& error) {
    DynamicJsonDocument doc(2048);
    doc["success"] = success;
    doc["error"] = error;

    if (data.is<JsonObject>()) {
        doc["data"] = data.as<JsonObject>();
    } else if (data.is<JsonArray>()) {
        doc["data"] = data.as<JsonArray>();
    } else if (!data.isNull()) {
        doc["data"] = data;
    }

    String response;
    serializeJson(doc, response);

    server->sendHeader("Access-Control-Allow-Origin", "*");
    server->send(200, "application/json", response);
}

void WebServerManager::handleGetAlarms() {
    auto alarms = g_alarmManager->getAlarms();
    DynamicJsonDocument doc(2048);
    doc["success"] = true;
    doc["error"] = "";
    JsonArray arr = doc.createNestedArray("data");
    for (const auto& a : alarms) {
        JsonObject obj = arr.createNestedObject();
        obj["id"] = a.id;
        obj["hour"] = a.hour;
        obj["minute"] = a.minute;
        obj["enabled"] = a.enabled;
    }
    String response;
    serializeJson(doc, response);
    server->sendHeader("Access-Control-Allow-Origin", "*");
    server->send(200, "application/json", response);
}

void WebServerManager::handlePostAlarms() {
    if (!server->hasArg("plain")) {
        sendResponse(false, JsonVariant(), "No body");
        return;
    }

    DynamicJsonDocument doc(256);
    DeserializationError err = deserializeJson(doc, server->arg("plain"));
    if (err) {
        sendResponse(false, JsonVariant(), String("JSON parse error: ") + err.c_str());
        return;
    }

    int hour = doc["hour"] | -1;
    int minute = doc["minute"] | -1;
    bool enabled = doc["enabled"] | true;

    if (!AlarmManager::validateHour(hour) || !AlarmManager::validateMinute(minute)) {
        sendResponse(false, JsonVariant(), "Invalid hour/minute");
        return;
    }

    int id = g_alarmManager->addAlarm(hour, minute, enabled);
    if (id == -1) {
        sendResponse(false, JsonVariant(), "Failed to add alarm");
    } else {
        DynamicJsonDocument respDoc(256);
        JsonObject obj = respDoc.to<JsonObject>();
        obj["id"] = id;
        obj["hour"] = hour;
        obj["minute"] = minute;
        obj["enabled"] = enabled;
        sendResponse(true, obj);
    }
}

void WebServerManager::handleDeleteAlarm() {
    String uri = server->uri();
    const char* prefix = "/alarms/";
    if (!uri.startsWith(prefix)) {
        sendResponse(false, JsonVariant(), "Invalid path");
        return;
    }

    String idStr = uri.substring(strlen(prefix));
    if (idStr.length() == 0) {
        sendResponse(false, JsonVariant(), "Missing alarm id");
        return;
    }

    int id = idStr.toInt();

    if (g_alarmManager->deleteAlarm(id)) {
        sendResponse(true, JsonVariant());
    } else {
        sendResponse(false, JsonVariant(), "Alarm not found");
    }
}

void WebServerManager::handleUpdateAlarm() {
    String uri = server->uri();
    const char* prefix = "/alarms/";
    if (!uri.startsWith(prefix)) {
        sendResponse(false, JsonVariant(), "Invalid path");
        return;
    }

    String idStr = uri.substring(strlen(prefix));
    if (idStr.length() == 0) {
        sendResponse(false, JsonVariant(), "Missing alarm id");
        return;
    }

    int id = idStr.toInt();

    if (!server->hasArg("plain")) {
        sendResponse(false, JsonVariant(), "No body");
        return;
    }

    DynamicJsonDocument doc(256);
    DeserializationError err = deserializeJson(doc, server->arg("plain"));
    if (err) {
        sendResponse(false, JsonVariant(), String("JSON parse error: ") + err.c_str());
        return;
    }

    int hour = doc["hour"] | -1;
    int minute = doc["minute"] | -1;
    bool enabled = doc["enabled"] | true;

    if (!AlarmManager::validateHour(hour) || !AlarmManager::validateMinute(minute)) {
        sendResponse(false, JsonVariant(), "Invalid hour/minute");
        return;
    }

    if (g_alarmManager->updateAlarm(id, hour, minute, enabled)) {
        DynamicJsonDocument respDoc(256);
        JsonObject obj = respDoc.to<JsonObject>();
        obj["id"] = id;
        obj["hour"] = hour;
        obj["minute"] = minute;
        obj["enabled"] = enabled;
        sendResponse(true, obj);
    } else {
        sendResponse(false, JsonVariant(), "Alarm not found");
    }
}

void WebServerManager::handleStopAlarm() {
    g_alarmManager->stopAlarm();
    g_audioManager->stop();
    sendResponse(true, JsonVariant());
}

void WebServerManager::handleGetStatus() {
    DynamicJsonDocument doc(256);
    JsonObject obj = doc.to<JsonObject>();
    obj["temp"] = g_dhtManager->getTemperature();
    obj["humidity"] = g_dhtManager->getHumidity();
    obj["motion"] = g_motionDetector->isMotionDetected();
    obj["alarm_active"] = g_alarmManager->isAlarmActive();

    sendResponse(true, obj);
}

void WebServerManager::handleGetTime() {
    DynamicJsonDocument doc(256);
    JsonObject obj = doc.to<JsonObject>();
    obj["hour"] = g_timeManager->getHour();
    obj["minute"] = g_timeManager->getMinute();
    obj["second"] = g_timeManager->getSecond();
    obj["date"] = g_timeManager->getDateString();
    sendResponse(true, obj);
}
