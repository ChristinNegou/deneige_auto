# start-backend.ps1
# Script pour demarrer uniquement le backend

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  DEMARRAGE DU SERVEUR BACKEND" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

cd backend

# Verifier si node_modules existe
if (-not (Test-Path "node_modules")) {
    Write-Host "[*] Installation des dependances..." -ForegroundColor Yellow
    npm install
    Write-Host ""
}

Write-Host "[*] Lancement du serveur..." -ForegroundColor Green
Write-Host ""

npm run dev