$path = "lib\screens\flashcard_review_screen.dart"
$content = Get-Content $path -Raw -Encoding UTF8

$content = $content.Replace('_buildGradeBtn("Fail", 1, Colors.redAccent)', '_buildGradeBtn("Fail", 1, Colors.redAccent, "F")')
$content = $content.Replace('_buildGradeBtn("Hard", 3, Colors.orangeAccent)', '_buildGradeBtn("Hard", 3, Colors.orangeAccent, "H")')
$content = $content.Replace('_buildGradeBtn("Good", 4, Colors.green)', '_buildGradeBtn("Good", 4, Colors.green, "G")')
$content = $content.Replace('_buildGradeBtn("Easy", 5, Colors.blue)', '_buildGradeBtn("Easy", 5, Colors.blue, "E")')

[System.IO.File]::WriteAllText((Resolve-Path $path), $content, [System.Text.Encoding]::UTF8)
Write-Host "Done"
