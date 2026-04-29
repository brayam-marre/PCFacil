#Requires -Version 5.1

$ErrorActionPreference = 'SilentlyContinue'
$ProgressPreference    = 'SilentlyContinue'
chcp 65001 | Out-Null
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:InstallPath = $PSScriptRoot
$script:Version     = "1.0.0"

# -- Elevacion de privilegios ----------------------------------
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host ""
    Write-Host "  Se necesitan permisos de administrador. Abriendo..." -ForegroundColor Yellow
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

# -- Carga de modulos ------------------------------------------
foreach ($mod in @('diagnostico','limpieza','reporte')) {
    $path = "$script:InstallPath\modules\$mod.ps1"
    if (Test-Path $path) { . $path }
}

# -- Cabecera --------------------------------------------------
function Show-HeaderFacil {
    Clear-Host
    Write-Host ""
    Write-Host "  ==========================================" -ForegroundColor Cyan
    Write-Host "         PC FACIL  -  Cuida tu computador   " -ForegroundColor Cyan
    Write-Host "  ==========================================" -ForegroundColor Cyan
    Write-Host "  v$script:Version  |  $env:COMPUTERNAME  |  $(Get-Date -Format 'dd/MM/yyyy HH:mm')" -ForegroundColor DarkGray
    Write-Host ""
}

# -- Menu ------------------------------------------------------
function Show-MenuFacil {
    Show-HeaderFacil
    Write-Host "¿Que quieres hacer hoy?" -ForegroundColor White
    Write-Host ""
    Write-Host "  [1]" -ForegroundColor Cyan -NoNewline
    Write-Host "   Ver como esta mi PC"
    Write-Host ""
    Write-Host "  [2]" -ForegroundColor Cyan -NoNewline
    Write-Host "   Limpiar mi PC  (liberar espacio y velocidad)"
    Write-Host ""
    Write-Host "  [3]" -ForegroundColor Cyan -NoNewline
    Write-Host "   Generar reporte de mi PC  (que puedo mejorar)"
    Write-Host ""
    Write-Host "  [4]" -ForegroundColor Green -NoNewline
    Write-Host "   Contactar al tecnico  (soporte presencial y remoto)"
    Write-Host ""
    Write-Host "  [0]" -ForegroundColor DarkGray -NoNewline
    Write-Host "   Salir"
    Write-Host ""
    Write-Host "  ===========================================" -ForegroundColor DarkGray
    Write-Host ""
}

function Show-Contacto {
    Show-HeaderFacil
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "  |          SERVICIO DE SOPORTE TECNICO             |" -ForegroundColor Cyan
    Write-Host "  +--------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Brayam Marre Provoste" -ForegroundColor White
    Write-Host "  Tecnico en Soporte TI y Programacion" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  SERVICIOS                                       |" -ForegroundColor Yellow
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Soporte tecnico y reparacion de computadores" -ForegroundColor White
    Write-Host "    Instalacion y configuracion de software" -ForegroundColor White
    Write-Host "    Programacion y automatizacion a medida" -ForegroundColor White
    Write-Host "    Limpieza, mantenimiento y optimizacion de PC" -ForegroundColor White
    Write-Host "    Asesoria y diagnostico de equipos" -ForegroundColor White
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  CONTACTO                                        |" -ForegroundColor Yellow
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Telefono / WhatsApp : " -NoNewline; Write-Host "+56 9 7991 0642" -ForegroundColor Cyan
    Write-Host "    Correo electronico  : " -NoNewline; Write-Host "brayam.provoste@hotmail.com" -ForegroundColor Cyan
    Write-Host "    LinkedIn            : " -NoNewline; Write-Host "linkedin.com/in/brayam-marre" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host "  |  COBERTURA                                       |" -ForegroundColor Yellow
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "    Presencial : " -NoNewline; Write-Host "Yumbel y Yumbel Estacion" -ForegroundColor Green
    Write-Host "    Remoto     : " -NoNewline; Write-Host "Todo Chile (via TeamViewer, AnyDesk o similar)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  +--------------------------------------------------+" -ForegroundColor DarkGray
    Write-Host ""
}

function Pause-Facil {
    Write-Host ""
    Write-Host "  Presiona Enter para volver al menu..." -ForegroundColor DarkGray
    Read-Host | Out-Null
}

function Invoke-SalirFacil {
    Write-Host ""
    Write-Host "  Cerrando PCFacil..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 1
    # Solo auto-eliminar si corre desde instalacion temporal en AppData
    if ($script:InstallPath -like "*$env:LOCALAPPDATA*") {
        $cmd = "ping 127.0.0.1 -n 4 > nul & rd /s /q `"$script:InstallPath`""
        Start-Process cmd -ArgumentList "/c $cmd" -WindowStyle Hidden
    }
}

# -- Bucle principal -------------------------------------------
while ($true) {
    Show-MenuFacil
    $op = Read-Host "  Escribe el numero de tu opcion"

    switch ($op.Trim()) {
        '1' { Invoke-DiagnosticoFacil; Pause-Facil }
        '2' { Invoke-LimpiezaFacil;    Pause-Facil }
        '3' { Invoke-ReporteFacil;     Pause-Facil }
        '4' { Show-Contacto;          Pause-Facil }
        '0' { Invoke-SalirFacil; exit }
        default {
            Write-Host ""
            Write-Host "  Opcion no valida. Escribe 1, 2, 3, 4 o 0." -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
    }
}
