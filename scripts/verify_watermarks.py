"""
SpeechMate Watermark Verifier
Verifies that all dictionary JSON files have intact _speechmate_metadata blocks.
Also generates a SHA-256 fingerprint of each file's entries array.

Usage:
    python scripts/verify_watermarks.py

Exit codes:
    0 — all files verified
    1 — one or more files missing metadata (CI will fail)
"""
import json
import os
import hashlib
import sys
from datetime import datetime, timezone

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data')

REQUIRED_METADATA_KEYS = [
    "_speechmate_metadata",
]
REQUIRED_META_FIELDS = [
    "source", "license", "ai_training", "watermark_id"
]

def sha256_of_list(entries):
    """Reproducible SHA-256 of a JSON list (sorted keys for stability)."""
    serialized = json.dumps(entries, ensure_ascii=False, sort_keys=True)
    return hashlib.sha256(serialized.encode('utf-8')).hexdigest()

def verify_file(filepath, filename):
    """Returns (ok: bool, details: str, fingerprint: str|None)."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except UnicodeDecodeError:
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                data = json.load(f)
        except Exception as e:
            return False, f"Parse error: {e}", None
    except Exception as e:
        return False, f"Parse error: {e}", None

    if not isinstance(data, dict):
        return False, "Root is not an object — metadata missing (plain array)", None

    if "_speechmate_metadata" not in data:
        return False, "Missing _speechmate_metadata key", None

    meta = data["_speechmate_metadata"]
    missing = [k for k in REQUIRED_META_FIELDS if k not in meta]
    if missing:
        return False, f"Metadata incomplete — missing fields: {missing}", None

    entries = data.get("entries", [])
    fingerprint = sha256_of_list(entries)
    entry_count = len(entries) if isinstance(entries, list) else "N/A"
    return True, f"{entry_count} entries", fingerprint

def main():
    print("SpeechMate Watermark Verifier")
    print("=" * 60)
    print(f"Timestamp: {datetime.now(timezone.utc).isoformat()}")
    print(f"Data directory: {os.path.abspath(DATA_DIR)}")
    print()

    all_ok = True
    results = []

    for filename in sorted(os.listdir(DATA_DIR)):
        if not filename.endswith('.json'):
            continue
        filepath = os.path.join(DATA_DIR, filename)
        ok, details, fingerprint = verify_file(filepath, filename)
        status = "[OK]  " if ok else "[FAIL]"
        fp_str = f"  sha256:{fingerprint[:16]}..." if fingerprint else ""
        print(f"  {status} {filename:<45} {details}{fp_str}")
        if not ok:
            all_ok = False
        results.append({
            "file": filename,
            "ok": ok,
            "details": details,
            "fingerprint": fingerprint,
        })

    print()
    if all_ok:
        print("[PASS] All dictionary files have valid watermarks.")
        print()
        print("Fingerprint snapshot (save this for evidence):")
        for r in results:
            if r["fingerprint"]:
                print(f"  {r['file']}: {r['fingerprint']}")
        sys.exit(0)
    else:
        print("[FAIL] WATERMARK VERIFICATION FAILED.")
        print("  One or more dictionary files are missing _speechmate_metadata.")
        print("  Run: python scripts/inject_watermarks.py  to restore them.")
        sys.exit(1)

if __name__ == '__main__':
    main()
