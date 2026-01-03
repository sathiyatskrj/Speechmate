$json = Get-Content 'assets\data\dictionary.json' -Raw | ConvertFrom-Json

Write-Host "=== DICTIONARY ANALYSIS ===" -ForegroundColor Cyan
Write-Host "Total entries: $($json.Count)" -ForegroundColor Green

# Find duplicate English words
$englishDuplicates = @{}
$json | ForEach-Object {
    $eng = $_.english.ToLower().Trim()
    if ($eng) {
        if ($englishDuplicates.ContainsKey($eng)) {
            $englishDuplicates[$eng] += 1
        }
        else {
            $englishDuplicates[$eng] = 1
        }
    }
}

$engDups = $englishDuplicates.GetEnumerator() | Where-Object { $_.Value -gt 1 } | Sort-Object Value -Descending

Write-Host "`nDuplicate English words: $($engDups.Count)" -ForegroundColor Yellow

# Find duplicate Nicobarese words
$nicobareseDuplicates = @{}
$json | ForEach-Object {
    $nic = $_.nicobarese.ToLower().Trim()
    if ($nic) {
        if ($nicobareseDuplicates.ContainsKey($nic)) {
            $nicobareseDuplicates[$nic] += 1
        }
        else {
            $nicobareseDuplicates[$nic] = 1
        }
    }
}

$nicDups = $nicobareseDuplicates.GetEnumerator() | Where-Object { $_.Value -gt 1 } | Sort-Object Value -Descending

Write-Host "Duplicate Nicobarese words: $($nicDups.Count)" -ForegroundColor Yellow

# Generate detailed report
$report = @"
# Dictionary Duplicate Analysis Report

## Summary
- **Total Entries:** $($json.Count)
- **Duplicate English Words:** $($engDups.Count)
- **Duplicate Nicobarese Words:** $($nicDups.Count)

## Duplicate English Words

"@

foreach ($dup in $engDups) {
    $report += "`n### '$($dup.Name)' (appears $($dup.Value) times)`n`n"
    $entries = $json | Where-Object { $_.english.ToLower().Trim() -eq $dup.Name }
    $idx = 0
    foreach ($entry in $entries) {
        $idx++
        $report += "**Entry ${idx}:**`n"
        $report += "- English: $($entry.english)`n"
        $report += "- Nicobarese: $($entry.nicobarese)`n`n"
    }
}

$report += "`n## Duplicate Nicobarese Words`n`n"

foreach ($dup in $nicDups) {
    $report += "`n### '$($dup.Name)' (appears $($dup.Value) times)`n`n"
    $entries = $json | Where-Object { $_.nicobarese.ToLower().Trim() -eq $dup.Name }
    $idx = 0
    foreach ($entry in $entries) {
        $idx++
        $report += "**Entry ${idx}:**`n"
        $report += "- English: $($entry.english)`n"
        $report += "- Nicobarese: $($entry.nicobarese)`n`n"
    }
}

# Save report
$report | Out-File -FilePath "duplicate_analysis.txt" -Encoding UTF8

Write-Host "`nReport saved to: duplicate_analysis.txt" -ForegroundColor Green
