#include "DHTManager.h"
#include "constants.h"

DHTManager::DHTManager() : valid(false), lastReadMs(0) {
    temperature = 0;
    humidity = 0;
}

void DHTManager::begin() {
    dht = new DHT(PIN_DHT, DHT_TYPE);
    dht->begin();
    // DHT11 上电后需约 1–2s 才能稳定；两次读取至少间隔约 2s（库内处理，本模块 30s 轮询）
    delay(2000);
    update();  // 首次读取（见 update 中 lastReadMs==0 立即采样）
}

void DHTManager::update() {
    unsigned long now = millis();
    // lastReadMs==0 表示尚未成功安排过一次采样周期，应立刻读，不能等 30s
    if (lastReadMs != 0 && (now - lastReadMs < READ_INTERVAL)) {
        return;
    }

    float t = NAN;
    float h = NAN;
    // DHT 单总线对时序敏感，失败时重试几次（常见于上电初期或 WiFi 刚启动）
    for (int attempt = 0; attempt < 3; attempt++) {
        h = dht->readHumidity();
        t = dht->readTemperature();
        if (!isnan(t) && !isnan(h)) {
            break;
        }
        delay(250);
    }

    if (!isnan(t) && !isnan(h)) {
        temperature = t;
        humidity = h;
        valid = true;
    } else {
        Serial.println("[DHT11] read failed (check DATA=GPIO4, 3.3V, GND, 4.7k–10k pull-up on DATA)");
    }

    lastReadMs = now;
}

float DHTManager::getTemperature() {
    return temperature;
}

float DHTManager::getHumidity() {
    return humidity;
}

bool DHTManager::hasReadings() {
    return valid;
}
