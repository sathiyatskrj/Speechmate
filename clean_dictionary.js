const fs = require('fs');

// Read the dictionary with BOM handling
const rawData = fs.readFileSync('assets/data/dictionary.json', 'utf8');
const cleanData = rawData.replace(/^\uFEFF/, ''); // Remove BOM
const data = JSON.parse(cleanData);

console.log(`Original entries: ${data.length}`);

// User's correct translations to keep
const correctTranslations = {
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
};

// Special cases - keep both
const keepBoth = ['foot'];

// Track removed entries
const removed = [];
const cleaned = [];

for (const entry of data) {
    const english = (entry.english || '').toLowerCase().trim();
    const nicobarese = (entry.nicobarese || '').trim();

    // Remove entries with empty/dash Nicobarese
    if (nicobarese === '-' || nicobarese === '') {
        removed.push(`Removed: ${entry.english} → '${nicobarese}' (empty/dash)`);
        continue;
    }

    // Check if this is a duplicate we need to handle
    if (correctTranslations[english]) {
        const correctNic = correctTranslations[english];

        // Keep only if it matches the correct translation
        if (nicobarese === correctNic) {
            cleaned.push(entry);
        } else {
            removed.push(`Removed: ${entry.english} → ${nicobarese} (keeping: ${correctNic})`);
        }
    }
    // Special case: Foot - keep both entries
    else if (keepBoth.includes(english)) {
        cleaned.push(entry);
    }
    // Not a duplicate - keep it
    else {
        cleaned.push(entry);
    }
}

console.log(`\nRemoved ${removed.length} duplicate entries`);
console.log(`Cleaned entries: ${cleaned.length}`);

// Save cleaned dictionary
fs.writeFileSync('assets/data/dictionary_cleaned.json', JSON.stringify(cleaned, null, 4), 'utf8');

console.log('\n✓ Cleaned dictionary saved to: dictionary_cleaned.json');
console.log(`✓ Removed: ${removed.length} entries`);
console.log(`✓ Kept: ${cleaned.length} entries`);
