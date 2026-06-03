"""
SpeechMate Prior Art Snapshot Generator
Generates a timestamped, reproducible evidence package of all data file
hashes and git commit information. Save this output offline as prior art proof.

Usage:
    python scripts/generate_prior_art_snapshot.py > snapshot_YYYYMMDD.json
"""
import json
import os
import hashlib
import subprocess
import sys
from datetime import datetime, timezone

REPO_ROOT = os.path.join(os.path.dirname(__file__), '..')
DATA_DIR = os.path.join(REPO_ROOT, 'assets', 'data')
SCRIPTS_DIR = os.path.join(REPO_ROOT, 'scripts')

def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()

def git_log(repo_root, n=5):
    try:
        result = subprocess.run(
            ['git', 'log', '--oneline', f'-{n}', '--format=%H %ai %s'],
            cwd=repo_root, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip().splitlines()
    except Exception as e:
        return [f"git error: {e}"]

def git_first_commit(repo_root):
    try:
        result = subprocess.run(
            ['git', 'log', '--reverse', '--format=%H %ai %s'],
            cwd=repo_root, capture_output=True, text=True, timeout=10
        )
        lines = result.stdout.strip().splitlines()
        return lines[0] if lines else "unknown"
    except Exception as e:
        return f"git error: {e}"

def git_current_commit(repo_root):
    try:
        result = subprocess.run(
            ['git', 'rev-parse', 'HEAD'],
            cwd=repo_root, capture_output=True, text=True, timeout=10
        )
        return result.stdout.strip()
    except Exception as e:
        return f"git error: {e}"

def main():
    now = datetime.now(timezone.utc)
    snapshot = {
        "speechmate_prior_art_snapshot": {
            "generated_at": now.isoformat(),
            "purpose": "Evidence of prior art for SpeechMate linguistic data and software",
            "creator": "sathiyatskrj (SpeechMate Project)",
            "vbyld": "National Level Entry — January 9, 2026 (IIT Bombay knowledge partner)",
            "repo": "https://github.com/sathiyatskrj/Speechmate",
            "data_license": "CC-BY-NC-4.0 — See DATA_TERMS.txt",
            "code_license": "Apache-2.0 — See LICENSE",
            "watermark_id": "SM-NIC-LANG-2025-v1",
        },
        "git_info": {
            "current_commit": git_current_commit(REPO_ROOT),
            "first_commit": git_first_commit(REPO_ROOT),
            "recent_commits": git_log(REPO_ROOT, 5),
        },
        "data_file_hashes": {},
        "script_file_hashes": {},
    }

    # Hash all data files
    for filename in sorted(os.listdir(DATA_DIR)):
        filepath = os.path.join(DATA_DIR, filename)
        if os.path.isfile(filepath):
            snapshot["data_file_hashes"][filename] = sha256_file(filepath)

    # Hash the protection scripts themselves
    for filename in sorted(os.listdir(SCRIPTS_DIR)):
        filepath = os.path.join(SCRIPTS_DIR, filename)
        if os.path.isfile(filepath) and filename.endswith('.py'):
            snapshot["script_file_hashes"][filename] = sha256_file(filepath)

    print(json.dumps(snapshot, indent=2, ensure_ascii=False))

if __name__ == '__main__':
    main()
