#Requires -Version 5.1

# -- Instalador de PCFacil -------------------------------------
# Uso: iwr -useb https://raw.githubusercontent.com/brayam-marre/PCFacil/main/install.ps1 | iex

$ProgressPreference    = 'SilentlyContinue'
$ErrorActionPreference = 'Stop'
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$baseUrl     = "https://raw.githubusercontent.com/brayam-marre/PCFacil/main"
$installPath = "$env:LOCALAPPDATA\PCFacil"

# -- Cabecera --------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "         PC FACIL  -  Cuida tu computador   " -ForegroundColor Cyan
Write-Host "  ==========================================" -ForegroundColor Cyan
Write-Host "  v1.0.0  |  $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  $('-' * 60)" -ForegroundColor DarkGray
Write-Host ""

# -- Verificar PowerShell version ------------------------------
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Host "  ERROR: Se requiere PowerShell 5.1 o superior." -ForegroundColor Red
    exit 1
}

# -- Verificar conexion a internet -----------------------------
Write-Host "  Verificando conexion a internet..." -ForegroundColor DarkGray
try {
    $null = Invoke-WebRequest -Uri "https://github.com" -UseBasicParsing -TimeoutSec 8
    Write-Host "  [OK] Conexion verificada" -ForegroundColor Green
} catch {
    Write-Host "  Sin conexion a internet. Verifica tu red e intenta nuevamente." -ForegroundColor Red
    exit 1
}

# -- Crear directorios -----------------------------------------
Write-Host "  Preparando archivos..." -ForegroundColor DarkGray
New-Item -ItemType Directory -Path $installPath           -Force | Out-Null
New-Item -ItemType Directory -Path "$installPath\modules" -Force | Out-Null

# -- Descargar archivos ----------------------------------------
Write-Host "  Descargando PCFacil..." -ForegroundColor DarkGray
Write-Host ""

$files = @(
    @{ Url = "$baseUrl/PCFacil.ps1";              Out = "$installPath\PCFacil.ps1" },
    @{ Url = "$baseUrl/modules/diagnostico.ps1";  Out = "$installPath\modules\diagnostico.ps1" },
    @{ Url = "$baseUrl/modules/limpieza.ps1";     Out = "$installPath\modules\limpieza.ps1" },
    @{ Url = "$baseUrl/modules/reporte.ps1";      Out = "$installPath\modules\reporte.ps1" }
)

$success = $true
foreach ($file in $files) {
    try {
        Invoke-WebRequest -Uri $file.Url -OutFile $file.Out -UseBasicParsing
        Write-Host "  [OK] $(Split-Path $file.Out -Leaf)" -ForegroundColor Green
    } catch {
        Write-Host "  [ERROR] No se pudo descargar: $(Split-Path $file.Out -Leaf)" -ForegroundColor Red
        $success = $false
    }
}

if (-not $success) {
    Write-Host ""
    Write-Host "  Hubo errores al descargar. Intenta nuevamente." -ForegroundColor Red
    Remove-Item -Path $installPath -Recurse -Force -ErrorAction SilentlyContinue
    exit 1
}

# -- Lanzar herramienta ----------------------------------------
Write-Host ""
Write-Host "  $('-' * 60)" -ForegroundColor DarkGray
Write-Host "  Listo. Iniciando PCFacil..." -ForegroundColor Cyan
Write-Host "  (Los archivos se eliminaran automaticamente al cerrar)" -ForegroundColor DarkGray
Write-Host ""
Start-Sleep -Seconds 2

try {
    & powershell -NoProfile -ExecutionPolicy Bypass -File "$installPath\PCFacil.ps1"
} catch {
    Write-Host "  Error al ejecutar PCFacil: $($_.Exception.Message)" -ForegroundColor Red
}
