import json
import sys

# Read the dictionary
with open('assets/data/dictionary.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Original entries: {len(data)}")

# User's correct translations to keep
correct_translations = {
    'sand': 'Kūyàyö',
    'wind': 'Kūföt',
    'one': 'Kahōk',
    'two': 'Nët',
    'three': 'Lūöi',
    'four': 'Fën',
    'five': 'Taneui',
    'head': 'Kūi',
    'eye': 'Mat',
    'ear': 'nâng',
    'nose': 'Elmëh',
    'mouth': 'Elvāng',
    'hand': 'el-tī',
    'finger': 'Kūnti',
    'leg': 'kal-drān',
    'stomach': 'Ellön',
    'back': 'Ùk',
    'face': 'AreKuö',
    'blood': 'Māhām',
    'sun': 'tâwūˑe',
    'moon': 'chingeät',
    'star': 'Taneūsömat',
    'sky': 'Hāliöngö',
    'rain': 'kòmrâˑh',
    'fire': 'Tāmeūyö',
    'night': 'Hātööm',
    'evening': 'Hāraap',
    'mother': 'Kikanö Yöng Nyiö',
    'father': 'Kikònyö Yöng',
    'brother': 'Kanònyö-Mem/Kahem',
    'sister': 'Kānanö',
    'boy': 'Kikònyö',
    'girl': 'Kikanö',
    'child': 'Nyiö/Kūn Nyiö',
    'friend': 'Hòl'
}

# Special cases - keep both
keep_both = ['foot']

# Track removed entries
removed = []
cleaned = []

for entry in data:
    english = entry.get('english', '').lower().strip()
    nicobarese = entry.get('nicobarese', '').strip()
    
    # Remove entries with empty/dash Nicobarese
    if nicobarese in ['-', '']:
        removed.append(f"Removed: {entry['english']} → '{nicobarese}' (empty/dash)")
        continue
    
    # Check if this is a duplicate we need to handle
    if english in correct_translations:
        correct_nic = correct_translations[english]
        
        # Keep only if it matches the correct translation
        if nicobarese == correct_nic:
            cleaned.append(entry)
        else:
            removed.append(f"Removed: {entry['english']} → {nicobarese} (keeping: {correct_nic})")
    # Special case: Foot - keep both entries
    elif english in keep_both:
        cleaned.append(entry)
    # Not a duplicate - keep it
    else:
        cleaned.append(entry)

print(f"\nRemoved {len(removed)} duplicate entries:")
for r in removed[:10]:  # Show first 10
    print(f"  - {r}")
if len(removed) > 10:
    print(f"  ... and {len(removed) - 10} more")

print(f"\nCleaned entries: {len(cleaned)}")

# Save cleaned dictionary
with open('assets/data/dictionary_cleaned.json', 'w', encoding='utf-8') as f:
    json.dump(cleaned, f, ensure_ascii=False, indent=4)

print("\nCleaned dictionary saved to: dictionary_cleaned.json")
print("Entries removed:", len(removed))
print("Entries kept:", len(cleaned))
