$json = Get-Content 'assets\data\dictionary.json' -Raw | ConvertFrom-Json

Write-Host "Original entries: $($json.Count)" -ForegroundColor Cyan

# User's correct translations to keep
$correctTranslations = @{
    'sand'    = 'Kūyàyö'
    'wind'    = 'Kūföt'
    'one'     = 'Kahōk'
    'two'     = 'Nët'
    'three'   = 'Lūöi'
    'four'    = 'Fën'
    'five'    = 'Taneui'
    'head'    = 'Kūi'
    'eye'     = 'Mat'
    'ear'     = 'nâng'
    'nose'    = 'Elmëh'
    'mouth'   = 'Elvāng'
    'hand'    = 'el-tī'
    'finger'  = 'Kūnti'
    'leg'     = 'kal-drān'
    'stomach' = 'Ellön'
    'back'    = 'Ùk'
    'face'    = 'AreKuö'
    'blood'   = 'Māhām'
    'sun'     = 'tâwūˑe'
    'moon'    = 'chingeät'
    'star'    = 'Taneūsömat'
    'sky'     = 'Hāliöngö'
    'rain'    = 'kòmrâˑh'
    'fire'    = 'Tāmeūyö'
    'night'   = 'Hātööm'
    'evening' = 'Hāraap'
    'mother'  = 'Kikanö Yöng Nyiö'
    'father'  = 'Kikònyö Yöng'
    'brother' = 'Kanònyö-Mem/Kahem'
    'sister'  = 'Kānanö'
    'boy'     = 'Kikònyö'
    'girl'    = 'Kikanö'
    'child'   = 'Nyiö/Kūn Nyiö'
    'friend'  = 'Hòl'
}

# Special cases - keep both
$keepBoth = @('foot')

# Track removed entries
$removed = @()
$cleaned = @()

foreach ($entry in $json) {
    $english = $entry.english.ToLower().Trim()
    $nicobarese = $entry.nicobarese.Trim()
    
    # Remove entries with empty/dash Nicobarese
    if ($nicobarese -eq '-' -or $nicobarese -eq '') {
        $removed += "Removed: $($entry.english) → '$nicobarese' (empty/dash)"
        continue
    }
    
    # Check if this is a duplicate we need to handle
    if ($correctTranslations.ContainsKey($english)) {
        $correctNic = $correctTranslations[$english]
        
        # Keep only if it matches the correct translation
        if ($nicobarese -eq $correctNic) {
            $cleaned += $entry
        }
        else {
            $removed += "Removed: $($entry.english) → $nicobarese (keeping: $correctNic)"
        }
    }
    # Special case: Foot - keep both entries
    elseif ($keepBoth -contains $english) {
        $cleaned += $entry
    }
    # Not a duplicate - keep it
    else {
        $cleaned += $entry
    }
}

Write-Host "`nRemoved $($removed.Count) duplicate entries:" -ForegroundColor Yellow
foreach ($r in $removed) {
    Write-Host "  - $r" -ForegroundColor Gray
}

Write-Host "`nCleaned entries: $($cleaned.Count)" -ForegroundColor Green

# Save cleaned dictionary
$cleaned | ConvertTo-Json -Depth 10 | Set-Content 'assets\data\dictionary_cleaned.json' -Encoding UTF8

Write-Host "`nCleaned dictionary saved to: dictionary_cleaned.json" -ForegroundColor Green
Write-Host "Please review and then rename to dictionary.json" -ForegroundColor Cyan
