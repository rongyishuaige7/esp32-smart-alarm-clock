#!/usr/bin/env python3
"""Scan the public candidate for credentials, local state, and unreviewed assets."""
from __future__ import annotations
import argparse
import re
import subprocess
import sys
from pathlib import Path

SKIP_DIRS = {'.git', '.pio', '.dart_tool', '.gradle', '.idea', 'build', 'dist', '__pycache__', 'ephemeral'}
TEXT_SUFFIXES = {'', '.c', '.cc', '.cpp', '.h', '.hpp', '.ini', '.md', '.py', '.txt', '.yml', '.yaml', '.json', '.csv', '.html', '.xml', '.plist', '.dart', '.gradle', '.kts', '.sh', '.svg'}
FORBIDDEN_SUFFIXES = {'.wav', '.apk', '.aab', '.bin', '.elf', '.map', '.o', '.a', '.pem', '.key', '.p12', '.jks'}
FORBIDDEN_NAMES = {'.env', 'local.properties', 'id_rsa', 'id_ed25519', '.flutter-plugins-dependencies'}
PATTERNS = [
    ('private key', re.compile(r'-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----')),
    ('GitHub token', re.compile(r'\b(?:gh[opusr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})\b')),
    ('AWS access key', re.compile(r'\bAKIA[0-9A-Z]{16}\b')),
    ('generic assigned secret', re.compile(r'''(?ix)\b(api[_-]?key|access[_-]?token|auth[_-]?token|secret|password|passwd|pwd)\b\s*[:=]\s*["']?(?!YOUR_|EXAMPLE|REPLACE|CHANGEME|REDACTED|\[REDACTED\])([A-Za-z0-9+/=_!@#$%^&*.-]{8,})''')),
    ('local absolute path', re.compile(r'/(?:home|Users|mnt)/[^\s`"\']+')),
]
# These exact lines are provenance evidence or source-level teaching boundary, not user credentials.
ALLOWED_EXACT_LINES = {
    ('docs/SOURCE_PROVENANCE.md', '/home/rongyi/桌面/esp32_alarm_clock'),
    ('docs/SOURCE_PROVENANCE.md', '/mnt/shared/2026项目/esp32_alarm_clock.zip'),
    ('docs/SOURCE_PROVENANCE.md', '/home/rongyi/桌面/esp32-smart-alarm-clock'),
}

def tracked_files(root: Path) -> list[Path]:
    try:
        raw = subprocess.run(['git', '-C', str(root), 'ls-files', '-z'], check=True, capture_output=True).stdout
    except (FileNotFoundError, subprocess.CalledProcessError):
        raw = b''
    if raw:
        return [root / part.decode('utf-8', 'surrogateescape') for part in raw.split(b'\0') if part]
    return sorted(p for p in root.rglob('*') if p.is_file() and not any(x in SKIP_DIRS for x in p.relative_to(root).parts))

def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', default='.')
    root = Path(parser.parse_args().root).resolve()
    errors: list[str] = []
    self_path = Path(__file__).resolve()
    for path in tracked_files(root):
        rel = path.relative_to(root)
        # The scanner's own exact-line allowlist contains audit paths; scan all
        # repository content, but do not report the implementation literals.
        if path.resolve() == self_path:
            continue
        if path.name in FORBIDDEN_NAMES:
            errors.append(f'{rel}: forbidden local/config file')
        if any(part in SKIP_DIRS for part in rel.parts):
            errors.append(f'{rel}: forbidden generated directory')
        if path.suffix.lower() in FORBIDDEN_SUFFIXES:
            errors.append(f'{rel}: forbidden binary or unreviewed audio asset')
        if path.stat().st_size > 5 * 1024 * 1024:
            errors.append(f'{rel}: file exceeds 5 MiB')
        if path.suffix.lower() not in TEXT_SUFFIXES or path.stat().st_size > 2_000_000:
            continue
        try:
            text = path.read_text(encoding='utf-8')
        except (UnicodeDecodeError, OSError):
            continue
        for number, line in enumerate(text.splitlines(), 1):
            if (rel.as_posix(), line.strip()) in ALLOWED_EXACT_LINES:
                continue
            for label, pattern in PATTERNS:
                if pattern.search(line):
                    errors.append(f'{rel}:{number}: {label}')
    if errors:
        print('Secret scan: FAIL', file=sys.stderr)
        print('\n'.join(sorted(set(errors))), file=sys.stderr)
        return 1
    print('Secret scan: PASS')
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
