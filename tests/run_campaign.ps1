param(
    [ValidateRange(1, 3)][int]$StartingStage = 1,
    [ValidateRange(1, 10)][int]$StartingWave = 1,
    [string]$Godot = 'C:\ProgramData\chocolatey\lib\godot\tools\Godot_v4.6.1-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$verificationRoot = Join-Path $projectRoot 'Temp/campaign-verification'
New-Item -ItemType Directory -Path $verificationRoot -Force | Out-Null
foreach ($folder in @('assets', 'scenes', 'scripts', 'tests')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $folder) -Destination $verificationRoot -Recurse -Force
}
foreach ($file in @('ui_theme.tres', 'icon.svg')) {
    Copy-Item -LiteralPath (Join-Path $projectRoot $file) -Destination $verificationRoot -Force
}
$config = [IO.File]::ReadAllText((Join-Path $projectRoot 'project.godot'))
$config = $config.Replace('config/name="Arena Shooter"', 'config/name="Arena Shooter Campaign Verification"')
$config = $config.Replace('run/main_scene="res://scenes/Lobby.tscn"', 'run/main_scene="res://tests/campaign_test.tscn"')
$config = $config.Replace('window/size/mode=4', 'window/size/mode=0')
[IO.File]::WriteAllText((Join-Path $verificationRoot 'project.godot'), $config)
$constantsPath = Join-Path $verificationRoot 'scripts/game_constants.gd'
$constants = [IO.File]::ReadAllText($constantsPath)
$constants = [regex]::Replace($constants, 'const DEBUG_STARTING_STAGE: int = \d+', "const DEBUG_STARTING_STAGE: int = $StartingStage")
$constants = [regex]::Replace($constants, 'const DEBUG_STARTING_WAVE: int = \d+', "const DEBUG_STARTING_WAVE: int = $StartingWave")
[IO.File]::WriteAllText($constantsPath, $constants)
function Invoke-CampaignGodot([string]$Flags, [string]$LogName) {
    $logPath = Join-Path $projectRoot ('Temp/' + $LogName)
    $arguments = '--path "' + $verificationRoot + '" --log-file "' + $logPath + '" ' + $Flags
    $testProcess = Start-Process -FilePath $Godot -ArgumentList $arguments -WindowStyle Hidden -PassThru
    if (-not $testProcess.WaitForExit(60000)) {
        $testProcess.Kill()
        throw "Verification timed out. Inspect $logPath"
    }
    $logText = [IO.File]::ReadAllText($logPath)
    if ($testProcess.ExitCode -ne 0 -or $logText -match '(?im)^(SCRIPT ERROR:|ERROR:|WARNING:)|leaked|Orphan StringName|unclaimed string names') {
        throw "Godot verification failed. Inspect $logPath"
    }
    return $logText
}
$null = Invoke-CampaignGodot '--headless --editor --import --quit' 'campaign-test-import.log'
$renderLog = Invoke-CampaignGodot '--rendering-method gl_compatibility --audio-driver Dummy --verbose --quit-after 2500' 'campaign-render.log'
if ($renderLog -notmatch 'OpenGL API.*Compatibility' -or $renderLog -notmatch '(CAMPAIGN_TEST_RESULT|DEBUG_START_TEST_RESULT) failures=0 .*orphans=0') {
    throw 'Real Compatibility renderer or complete lifecycle test did not pass.'
}
Write-Output ($renderLog -split "
" | Where-Object { $_ -match 'TEST_RESULT' })
Write-Output 'PASS: clean GLES3 shutdown.'
Write-Output "Screenshots and isolated game copy: $verificationRoot"
