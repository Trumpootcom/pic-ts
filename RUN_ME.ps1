Write-Host ""
Write-Host "========================================="
Write-Host " PIC Tool Suite Build"
Write-Host "========================================="
Write-Host ""

$hash = git rev-parse --short HEAD
$date = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$buildTime = Get-Date -Format "HH:mm:ss"

@"
const String gitCommit = '$hash';
const String buildDate = '$date';
const String buildTime = '$buildTime';
"@ | Set-Content "lib/build_info.dart"

Write-Host "Git Commit : $hash"
Write-Host "Build Date : $date"
Write-Host ""

flutter run