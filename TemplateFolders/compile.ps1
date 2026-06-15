param(
    [string]$ProjectFolder,
    [switch]$All
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$appRoot = Split-Path -Parent $scriptDir

$outputDir = Join-Path $appRoot "assets\pic_templates"

function Compile-ProjectFolder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FolderPath
    )

    $sourcePath = (Resolve-Path $FolderPath).Path
    $projectName = Split-Path $sourcePath -Leaf

    if ($projectName.StartsWith("_")) {
        Write-Host "Skipped:"
        Write-Host "  $sourcePath"
        Write-Host "Reason:"
        Write-Host "  Folder name starts with _"
        return
    }

    $outputName = "$projectName.pictsx"
    $tempZip = Join-Path $scriptDir "$projectName.zip"
    $tempStage = Join-Path $scriptDir "_compile_stage_$projectName"
    $outputPath = Join-Path $outputDir $outputName

    if (Test-Path $tempZip) {
        Remove-Item $tempZip -Force
    }

    if (Test-Path $tempStage) {
        Remove-Item $tempStage -Recurse -Force
    }

    if (Test-Path $outputPath) {
        Remove-Item $outputPath -Force
    }

    $archiveFiles = Get-ChildItem -LiteralPath $sourcePath -Recurse -File -Force |
        Where-Object {
            $relativePath = $_.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
            $parts = $relativePath -split '[\\/]'
            -not ($parts | Where-Object { $_.StartsWith("_") })
        } |
        ForEach-Object {
            $_.FullName.Substring($sourcePath.Length).TrimStart('\', '/')
        }

    if (!$archiveFiles) {
        Write-Host "Skipped:"
        Write-Host "  $sourcePath"
        Write-Host "Reason:"
        Write-Host "  No files to archive after excluding _ folders"
        return
    }

    New-Item -ItemType Directory -Path $tempStage | Out-Null

    foreach ($relativePath in $archiveFiles) {
        $sourceFile = Join-Path $sourcePath $relativePath
        $stageFile = Join-Path $tempStage $relativePath
        $stageDir = Split-Path -Parent $stageFile

        if (!(Test-Path $stageDir)) {
            New-Item -ItemType Directory -Path $stageDir -Force | Out-Null
        }

        Copy-Item -LiteralPath $sourceFile -Destination $stageFile -Force
    }

    Push-Location $tempStage
    try {
        Compress-Archive -Path * -DestinationPath $tempZip -Force
    }
    finally {
        Pop-Location
        Remove-Item $tempStage -Recurse -Force
    }

    Move-Item $tempZip $outputPath -Force

    Write-Host "Compiled:"
    Write-Host "  $sourcePath"
    Write-Host "to:"
    Write-Host "  $outputPath"
}

if (!(Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

if ($ProjectFolder) {
    $sourcePath = Join-Path $scriptDir $ProjectFolder

    if (!(Test-Path $sourcePath)) {
        throw "Project folder not found: $sourcePath"
    }

    Compile-ProjectFolder -FolderPath $sourcePath
    exit 0
}

if (!$All) {
    Write-Host "No folder specified. Compiling all template folders."
}

$folders = Get-ChildItem -Path $scriptDir -Directory |
    Where-Object { !$_.Name.StartsWith("_") } |
    Sort-Object Name

foreach ($folder in $folders) {
    Compile-ProjectFolder -FolderPath $folder.FullName
}
