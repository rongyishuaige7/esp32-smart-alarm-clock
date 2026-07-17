#ifndef AUDIO_MANAGER_H
#define AUDIO_MANAGER_H

#include <driver/i2s.h>
#include <freertos/FreeRTOS.h>
#include <freertos/task.h>
#include <FS.h>
#include <SPIFFS.h>

class AudioManager {
public:
    AudioManager();
    void begin();

    void playTTS(const String& text);
    void playRingtone();
    void playFile(const String& path);

    /// 在独立 FreeRTOS 任务中播放闹钟序列（立即返回，不阻塞 loop）
    void playAlarmSequence();

    /// 停止播放（可在 loop 或 ISR 中安全调用）
    void stop();
    bool isPlaying();

private:
    i2s_port_t i2sPort;
    volatile bool playing;

    TaskHandle_t _taskHandle = nullptr;

    bool playWavFile(const String& path);
    void playFragment(const String& filename);

    static void alarmTask(void* param);
};

#endif
