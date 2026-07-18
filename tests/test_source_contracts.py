from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]

def read(rel: str) -> str:
    return (ROOT / rel).read_text(encoding='utf-8')

class SourceContracts(unittest.TestCase):
    def test_platform_and_gpio_contract(self):
        self.assertIn('platform = espressif32@6.13.0', read('firmware/platformio.ini'))
        constants = read('firmware/src/constants.h')
        for value in [
            '#define PIN_OLED_SDA      21', '#define PIN_OLED_SCL      22', '#define PIN_STOP_BUTTON   18',
            '#define PIN_PIR           19', '#define PIN_LED           5', '#define PIN_DHT           4',
            '#define PIN_I2S_BCLK      26', '#define PIN_I2S_WS        25', '#define PIN_I2S_DIN       33',
        ]:
            self.assertIn(value, constants)

    def test_ap_and_rest_ports_are_separated(self):
        constants = read('firmware/src/constants.h')
        wifi = read('firmware/src/WiFiManager.cpp')
        rest = read('firmware/src/WebServerManager.cpp')
        self.assertIn('#define WIFI_AP_HTTP_PORT 81', constants)
        self.assertIn('WiFi.softAP("ESP32_Alarm_Config")', wifi)
        self.assertIn('new WebServer(WIFI_AP_HTTP_PORT)', wifi)
        self.assertIn('server = new WebServer(80)', rest)
        self.assertIn('webServerManager.begin();', read('firmware/src/main.cpp'))

    def test_unknown_rest_path_is_real_404_and_cors_is_explicit(self):
        rest = read('firmware/src/WebServerManager.cpp')
        self.assertIn('server->send(404, "application/json", "{\\"success\\":false,\\"error\\":\\"Not Found\\"}")', rest)
        self.assertIn('Access-Control-Allow-Origin', rest)
        self.assertIn('Access-Control-Allow-Methods', rest)

    def test_audio_is_optional_and_no_wav_is_tracked(self):
        audio_doc = read('firmware/data/audio/README.md')
        self.assertIn('不包含**任何现成 WAV 文件', audio_doc)
        self.assertIn('alarm_ringtone.wav', audio_doc)
        self.assertIn('File not found', read('firmware/src/AudioManager.cpp'))
        self.assertEqual([], list((ROOT / 'firmware/data/audio').glob('*.wav')))

    def test_client_requires_actual_sta_address_and_parses_envelope(self):
        api = read('app/lib/services/api_service.dart')
        home = read('app/lib/pages/home_page.dart')
        self.assertIn("defaultBaseUrl = 'http://192.168.4.1'", api)
        self.assertIn("map['success'] != true", api)
        self.assertIn('requestTimeout = Duration(seconds: 10)', api)
        self.assertIn('设备实际 IP', home)
        self.assertNotIn('SYSTEM ONLINE', home.upper())

    def test_network_policy_is_declared(self):
        self.assertIn('android:usesCleartextTraffic="true"', read('app/android/app/src/main/AndroidManifest.xml'))
        self.assertIn('NSAllowsLocalNetworking', read('app/ios/Runner/Info.plist'))
        self.assertIn('没有认证、TLS', read('README.md'))

    def test_widget_test_tracks_visible_title(self):
        self.assertIn("find.text('ESP32 智能闹钟')", read('app/test/widget_test.dart'))
        self.assertIn("title: const Text('ESP32 智能闹钟')", read('app/lib/pages/home_page.dart'))

if __name__ == '__main__':
    unittest.main()
