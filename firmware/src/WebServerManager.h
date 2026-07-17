#ifndef WEB_SERVER_MANAGER_H
#define WEB_SERVER_MANAGER_H

#include <WebServer.h>
#include <ArduinoJson.h>

class WebServerManager {
public:
    WebServerManager();
    void begin();
    void handle();

private:
    WebServer* server = nullptr;

    // 响应格式(统一 envelope)
    void sendResponse(bool success, JsonVariant data, const String& error = "");
    void handleGetAlarms();
    void handlePostAlarms();
    void handleDeleteAlarm();
    void handleUpdateAlarm();
    void handleStopAlarm();
    void handleGetStatus();
    void handleGetTime();
};

#endif
