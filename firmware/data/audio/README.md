# 本地音频素材说明

本公开仓库**不包含**任何现成 WAV 文件。原始项目中的 TTS 和铃声文件无法在公开前确认逐个来源与再分发许可，因此没有随 MIT 源码分发。

## 可自行准备的文件

如需在自己的硬件上启用声音，请只放入你拥有再分发权的音频，并将它们放到本目录。固件按以下文件名读取：

```text
0.wav 1.wav 2.wav 3.wav 4.wav 5.wav 6.wav 7.wav 8.wav 9.wav
shi.wav
fen.wav
gai_qc_le.wav
alarm_ringtone.wav
```

格式要求：PCM WAV、16-bit；推荐 16 kHz 单声道。固件也接受 8–48 kHz 的 16-bit 单/双声道 PCM WAV。上传文件系统镜像前请自行核对 Flash 分区容量与素材许可。

```bash
pio run -t uploadfs
```

缺少音频文件时，固件会在串口输出 `File not found`，闹钟的声音播放不会完成；这不是硬件已坏或网络状态的判断。

不要上传来源不明的第三方 TTS、铃声、音乐或平台导出音频。
