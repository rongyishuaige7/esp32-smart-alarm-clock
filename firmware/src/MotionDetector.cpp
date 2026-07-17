#include "MotionDetector.h"
#include "constants.h"

#if LED_RGB_COMMON_ANODE
static constexpr uint8_t LED_ON = LOW;
static constexpr uint8_t LED_OFF = HIGH;
#else
static constexpr uint8_t LED_ON = HIGH;
static constexpr uint8_t LED_OFF = LOW;
#endif

MotionDetector::MotionDetector() : ledState(false), lastMotionMs(0) {}

void MotionDetector::begin() {
    pinMode(PIN_PIR, INPUT);
    pinMode(PIN_LED, OUTPUT);
    digitalWrite(PIN_LED, LED_OFF);
}

void MotionDetector::update() {
    bool motion = digitalRead(PIN_PIR) == HIGH;

    if (motion) {
        lastMotionMs = millis();
        if (!ledState) {
            ledState = true;
            digitalWrite(PIN_LED, LED_ON);
        }
    } else if (ledState && (millis() - lastMotionMs > MOTION_TIMEOUT_MS)) {
        ledState = false;
        digitalWrite(PIN_LED, LED_OFF);
    }
}

bool MotionDetector::isMotionDetected() {
    return ledState;  // 有人触发后 30 秒内持续为 true，与 LED 逻辑一致
}

bool MotionDetector::isLEDOn() {
    return ledState;
}

void MotionDetector::forceLEDOff() {
    ledState = false;
    digitalWrite(PIN_LED, LED_OFF);
}
