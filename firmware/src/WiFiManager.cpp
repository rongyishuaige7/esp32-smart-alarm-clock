#include "WiFiManager.h"
#include "constants.h"
#include <WebServer.h>
#include <esp_system.h>

WebServer* g_server = nullptr;  // 全局WebServer指针（仅 AP 配网）

WiFiManager::WiFiManager() {}

bool WiFiManager::autoConnect() {
    apMode = false;
    preferences.begin("wifi", true);
    String savedSSID = preferences.getString(ssidKey, "");
    String savedPass = preferences.getString(passKey, "");
    preferences.end();

    if (savedSSID.length() == 0) {
        return false;  // 无存储的WiFi
    }

    WiFi.mode(WIFI_STA);
    WiFi.begin(savedSSID.c_str(), savedPass.c_str());

    // 等待连接，最多10秒
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 100) {
        delay(100);
        attempts++;
    }

    return WiFi.status() == WL_CONNECTED;
}

void WiFiManager::setupAP() {
    apMode = true;
    if (g_server) {
        g_server->stop();
        delete g_server;
        g_server = nullptr;
    }

    WiFi.mode(WIFI_AP);
    WiFi.softAP("ESP32_Alarm_Config");

    g_server = new WebServer(WIFI_AP_HTTP_PORT);
    g_server->on("/", HTTP_GET, []() {
        String port = String(WIFI_AP_HTTP_PORT);
        g_server->send(200, "text/html",
            "<html><head><meta charset='utf-8'><title>ESP32 WiFi</title></head><body>"
            "<h1>ESP32 Alarm Config</h1>"
            "<p>请使用端口 <strong>:" + port + "</strong> 访问本页。</p>"
            "<form method='POST' action='/save'>"
            "SSID: <input name='ssid' required><br><br>"
            "Password: <input name='pass' type='password'><br><br>"
            "<input type='submit' value='Save &amp; Reboot'>"
            "</form></body></html>");
    });
    g_server->on("/save", HTTP_POST, []() {
        if (!g_server->hasArg("ssid")) {
            g_server->send(400, "text/plain", "Missing ssid");
            return;
        }
        Preferences prefs;
        prefs.begin("wifi", false);
        prefs.putString("wifi_ssid", g_server->arg("ssid"));
        prefs.putString("wifi_pass", g_server->arg("pass"));
        prefs.end();
        g_server->send(200, "text/html",
            "<html><body><p>Saved. Rebooting...</p></body></html>");
        delay(500);
        esp_restart();
    });
    g_server->begin();
}

void WiFiManager::handleAP() {
    if (g_server) {
        g_server->handleClient();
    }
}

bool WiFiManager::isAPMode() const {
    return apMode;
}

bool WiFiManager::isConnected() {
    return WiFi.status() == WL_CONNECTED;
}

String WiFiManager::getIP() {
    return WiFi.localIP().toString();
}