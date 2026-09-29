[CmdletBinding()]
param([string]$Version)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$projectRoot = Split-Path -Parent $PSScriptRoot
$addonRoot = Join-Path $projectRoot 'PlateFaction'
$tocPath = Join-Path $addonRoot 'PlateFaction.toc'
$strictUtf8 = New-Object System.Text.UTF8Encoding($false, $true)
$toc = $strictUtf8.GetString([IO.File]::ReadAllBytes($tocPath))
$versionMatch = [regex]::Match($toc, '(?m)^## Version:\s*(\d+\.\d+\.\d+)\s*$')
if (-not $versionMatch.Success) { throw 'Missing semantic version in the TOC.' }
$tocVersion = $versionMatch.Groups[1].Value
if ($Version -and $Version -ne $tocVersion) { throw "Tag version $Version does not match TOC version $tocVersion." }
$Version = $tocVersion

# Only ship the manifest, its declared Lua files and the license.
$files = @('PlateFaction.toc')
foreach ($line in ($toc -split '\r?\n')) {
    $entry = $line.Trim()
    if (-not $entry -or $entry.StartsWith('#')) { continue }
    if ($entry -notmatch '^[A-Za-z0-9_-]+\.lua$') { throw "Unexpected TOC entry: $entry" }
    $files += $entry
}
foreach ($file in $files) {
    $path = Join-Path $addonRoot $file
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing package file: $file" }
    $null = $strictUtf8.GetString([IO.File]::ReadAllBytes($path))
}
$license = Join-Path $projectRoot 'LICENSE'
if (-not (Test-Path -LiteralPath $license -PathType Leaf)) { throw 'Missing LICENSE.' }
$outputDirectory = Join-Path $projectRoot 'dist'
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$outputPath = Join-Path $outputDirectory "PlateFaction-$Version.zip"
$stream = [IO.File]::Open($outputPath, [IO.FileMode]::Create)
try {
    $archive = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Create, $true)
    try {
        foreach ($file in $files) {
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, (Join-Path $addonRoot $file), "PlateFaction/$file") | Out-Null
        }
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $license, 'PlateFaction/LICENSE') | Out-Null
    }
    finally { $archive.Dispose() }
}
finally { $stream.Dispose() }
Write-Output $outputPath
