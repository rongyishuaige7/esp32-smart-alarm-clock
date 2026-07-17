#ifndef MOTION_DETECTOR_H
#define MOTION_DETECTOR_H

#include <Arduino.h>

class MotionDetector {
public:
    MotionDetector();
    void begin();
    void update();  // 在loop中调用

    bool isMotionDetected();
    bool isLEDOn();
    void forceLEDOff();  // 手动关闭LED

private:
    int pirPin;
    int ledPin;
    bool ledState;
    unsigned long lastMotionMs;
    static const int MOTION_TIMEOUT_MS = 30000;  // 30秒
};

#endif
