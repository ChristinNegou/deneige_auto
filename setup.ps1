# setup.ps1
# Script d'installation initiale du projet

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration initiale du projet" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Verifier Node.js
Write-Host "[*] Verification de Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Node.js n'est pas installe!" -ForegroundColor Red
    Write-Host "[!] Telechargez-le depuis: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Node.js: $nodeVersion" -ForegroundColor Green

# Verifier Flutter
Write-Host "[*] Verification de Flutter..." -ForegroundColor Yellow
$flutterVersion = flutter --version 2>$null | Select-Object -First 1
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Flutter n'est pas installe!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] $flutterVersion" -ForegroundColor Green
Write-Host ""

# Installer les dependances backend
Write-Host "[*] Installation des dependances backend..." -ForegroundColor Cyan
Set-Location backend
npm install
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Erreur lors de l'installation des dependances backend" -ForegroundColor Red
    Set-Location ..
    exit 1
}
Set-Location ..
Write-Host "[OK] Dependances backend installees" -ForegroundColor Green
Write-Host ""

# Installer les dependances Flutter
Write-Host "[*] Installation des dependances Flutter..." -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Erreur lors de l'installation des dependances Flutter" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Dependances Flutter installees" -ForegroundColor Green
Write-Host ""

# Nettoyer et construire
Write-Host "[*] Nettoyage du projet..." -ForegroundColor Yellow
flutter clean
cd android
.\gradlew clean
cd ..
Write-Host "[OK] Projet nettoye" -ForegroundColor Green
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  Configuration terminee avec succes!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "[*] Vous pouvez maintenant lancer: .\start-dev.ps1" -ForegroundColor Cyan