param(
    [Parameter(Mandatory = $true)]
    [string]$ProjectFolder
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir

$sourcePath = Join-Path $scriptDir $ProjectFolder
$outputName = "$ProjectFolder.pictsx"
$tempZip = Join-Path $scriptDir "$ProjectFolder.zip"
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

Compress-Archive -Path (Join-Path $sourcePath "*") -DestinationPath $tempZip -Force
Move-Item $tempZip $outputPath -Force

Write-Host "Compiled:"
Write-Host "  $sourcePath"
Write-Host "to:"
Write-Host "  $outputPath"