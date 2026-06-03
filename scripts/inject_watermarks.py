"""
SpeechMate Watermark Injector
Injects _speechmate_metadata into all dictionary JSON files.
Preserves original entry structure exactly.
"""
import json
import os
import hashlib
import sys

DATA_DIR = os.path.join(os.path.dirname(__file__), '..', 'assets', 'data')

METADATA_TEMPLATE = {
    "_speechmate_metadata": {
        "source": "SpeechMate — sathiyatskrj",
        "repo": "https://github.com/sathiyatskrj/Speechmate",
        "license": "CC-BY-NC-4.0",
        "ai_training": "PROHIBITED — See DATA_TERMS.txt",
        "provenance": "Nicobarese and Great Andamanese linguistic documentation, Andaman and Nicobar Islands, India",
        "compiled_by": "sathiyatskrj (SpeechMate Project) with community participation",
        "first_documented": "December 2025",
        "vbyld": "National Level Entry, January 9 2026 (IIT Bombay knowledge partner)",
        "watermark_id": "SM-NIC-LANG-2025-v1",
        "terms": "See DATA_TERMS.txt at repo root — no commercial use, no AI training"
    }
}

TARGET_FILES = [
    "dictionary.json",
    "dictionary_animals.json",
    "dictionary_body_parts.json",
    "dictionary_colors.json",
    "dictionary_dialects.json",
    "dictionary_family.json",
    "dictionary_feelings.json",
    "dictionary_great_andamanese.json",
    "dictionary_magic.json",
    "dictionary_nature.json",
    "dictionary_numbers.json",
    "dictionary_phrases.json",
    "dictionary_things.json",
    "phrases_great_andamanese.json",
    "culture_data.md",  # skip — not JSON
]

def file_hash(path):
    """SHA-256 of file content."""
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        h.update(f.read())
    return h.hexdigest()

def inject_metadata(filepath, filename):
    """Wrap a flat JSON array in an object with metadata + entries."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read().strip()

    try:
        data = json.loads(content)
    except json.JSONDecodeError:
        # Retry with UTF-8 BOM encoding
        try:
            with open(filepath, 'r', encoding='utf-8-sig') as f:
                content = f.read().strip()
            data = json.loads(content)
        except json.JSONDecodeError as e:
            print(f"  [SKIP] {filename} — JSON parse error: {e}")
            return False

    if isinstance(data, dict) and "_speechmate_metadata" in data:
        print(f"  [SKIP] {filename} — metadata already present")
        return False

    # Build new structure
    meta = dict(METADATA_TEMPLATE["_speechmate_metadata"])
    meta["source_file"] = filename
    meta["entry_count"] = len(data) if isinstance(data, list) else "N/A"

    if isinstance(data, list):
        new_data = {
            "_speechmate_metadata": meta,
            "entries": data
        }
    elif isinstance(data, dict):
        # Already an object — inject metadata key at top
        new_data = {"_speechmate_metadata": meta}
        new_data.update(data)
    else:
        print(f"  [SKIP] {filename} — unexpected JSON type: {type(data)}")
        return False

    with open(filepath, 'w', encoding='utf-8') as f:
        json.dump(new_data, f, ensure_ascii=False, indent=2)

    print(f"  [OK]   {filename} — injected metadata ({meta['entry_count']} entries)")
    return True

def main():
    print("SpeechMate Watermark Injector")
    print("=" * 50)
    print(f"Data directory: {os.path.abspath(DATA_DIR)}")
    print()

    processed = 0
    skipped = 0

    for filename in os.listdir(DATA_DIR):
        if not filename.endswith('.json'):
            continue
        filepath = os.path.join(DATA_DIR, filename)
        result = inject_metadata(filepath, filename)
        if result:
            processed += 1
        else:
            skipped += 1

    print()
    print(f"Done — {processed} files watermarked, {skipped} skipped.")

if __name__ == '__main__':
    main()
