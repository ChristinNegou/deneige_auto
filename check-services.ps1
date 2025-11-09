# check-services.ps1
# Script pour verifier l'etat des services

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Verification des services actifs" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verifier les processus Node.js
Write-Host "[*] Processus Node.js:" -ForegroundColor Yellow
$nodeProcesses = Get-Process node -ErrorAction SilentlyContinue
if ($nodeProcesses) {
    $nodeProcesses | Format-Table Id, ProcessName, @{Name="Memoire (MB)"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}} -AutoSize
    Write-Host "[OK] $($nodeProcesses.Count) processus Node.js actif(s)" -ForegroundColor Green
} else {
    Write-Host "[X] Aucun processus Node.js actif" -ForegroundColor Red
}

Write-Host ""

# Verifier si le serveur backend repond
Write-Host "[*] Etat du serveur backend (http://localhost:3000):" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000" -Method GET -TimeoutSec 3
    Write-Host "[OK] Serveur operationnel - Version: $($response.version)" -ForegroundColor Green
    Write-Host "     Message: $($response.message)" -ForegroundColor Cyan
} catch {
    Write-Host "[X] Serveur non accessible" -ForegroundColor Red
}

Write-Host ""

# Verifier les processus Java (Flutter/Gradle)
Write-Host "[*] Processus Java (Flutter/Gradle):" -ForegroundColor Yellow
$javaProcesses = Get-Process java -ErrorAction SilentlyContinue
if ($javaProcesses) {
    Write-Host "[OK] $($javaProcesses.Count) processus Java actif(s)" -ForegroundColor Green
} else {
    Write-Host "[i] Aucun processus Java actif" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Verification terminee!" -ForegroundColor Green