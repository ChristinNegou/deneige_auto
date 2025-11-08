
# start-dev.ps1
# Script pour demarrer le backend et l'application Flutter simultanement

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deneige Auto - Demarrage en mode DEV" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifier si Node.js est installe
Write-Host "[*] Verification de Node.js..." -ForegroundColor Yellow
$nodeVersion = node --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] Node.js n'est pas installe!" -ForegroundColor Red
    Write-Host "[!] Telechargez-le depuis: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}
Write-Host "[OK] Node.js installe: $nodeVersion" -ForegroundColor Green

# Verifier si npm est installe
Write-Host "[*] Verification de npm..." -ForegroundColor Yellow
$npmVersion = npm --version 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "[X] npm n'est pas installe!" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] npm installe: v$npmVersion" -ForegroundColor Green
Write-Host ""

# Verifier si les dependances backend sont installees
if (-Not (Test-Path "backend\node_modules")) {
    Write-Host "[*] Installation des dependances backend..." -ForegroundColor Yellow
    Set-Location backend
    npm install
    Set-Location ..
    Write-Host "[OK] Dependances backend installees" -ForegroundColor Green
} else {
    Write-Host "[OK] Dependances backend deja installees" -ForegroundColor Green
}

Write-Host ""
Write-Host "[*] Demarrage du serveur backend..." -ForegroundColor Green

# Demarrer le serveur backend dans une nouvelle fenetre
$backendPath = Join-Path $PWD "backend"
Start-Process powershell -ArgumentList "-NoExit", "-Command", "Write-Host '======================================' -ForegroundColor Magenta; Write-Host '  Backend Node.js - Console' -ForegroundColor Magenta; Write-Host '======================================' -ForegroundColor Magenta; Write-Host ''; cd '$backendPath'; npm run dev"

# Attendre que le serveur demarre
Write-Host "[*] Attente du demarrage du serveur (5 secondes)..." -ForegroundColor Yellow
Start-Sleep -Seconds 5

# Tester si le serveur repond
Write-Host "[*] Verification de la connexion au serveur..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -Method GET -TimeoutSec 3 -UseBasicParsing
    Write-Host "[OK] Serveur backend operationnel!" -ForegroundColor Green
} catch {
    Write-Host "[!] Le serveur pourrait ne pas etre pret, mais on continue..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "[*] Demarrage de l'application Flutter..." -ForegroundColor Cyan
Write-Host ""

# Demarrer Flutter dans le terminal actuel
flutter run