<#
Uruchamia wszystkie testy gry (tests/*.gd) w Godocie i podsumowuje wyniki.
Testy z oknem (zrzuty, mysz, interfejs) otwierają na chwilę okno gry; reszta działa bez okna.
Zapisy testów idą do user://test_savegame.json - prawdziwy zapis gracza zostaje nietknięty.

Użycie:  powershell -File tests/run_tests.ps1 [-Godot <ścieżka do Godot_v4.7.2-stable_win64_console.exe>] [-Bench]
Ścieżkę do Godota można też podać w zmiennej środowiskowej GODOT.
-Bench dodaje pomiar wydajności walki we wszystkich krainach (kilka minut).
#>
param([string]$Godot = $env:GODOT, [switch]$Bench)

$ErrorActionPreference = "Stop"
$project = Split-Path -Parent $PSScriptRoot
if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Host "Podaj ścieżkę do Godota: -Godot <plik .exe> albo zmienna GODOT" -ForegroundColor Red
    exit 2
}
$out = Join-Path ([System.IO.Path]::GetTempPath()) "watra_tests"
New-Item -ItemType Directory -Force $out | Out-Null

# [plik, czy potrzebuje okna]
$tests = @(
    @("test_loot.gd", $false), @("test_stats.gd", $false), @("test_inv.gd", $false), @("test_drops.gd", $false),
    @("test_save_roundtrip.gd", $false), @("test_pal.gd", $false), @("test_audio.gd", $false), @("balance_sim.gd", $false),
    @("test_village.gd", $true), @("test_ui.gd", $true), @("test_pan.gd", $true)
)
if ($Bench) { $tests += ,@("bench_combat.gd", $false) }

Write-Host "Import zasobów..."
$p = Start-Process $Godot -ArgumentList "--path", $project, "--headless", "--import" -PassThru -NoNewWindow `
    -RedirectStandardOutput "$out\import_out.txt" -RedirectStandardError "$out\import_err.txt"
$p.WaitForExit(300000) | Out-Null

$failed = 0
foreach ($t in $tests) {
    $name = $t[0]
    $args = @("--path", $project)
    if ($t[1]) { $args += @("--resolution", "1280x720") } else { $args += "--headless" }
    $args += @("-s", (Join-Path $PSScriptRoot $name))
    $p = Start-Process $Godot -ArgumentList $args -PassThru -NoNewWindow `
        -RedirectStandardOutput "$out\$name.out.txt" -RedirectStandardError "$out\$name.err.txt"
    $timeout = if ($name -like "bench*") { 600000 } else { 180000 }
    if (-not $p.WaitForExit($timeout)) { $p.Kill(); Write-Host "[CZAS] $name" -ForegroundColor Red; $failed++; continue }
    $lines = Get-Content "$out\$name.out.txt" -Encoding UTF8
    $errors = Get-Content "$out\$name.err.txt" -Encoding UTF8 | Select-String "SCRIPT ERROR|Parse Error"
    $bad = $lines | Select-String "^FAIL|BLAD|: BLAD"
    $good = ($lines | Select-String "^OK|: OK|WYNIK: OK|^===").Count
    if ($errors -or $bad -or $good -eq 0) {
        $failed++
        Write-Host "[BŁĄD] $name" -ForegroundColor Red
        $bad | ForEach-Object { Write-Host "    $_" }
        $errors | Select-Object -First 5 | ForEach-Object { Write-Host "    $_" }
    } else {
        Write-Host "[OK]   $name ($good)" -ForegroundColor Green
        if ($name -like "bench*") { $lines | Select-String "^===" | ForEach-Object { Write-Host "    $_" } }
    }
}
Write-Host ""
if ($failed -eq 0) { Write-Host "Wszystkie testy przeszły." -ForegroundColor Green } else { Write-Host "Nieudane: $failed" -ForegroundColor Red }
exit $failed
