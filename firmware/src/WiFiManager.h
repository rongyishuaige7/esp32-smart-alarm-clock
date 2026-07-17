#ifndef WIFI_MANAGER_H
#define WIFI_MANAGER_H

#include <WiFi.h>
#include <Preferences.h>

class WiFiManager {
public:
    WiFiManager();
    bool autoConnect();  // 尝试自动连接已存储的WiFi
    void setupAP();      // 创建配网热点（HTTP 在 WIFI_AP_HTTP_PORT）
    void handleAP();     // AP 模式下在主循环中调用（处理配网页）
    bool isAPMode() const;
    bool isConnected();
    String getIP();

private:
    Preferences preferences;
    const char* ssidKey = "wifi_ssid";
    const char* passKey = "wifi_pass";
    bool apMode = false;
};

#endif