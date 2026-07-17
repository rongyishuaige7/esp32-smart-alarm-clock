#include "AudioManager.h"
#include "constants.h"
#include <cstring>

namespace {

struct WavInfo {
    bool valid = false;
    uint32_t sampleRate = I2S_SAMPLE_RATE;
    uint16_t numChannels = 1;
    uint16_t bitsPerSample = 16;
};

bool readU32LE(File& f, uint32_t& out) {
    uint8_t b[4];
    if (f.read(b, 4) != 4) {
        return false;
    }
    out = (uint32_t)b[0] | ((uint32_t)b[1] << 8) | ((uint32_t)b[2] << 16) | ((uint32_t)b[3] << 24);
    return true;
}

bool readU16LE(File& f, uint16_t& out) {
    uint8_t b[2];
    if (f.read(b, 2) != 2) {
        return false;
    }
    out = (uint16_t)b[0] | ((uint16_t)b[1] << 8);
    return true;
}

/// SPIFFS 上 file.seek() 后 available() 不可靠；统一用顺序 read 跳字节
static bool skipBytes(File& file, uint32_t n) {
    uint8_t buf[32];
    while (n > 0) {
        uint32_t step = (n < sizeof(buf)) ? n : sizeof(buf);
        if (file.read(buf, step) != step) {
            return false;
        }
        n -= step;
    }
    return true;
}

bool parseWavHeader(File& file, WavInfo& info) {
    char riff[4];
    if (file.read((uint8_t*)riff, 4) != 4 || memcmp(riff, "RIFF", 4) != 0) {
        return false;
    }
    uint32_t riffSize = 0;
    if (!readU32LE(file, riffSize)) {
        return false;
    }
    char wave[4];
    if (file.read((uint8_t*)wave, 4) != 4 || memcmp(wave, "WAVE", 4) != 0) {
        return false;
    }

    bool haveFmt = false;

    // 最多扫描 16 个 chunk，防止无限循环
    for (int chunkCount = 0; chunkCount < 16; chunkCount++) {
        char chunkId[4];
        if (file.read((uint8_t*)chunkId, 4) != 4) {
            break;
        }
        uint32_t chunkSize = 0;
        if (!readU32LE(file, chunkSize)) {
            break;
        }
        // chunkSize 超过 4MB 很可能是数据损坏
        if (chunkSize > 4 * 1024 * 1024UL) {
            break;
        }

        if (memcmp(chunkId, "fmt ", 4) == 0) {
            if (chunkSize < 16) {
                return false;
            }
            uint16_t audioFormat = 0;
            uint16_t numChannels = 0;
            uint32_t sampleRate = 0;
            uint32_t byteRate = 0;
            uint16_t blockAlign = 0;
            uint16_t bitsPerSample = 0;
            if (!readU16LE(file, audioFormat)) {
                return false;
            }
            if (!readU16LE(file, numChannels)) {
                return false;
            }
            if (!readU32LE(file, sampleRate)) {
                return false;
            }
            if (!readU32LE(file, byteRate)) {
                return false;
            }
            if (!readU16LE(file, blockAlign)) {
                return false;
            }
            if (!readU16LE(file, bitsPerSample)) {
                return false;
            }
            if (audioFormat != 1) {
                Serial.println("WAV: only PCM supported");
                return false;
            }
            info.numChannels = numChannels;
            info.sampleRate = sampleRate;
            info.bitsPerSample = bitsPerSample;
            haveFmt = true;
            // 跳过 fmt 剩余字节（如 cbSize 扩展），用顺序 read 而非 seek
            uint32_t readSoFar = 16;
            if (chunkSize > readSoFar) {
                if (!skipBytes(file, chunkSize - readSoFar)) {
                    return false;
                }
            }
            // WAV chunk 对齐到偶数字节
            if (chunkSize & 1) {
                if (!skipBytes(file, 1)) {
                    return false;
                }
            }
        } else if (memcmp(chunkId, "data", 4) == 0) {
            if (!haveFmt) {
                return false;
            }
            // 文件指针现在正好在 PCM 数据起点，直接返回
            info.valid = true;
            return true;
        } else {
            // 未知 chunk：顺序跳过（含奇数对齐字节）
            uint32_t toSkip = chunkSize + (chunkSize & 1 ? 1 : 0);
            if (toSkip > 0 && !skipBytes(file, toSkip)) {
                return false;
            }
        }
    }

    return false;
}

}  // namespace

AudioManager::AudioManager() : playing(false), i2sPort(I2S_NUM_0) {}

void AudioManager::begin() {
    if (!SPIFFS.begin(true)) {
        Serial.println("SPIFFS mount failed");
    }

    i2s_config_t i2s_config = {
        .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_TX),
        .sample_rate = I2S_SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_RIGHT_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 8,
        .dma_buf_len = 256,
        .use_apll = false,
    };

    i2s_pin_config_t pin_config = {
        .bck_io_num = PIN_I2S_BCLK,
        .ws_io_num = PIN_I2S_WS,
        .data_out_num = PIN_I2S_DIN,
        .data_in_num = I2S_PIN_NO_CHANGE,
    };

    esp_err_t err = i2s_driver_install(i2sPort, &i2s_config, 0, NULL);
    if (err != ESP_OK) {
        Serial.printf("i2s_driver_install failed: %d\n", (int)err);
        return;
    }
    i2s_set_pin(i2sPort, &pin_config);
    i2s_set_clk(i2sPort, I2S_SAMPLE_RATE, I2S_BITS_PER_SAMPLE_16BIT, I2S_CHANNEL_STEREO);
}

bool AudioManager::playWavFile(const String& path) {
    File file = SPIFFS.open(path, "r");
    if (!file) {
        Serial.printf("[Audio] File not found: %s\n", path.c_str());
        return false;
    }
    Serial.printf("[Audio] Playing: %s (%u bytes)\n", path.c_str(), (unsigned)file.size());

    WavInfo wav;
    if (!parseWavHeader(file, wav)) {
        Serial.printf("[Audio] Invalid WAV: %s  pos_after_parse=%u\n",
                      path.c_str(), (unsigned)file.position());
        file.close();
        return false;
    }
    Serial.printf("[Audio] WAV ok: ch=%u sr=%lu bits=%u  data_pos=%u\n",
                  wav.numChannels, (unsigned long)wav.sampleRate,
                  wav.bitsPerSample, (unsigned)file.position());

    if (wav.bitsPerSample != 16) {
        Serial.println("WAV: only 16-bit PCM supported");
        file.close();
        return false;
    }

    if (wav.sampleRate < 8000 || wav.sampleRate > 48000) {
        Serial.println("WAV: sample rate out of range");
        file.close();
        return false;
    }

    i2s_set_clk(i2sPort, wav.sampleRate, I2S_BITS_PER_SAMPLE_16BIT, I2S_CHANNEL_STEREO);

    const size_t rawCap = 512;
    uint8_t raw[rawCap];
    size_t bytesRead = 0;

    // rawCap = 512 字节 = 256 单声道采样；转立体声后 = 512 采样 * 2 字节 = 1024 字节
    // stereo 数组必须能容纳 256 * 2 个 int16_t
    // i2s_write 超时设为 50ms，使 playing=false 后最多延迟一个缓冲区时间即可退出
    const TickType_t i2sTimeout = pdMS_TO_TICKS(50);

    if (wav.numChannels == 1) {
        while (playing && (bytesRead = file.read(raw, rawCap)) > 0) {
            size_t numSamples = bytesRead / 2;
            int16_t stereo[512];
            size_t stereoBytes = numSamples * 4;
            int16_t* mono = reinterpret_cast<int16_t*>(raw);
            for (size_t i = 0; i < numSamples; i++) {
                int16_t s = mono[i];
                stereo[i * 2] = s;
                stereo[i * 2 + 1] = s;
            }
            size_t written = 0;
            i2s_write(i2sPort, (const char*)stereo, stereoBytes, &written, i2sTimeout);
        }
    } else if (wav.numChannels == 2) {
        while (playing && (bytesRead = file.read(raw, rawCap)) > 0) {
            size_t written = 0;
            i2s_write(i2sPort, (const char*)raw, bytesRead, &written, i2sTimeout);
        }
    } else {
        Serial.println("WAV: unsupported channel count");
        file.close();
        return false;
    }

    file.close();
    return true;
}

void AudioManager::playFragment(const String& filename) {
    String path = "/audio/" + filename;
    playWavFile(path);
}

void AudioManager::playFile(const String& path) {
    playWavFile(path);
}

void AudioManager::playTTS(const String& text) {
    if (!playing) {
        return;
    }
    if (text.length() == 0) {
        playFragment("gai_qc_le.wav");
        return;
    }

    bool onlyDigitsAndSpace = true;
    for (unsigned i = 0; i < text.length(); i++) {
        char c = text[i];
        if (c >= '0' && c <= '9') {
            continue;
        }
        if (c == ' ' || c == '\t' || c == '\n' || c == '\r') {
            continue;
        }
        onlyDigitsAndSpace = false;
        break;
    }

    if (onlyDigitsAndSpace) {
        for (unsigned i = 0; i < text.length(); i++) {
            if (!playing) {
                break;
            }
            char c = text[i];
            if (c >= '0' && c <= '9') {
                playFragment(String(c) + ".wav");
            }
        }
    } else {
        playFragment("gai_qc_le.wav");
    }
}

void AudioManager::playRingtone() {
    for (int i = 0; i < 11 && playing; i++) {
        playFragment("alarm_ringtone.wav");
        if (!playing) {
            break;
        }
        delay(100);
    }
}

// ---- FreeRTOS 闹钟任务 ----
void AudioManager::alarmTask(void* param) {
    AudioManager* self = static_cast<AudioManager*>(param);

    self->playTTS("该起床了");
    if (self->playing) {
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
    self->playRingtone();

    // 正常播完或被 stop() 中断后，清空 DMA 残留，避免最后几毫秒杂音
    i2s_zero_dma_buffer(self->i2sPort);
    self->playing = false;
    self->_taskHandle = nullptr;
    vTaskDelete(nullptr);
}

void AudioManager::playAlarmSequence() {
    if (playing) {
        return;  // 已在播放，不重复启动
    }
    playing = true;
    // 栈 4096 字节，优先级 1（低于 WiFi/TCP 任务），固定到 APP_CPU（核 1）
    xTaskCreatePinnedToCore(
        alarmTask,
        "alarmSeq",
        4096,
        this,
        1,
        &_taskHandle,
        1
    );
}

void AudioManager::stop() {
    playing = false;

    // 等待 alarmTask 退出（它检查 playing 标志，i2s_write 超时 50ms 后会退出循环）
    // 最多等 200ms，避免在 loop() 或 HTTP handler 里长时间阻塞
    for (int i = 0; i < 20 && _taskHandle != nullptr; i++) {
        vTaskDelay(pdMS_TO_TICKS(10));
    }

    // 任务已退出（或超时），清空 DMA 缓冲区以消除残留噪声
    i2s_zero_dma_buffer(i2sPort);
}

bool AudioManager::isPlaying() {
    return playing;
}
