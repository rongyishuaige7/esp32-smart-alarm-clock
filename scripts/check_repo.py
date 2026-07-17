#!/usr/bin/env python3
"""Repository release contracts that do not require ESP32 hardware."""
from __future__ import annotations
import argparse
import csv
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REQUIRED = [
    '.github/platformio-requirements.in', '.github/platformio-requirements.txt', '.github/workflows/validate.yml',
    '.gitignore', '.markdownlint-cli2.jsonc', 'HARDWARE.md', 'LICENSE', 'README.md', 'SECURITY.md',
    'THIRD_PARTY_NOTICES.md', 'docs/GITHUB_METADATA.md', 'docs/HARDWARE_LAB_CARD.md',
    'docs/PROJECT_STATUS.md', 'docs/PROTOCOL.md', 'docs/SOURCE_PROVENANCE.md', 'docs/VERIFICATION.md',
    'hardware/BOM.csv', 'hardware/wiring-diagram.svg', 'firmware/platformio.ini',
    'firmware/data/audio/README.md', 'scripts/check_repo.py', 'scripts/secret_scan.py', 'scripts/verify.sh',
    'tests/test_source_contracts.py', 'app/pubspec.yaml', 'app/test/widget_test.dart',
]
FORBIDDEN_NAMES = {'.env', 'local.properties', 'id_rsa', 'id_ed25519'}
FORBIDDEN_DIRS = {'.pio', '.gradle', '.dart_tool', '.idea', 'build', 'dist', 'ephemeral', '__pycache__', '.vscode'}
FORBIDDEN_SUFFIXES = {'.o', '.a', '.elf', '.bin', '.map', '.pyc', '.apk', '.aab', '.wav', '.pem', '.key', '.zip', '.7z', '.tar', '.gz'}
MAX = 5 * 1024 * 1024

def files(root: Path) -> list[Path]:
    try:
        raw = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'], check=True, capture_output=True).stdout
    except (subprocess.CalledProcessError, FileNotFoundError):
        raw = b''
    if raw:
        return [root / item.decode('utf-8', 'surrogateescape') for item in raw.split(b'\0') if item]
    return sorted(p for p in root.rglob('*') if p.is_file() and not any(x in {'.git', *FORBIDDEN_DIRS} for x in p.relative_to(root).parts))

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    root = Path(parser.parse_args().root).resolve()
    errors: list[str] = []
    for rel in REQUIRED:
        if not (root / rel).is_file():
            errors.append(f'missing required file: {rel}')
    checked = files(root)
    for path in checked:
        rel = path.relative_to(root)
        if path.name in FORBIDDEN_NAMES:
            errors.append(f'forbidden local/config file: {rel}')
        if any(part in FORBIDDEN_DIRS for part in rel.parts):
            errors.append(f'forbidden generated directory: {rel}')
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            errors.append(f'forbidden binary/archive/key/audio artifact: {rel}')
        if path.stat().st_size > MAX:
            errors.append(f'file exceeds 5 MiB: {rel}')
    contracts = {
        'README.md': [
            '当前 ESP32、OLED、DHT11、PIR、MAX98357A、实体按键及 Flutter App 的端到端链路尚未重新真机复测',
            'REST API 没有认证、TLS', '没有打包现成 TTS 或铃声音频', 'HTTP `404` JSON',
        ],
        'firmware/platformio.ini': ['platform = espressif32@6.13.0', 'board = esp32dev'],
        'firmware/src/constants.h': [
            '#define PIN_OLED_SDA      21', '#define PIN_OLED_SCL      22', '#define PIN_STOP_BUTTON   18',
            '#define PIN_PIR           19', '#define PIN_LED           5', '#define PIN_DHT           4',
            '#define PIN_I2S_BCLK      26', '#define PIN_I2S_WS        25', '#define PIN_I2S_DIN       33',
            '#define WIFI_AP_HTTP_PORT 81',
        ],
        'firmware/src/WiFiManager.cpp': ['WiFi.softAP("ESP32_Alarm_Config")', 'new WebServer(WIFI_AP_HTTP_PORT)'],
        'firmware/src/WebServerManager.cpp': ['server = new WebServer(80)', 'server->send(404, "application/json", "{\\"success\\":false,\\"error\\":\\"Not Found\\"}")', 'Access-Control-Allow-Origin'],
        'app/lib/services/api_service.dart': ["defaultBaseUrl = 'http://192.168.4.1'", 'requestTimeout = Duration(seconds: 10)', "map['success'] != true"],
        'app/android/app/src/main/AndroidManifest.xml': ['android:usesCleartextTraffic="true"'],
        'app/ios/Runner/Info.plist': ['NSAllowsLocalNetworking'],
        'firmware/data/audio/README.md': ['本公开仓库**不包含**任何现成 WAV 文件', 'alarm_ringtone.wav'],
        'docs/SOURCE_PROVENANCE.md': ['e8a457031cd3f194ca18dd096aaff433998a27765432da440650efec709b391b', 'cea0eb2af1cfbd90ee15f1a901f1246faee4519b6822fa624c394ea34c67e6bb'],
    }
    for rel, values in contracts.items():
        path = root / rel
        if not path.is_file():
            continue
        text = path.read_text(encoding='utf-8')
        for value in values:
            if value not in text:
                errors.append(f'fact contract missing in {rel}: {value}')
    try:
        ET.parse(root / 'hardware/wiring-diagram.svg')
    except (ET.ParseError, OSError) as exc:
        errors.append(f'invalid wiring SVG: {exc}')
    try:
        rows = list(csv.DictReader((root / 'hardware/BOM.csv').open(newline='', encoding='utf-8')))
        if len(rows) < 8:
            errors.append('BOM must contain at least 8 component rows')
    except (OSError, csv.Error) as exc:
        errors.append(f'invalid BOM.csv: {exc}')
    for rel in ['README.md', 'docs/PROJECT_STATUS.md', 'docs/HARDWARE_LAB_CARD.md']:
        path = root / rel
        text = path.read_text(encoding='utf-8').lower() if path.is_file() else ''
        for claim in ['system online', 'current hardware verified', 'hardware re-verified: pass', 'production ready']:
            if claim in text:
                errors.append(f'unsupported claim in {rel}: {claim}')
    if errors:
        print('Repository check: FAIL', file=sys.stderr)
        for item in sorted(set(errors)):
            print(f'- {item}', file=sys.stderr)
        return 1
    print(f'Repository check: PASS ({len(checked)} files checked)')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
