<#
Pobiera najnowszą wersję gry z GitHuba i od razu importuje zasoby w Godocie,
żeby gra widziała nowe skrypty i grafiki (bez tego po git pull gra się nie uruchamia).

Użycie (w folderze gry):  powershell -ExecutionPolicy Bypass -File aktualizuj.ps1
Inną ścieżkę do Godota można podać: -Godot <plik .exe> albo w zmiennej środowiskowej GODOT.
#>
param([string]$Godot = $(if ($env:GODOT) { $env:GODOT } else { "C:\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe" }))

Set-Location $PSScriptRoot

if (-not (Test-Path $Godot -PathType Leaf)) {
	Write-Host "Nie znaleziono Godota: $Godot (podaj ścieżkę: -Godot <plik .exe>)" -ForegroundColor Red
	exit 1
}

Write-Host "Pobieranie zmian (git pull)..." -ForegroundColor Cyan
git pull --no-edit origin main
if ($LASTEXITCODE -ne 0) {
	Write-Host "git pull się nie udał - zobacz komunikat wyżej." -ForegroundColor Red
	exit 1
}

Write-Host "Import zasobów w Godocie (może potrwać do kilku minut)..." -ForegroundColor Cyan
$proc = Start-Process -FilePath $Godot -ArgumentList "--headless", "--path", ".", "--import" -Wait -PassThru -NoNewWindow
if ($proc.ExitCode -ne 0) {
	Write-Host "Import zakończył się błędem (kod $($proc.ExitCode))." -ForegroundColor Red
	exit 1
}

Write-Host "Gotowe! Możesz uruchomić grę." -ForegroundColor Green
