# =============================================================================
# Script de lancement Flutter avec variables d'environnement (Windows)
# =============================================================================
# Usage: .\run_dev.ps1
# =============================================================================

# Charger les variables depuis env.local
$envFile = "env.local"

if (-Not (Test-Path $envFile)) {
    Write-Host "❌ Fichier env.local non trouve!" -ForegroundColor Red
    Write-Host "   Copiez env.local.example vers env.local et configurez vos cles API" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   cp env.local.example env.local" -ForegroundColor Cyan
    exit 1
}

# Lire les variables
$envVars = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match "^\s*([^#][^=]+)=(.*)$") {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $envVars[$key] = $value
    }
}

# Construire les dart-define
$dartDefines = ""
foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    if ($value -ne "" -and $value -ne "votre_cle_*") {
        $dartDefines += "--dart-define=$key=$value "
    }
}

Write-Host ""
Write-Host "🚀 Lancement de Deneige Auto en mode developpement" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Afficher les clés configurées (masquées)
foreach ($key in $envVars.Keys) {
    $value = $envVars[$key]
    if ($value -ne "" -and -not $value.StartsWith("votre_")) {
        $masked = $value.Substring(0, [Math]::Min(10, $value.Length)) + "..."
        Write-Host "   ✓ $key = $masked" -ForegroundColor Cyan
    } else {
        Write-Host "   ✗ $key (non configure)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Demarrage de Flutter..." -ForegroundColor Green
Write-Host ""

# Lancer Flutter
$command = "flutter run $dartDefines"
Write-Host "Commande: $command" -ForegroundColor DarkGray
Invoke-Expression $command
