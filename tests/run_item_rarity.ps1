param(
    [string]$Godot = 'C:\ProgramData\chocolatey\lib\godot\tools\Godot_v4.6.1-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$verificationRoot = Join-Path $projectRoot 'Temp/rarity-verification'
New-Item -ItemType Directory -Path $verificationRoot -Force | Out-Null
foreach ($folder in @('assets', 'scenes', 'scripts', 'tests')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $folder) -Destination $verificationRoot -Recurse -Force
}
foreach ($file in @('ui_theme.tres', 'icon.svg')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $verificationRoot -Force
}
$config = [IO.File]::ReadAllText((Join-Path $projectRoot 'project.godot'))
$config = $config.Replace('config/name="Arena Shooter"', 'config/name="Arena Shooter Rarity Verification"')
$config = $config.Replace('run/main_scene="res://scenes/Lobby.tscn"', 'run/main_scene="res://tests/item_rarity_test.tscn"')
$config = $config.Replace('window/size/mode=4', 'window/size/mode=0')
[IO.File]::WriteAllText((Join-Path $verificationRoot 'project.godot'), $config)
function Invoke-RarityGodot([string]$Flags, [string]$LogName) {
    $logPath = Join-Path $projectRoot ('Temp/' + $LogName)
    $arguments = '--path "' + $verificationRoot + '" --log-file "' + $logPath + '" ' + $Flags
    $testProcess = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $testProcess.WaitForExit(60000)) {
        $testProcess.Kill()
        throw 'Godot verification timed out.'
    }
    $logText = [IO.File]::ReadAllText($logPath)
    if ($testProcess.ExitCode -ne 0 -or $logText -match '(?im)^(SCRIPT ERROR:|ERROR:|WARNING:)|leaked|Orphan StringName|unclaimed string names') {
        throw "Godot verification failed. Inspect $logPath"
    }
    return $logText
}
$null = Invoke-RarityGodot '--headless --editor --import --quit' 'rarity-import.log'
$renderLog = Invoke-RarityGodot '--rendering-method gl_compatibility --audio-driver Dummy --verbose --quit-after 1500' 'rarity-render.log'
if ($renderLog -notmatch 'OpenGL API.*Compatibility' -or $renderLog -notmatch 'RARITY_TEST_RESULT failures=0 items=83 orphans=0') {
    throw 'The real Compatibility renderer or complete lifecycle test did not pass.'
}
Write-Output 'PASS: 83 items, weighted draws, eligibility, UI lifecycle, zero orphans, clean GLES3 shutdown.'
Write-Output "Screenshots and isolated game copy: $verificationRoot"
