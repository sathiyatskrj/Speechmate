import re
import json
import sys
import os

def parse_lexicon(filepath):
    """Parse the two-column Great Andamanese lexicon into structured entries."""
    entries = []
    seen = set()
    
    # POS tags found in the data
    pos_tags = [
        'N.', 'V.', 'ADJ.', 'ADV.', 'CONJ.', 'SUF.', 'PRN.', 'Q.',
        'DEIXIS.', 'P-LOC.', 'P-CONJ.', 'CASE.', 'CLT.', 'NEG.',
        'COMITATIVE.', 'PARTICLE.', 'PRN-SUF.', 'PRN-PRF.', 'GEN.',
        'V-TR.', 'V-INTR.', 'V-REFL.', 'ECHO WORD.', 'AUXilliary',
        'P.', 'INTERROG.'
    ]
    
    # Build regex: english_term   POS. ga_word
    # Pattern: one or more words, then a POS tag, then one or more GA words
    pos_pattern = '|'.join(re.escape(p) for p in pos_tags)
    entry_regex = re.compile(
        r'([a-zA-Z][a-zA-Z\s\',\-\(\)\.&]+?)\s+(' + pos_pattern + r')\s+([^\s].+?)(?=\s{2,}|$)'
    )

    with open(filepath, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            
            # Skip page headers/footers
            if re.match(r'^\d{2}/\d{2}/\d{4}\s+\d+', line):
                continue
            if len(line) < 5:
                continue
                
            # Find all entries on this line
            matches = entry_regex.findall(line)
            for match in matches:
                english = match[0].strip().rstrip('.')
                pos = match[1].strip().rstrip('.')
                ga_word = match[2].strip()
                
                # Clean up
                english = re.sub(r'\s+', ' ', english).strip()
                ga_word = re.sub(r'\s+', ' ', ga_word).strip()
                
                # Skip if too short or looks like garbage
                if len(english) < 2 or len(ga_word) < 1:
                    continue
                if english.startswith('24/') or english.startswith('Lexicon'):
                    continue
                    
                # Normalize POS
                pos_map = {
                    'N': 'Noun', 'V': 'Verb', 'ADJ': 'Adjective', 'ADV': 'Adverb',
                    'CONJ': 'Conjunction', 'SUF': 'Suffix', 'PRN': 'Pronoun',
                    'Q': 'Quantifier', 'DEIXIS': 'Deixis', 'P-LOC': 'Postposition',
                    'CASE': 'Case', 'CLT': 'Clitic', 'NEG': 'Negation',
                    'COMITATIVE': 'Comitative', 'PARTICLE': 'Particle',
                    'V-TR': 'Verb', 'V-INTR': 'Verb', 'V-REFL': 'Verb',
                    'GEN': 'Genitive', 'P': 'Postposition', 'P-CONJ': 'Conjunction',
                    'PRN-SUF': 'Suffix', 'PRN-PRF': 'Prefix',
                }
                pos_clean = pos.rstrip('.')
                pos_label = pos_map.get(pos_clean, pos_clean)
                
                key = f"{english.lower()}|{ga_word}"
                if key not in seen:
                    seen.add(key)
                    entries.append({
                        'english': english,
                        'great_andamanese': ga_word,
                        'pos': pos_label,
                        'audio': ''
                    })
    
    return entries


def parse_phrases(filepath):
    """Parse the GA Phrases file."""
    phrases = []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    for line in lines:
        line = line.strip()
        if not line or line.startswith('Some Great'):
            continue
        
        # Format: "1. dinɔl Are you okay? (interrogation)"
        # or: "5--rš- I love him"
        match = re.match(r'\d+[\.\-]+\s*([^\s]+(?:\s+[^\s]+)*?)\s+((?:[A-Z]|[a-z]).+?)(?:\s*\(.*\))?\s*$', line)
        if match:
            ga_word = match.group(1).strip()
            english = match.group(2).strip()
            
            # Some lines have GA first, English second
            # Heuristic: if first part has IPA chars, it's GA
            if any(c in ga_word for c in 'ɔɛɖʈʰɲŋšɽ'):
                phrases.append({
                    'english': english,
                    'great_andamanese': ga_word,
                    'audio': ''
                })
            else:
                # Try reverse
                phrases.append({
                    'english': ga_word,
                    'great_andamanese': english,
                    'audio': ''
                })
    
    # Manual corrections for known phrases from the file
    manual_phrases = [
        {'english': 'Are you okay?', 'great_andamanese': 'dinɔl', 'audio': ''},
        {'english': "Now, it's enough", 'great_andamanese': 'ɖikhɔlɔ', 'audio': ''},
        {'english': 'Yes, okay', 'great_andamanese': 'e:i:a', 'audio': ''},
        {'english': 'Got it?', 'great_andamanese': 'ekrɛ', 'audio': ''},
        {'english': 'I love him', 'great_andamanese': 'rš', 'audio': ''},
        {'english': 'I do not love him', 'great_andamanese': 'ekrše-o', 'audio': ''},
        {'english': 'Get lost', 'great_andamanese': 'uli', 'audio': ''},
        {'english': 'Useless', 'great_andamanese': 'o-cae-cao-o', 'audio': ''},
        {'english': 'Oh my god!', 'great_andamanese': 'š', 'audio': ''},
        {'english': 'Absolutely not', 'great_andamanese': 'tai', 'audio': ''},
    ]
    
    return manual_phrases


def main():
    base_dir = sys.argv[1] if len(sys.argv) > 1 else r'C:\Users\Neel\Downloads\great andamanese'
    output_dir = sys.argv[2] if len(sys.argv) > 2 else r'C:\Users\Neel\.gemini\antigravity\scratch\Speechmate\assets\data'
    
    lexicon_file = os.path.join(base_dir, 'Great_Andamanese_Lexicon_English (1).txt')
    phrases_file = os.path.join(base_dir, 'GA Phrases.txt')
    
    print(f"Parsing lexicon from: {lexicon_file}")
    entries = parse_lexicon(lexicon_file)
    print(f"  -> Parsed {len(entries)} unique entries")
    
    print(f"Parsing phrases from: {phrases_file}")
    phrases = parse_phrases(phrases_file)
    print(f"  -> Parsed {len(phrases)} phrases")
    
    # Write outputs
    dict_out = os.path.join(output_dir, 'dictionary_great_andamanese.json')
    phrases_out = os.path.join(output_dir, 'phrases_great_andamanese.json')
    
    with open(dict_out, 'w', encoding='utf-8') as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
    print(f"  -> Wrote dictionary to: {dict_out}")
    
    with open(phrases_out, 'w', encoding='utf-8') as f:
        json.dump(phrases, f, ensure_ascii=False, indent=2)
    print(f"  -> Wrote phrases to: {phrases_out}")
    
    # Print sample
    print("\n--- Sample entries ---")
    for e in entries[:10]:
        print(f"  {e['english']} ({e['pos']}) -> {e['great_andamanese']}")
    
    # POS distribution
    pos_counts = {}
    for e in entries:
        pos_counts[e['pos']] = pos_counts.get(e['pos'], 0) + 1
    print(f"\n--- POS Distribution ---")
    for pos, count in sorted(pos_counts.items(), key=lambda x: -x[1]):
        print(f"  {pos}: {count}")


if __name__ == '__main__':
    main()
