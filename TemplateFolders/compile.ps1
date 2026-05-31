param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectFolder
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir

$sourcePath = (Resolve-Path (Join-Path $scriptDir $ProjectFolder)).Path
$projectName = Split-Path $sourcePath -Leaf

$outputName = "$projectName.pictsx"
$tempZip = Join-Path $scriptDir "$projectName.zip"
$outputDir = Join-Path $appRoot "assets\pic_templates"
$outputPath = Join-Path $outputDir $outputName

if (!(Test-Path $sourcePath)) {
    throw "Project folder not found: $sourcePath"
}

if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if (Test-Path $tempZip) {
    Remove-Item $tempZip -Force
}

if (Test-Path $outputPath) {
    Remove-Item $outputPath -Force
}

Push-Location $sourcePath
try {
    Compress-Archive -Path * -DestinationPath $tempZip -Force
}
finally {
    Pop-Location
}

Move-Item $tempZip $outputPath -Force

Write-Host "Compiled:"
Write-Host "  $sourcePath"
Write-Host "to:"
Write-Host "  $outputPath"