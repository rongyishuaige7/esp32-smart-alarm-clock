#ifndef DHT_MANAGER_H
#define DHT_MANAGER_H

#include <DHT.h>

class DHTManager {
public:
    DHTManager();
    void begin();
    void update();  // 每30秒调用一次

    float getTemperature();
    float getHumidity();
    bool hasReadings();

private:
    DHT* dht;
    float temperature;
    float humidity;
    bool valid;
    unsigned long lastReadMs;
    static const int READ_INTERVAL = 30000;  // 30秒
};

#endif
