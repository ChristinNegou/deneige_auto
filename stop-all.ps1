# stop-all.ps1
# Script pour arreter tous les processus de developpement

Write-Host "========================================" -ForegroundColor Red
Write-Host "  Arret des services de developpement" -ForegroundColor Red
Write-Host "========================================" -ForegroundColor Red
Write-Host ""

# Arreter tous les processus Node.js
Write-Host "[*] Arret des processus Node.js..." -ForegroundColor Yellow
$nodeProcesses = Get-Process node -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
    Write-Host "[OK] Processus Node.js arretes" -ForegroundColor Green
} else {
    Write-Host "[i] Aucun processus Node.js en cours" -ForegroundColor Cyan
}

# Arreter les processus Gradle
Write-Host "[*] Arret des processus Gradle..." -ForegroundColor Yellow
cd android
.\gradlew --stop 2>$null
cd ..
Write-Host "[OK] Processus Gradle arretes" -ForegroundColor Green

Write-Host ""
Write-Host "[OK] Tous les services ont ete arretes" -ForegroundColor Green