function Invoke-LimpiezaFacil {
    Clear-Host
    Show-HeaderFacil

    Write-Host "  LIMPIAR TU COMPUTADOR" -ForegroundColor White
    Write-Host "  $('-' * 65)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  Este proceso eliminará archivos basura que ya no necesita tu PC." -ForegroundColor DarkGray
    Write-Host "  No se borrarán tus documentos, fotos ni programas instalados." -ForegroundColor DarkGray
    Write-Host ""

    $ok = Read-Host "  ¿Quieres continuar con la limpieza? (s/n)"
    if ($ok -ine 's') { return }

    Write-Host ""
    $totalMB = 0

    function Limpiar-Carpeta {
        param([string]$Ruta, [string]$Descripcion)
        if (-not (Test-Path $Ruta)) { return 0 }
        $antes = (Get-ChildItem $Ruta -Recurse -Force -ErrorAction SilentlyContinue |
                  Measure-Object -Property Length -Sum).Sum
        Remove-Item "$Ruta\*" -Recurse -Force -ErrorAction SilentlyContinue
        $liberado = if ($antes) { [math]::Round($antes / 1MB, 1) } else { 0 }
        if ($liberado -gt 0) {
            Write-Host "  [OK] " -ForegroundColor Green -NoNewline
            Write-Host "$Descripcion" -NoNewline
            Write-Host "  ($liberado MB liberados)" -ForegroundColor Cyan
        } else {
            Write-Host "  [OK] " -ForegroundColor Green -NoNewline
            Write-Host "$Descripcion (ya estaba limpio)"
        }
        return $liberado
    }

    Write-Host "  Limpiando archivos temporales..." -ForegroundColor Yellow
    Write-Host ""
    $totalMB += Limpiar-Carpeta $env:TEMP                "Archivos temporales de tu usuario"
    $totalMB += Limpiar-Carpeta "C:\Windows\Temp"        "Archivos temporales del sistema"
    $totalMB += Limpiar-Carpeta "C:\Windows\Prefetch"    "Archivos de precarga de Windows"
    $totalMB += Limpiar-Carpeta "$env:LOCALAPPDATA\Temp" "Archivos temporales adicionales"
    $totalMB += Limpiar-Carpeta "$env:LOCALAPPDATA\Microsoft\Windows\INetCache" "Archivos de internet guardados"
    $totalMB += Limpiar-Carpeta "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache" "Caché de Google Chrome"
    $ffProfiles = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    if (Test-Path $ffProfiles) {
        Get-ChildItem $ffProfiles -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $totalMB += Limpiar-Carpeta "$($_.FullName)\cache2" "Caché de Mozilla Firefox"
        }
    }

    # Papelera
    Write-Host ""
    Write-Host "  Vaciando la Papelera de reciclaje..." -ForegroundColor Yellow
    Write-Host ""
    try {
        $shell   = New-Object -ComObject Shell.Application
        $recycle = $shell.Namespace(0xA)
        $rSize   = ($recycle.Items() | ForEach-Object { $_.Size } | Measure-Object -Sum).Sum
        Clear-RecycleBin -Force -ErrorAction SilentlyContinue
        $rMB = if ($rSize) { [math]::Round($rSize / 1MB, 1) } else { 0 }
        $totalMB += $rMB
        Write-Host "  [OK] " -ForegroundColor Green -NoNewline
        if ($rMB -gt 0) {
            Write-Host "Papelera vaciada  ($rMB MB liberados)" -ForegroundColor Cyan
        } else {
            Write-Host "La Papelera ya estaba vacía"
        }
    } catch {
        Write-Host "  [--] No se pudo vaciar la Papelera" -ForegroundColor DarkGray
    }

    # Windows Update cache
    Write-Host ""
    Write-Host "  Limpiando archivos de actualizaciones de Windows..." -ForegroundColor Yellow
    Write-Host ""
    Stop-Service -Name wuauserv, bits -Force -ErrorAction SilentlyContinue
    $totalMB += Limpiar-Carpeta "C:\Windows\SoftwareDistribution\Download" "Actualizaciones de Windows ya instaladas"
    Start-Service -Name wuauserv, bits -ErrorAction SilentlyContinue

    # DNS flush
    ipconfig /flushdns 2>&1 | Out-Null
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host "Conexión de internet optimizada"

    # Logs viejos
    Write-Host ""
    Write-Host "  Limpiando registros de errores antiguos..." -ForegroundColor Yellow
    Write-Host ""
    @("C:\Windows\Logs", "$env:LOCALAPPDATA\CrashDumps") | ForEach-Object {
        if (Test-Path $_) {
            $viejos = Get-ChildItem $_ -Recurse -File -ErrorAction SilentlyContinue |
                      Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
            $sz = ($viejos | Measure-Object -Property Length -Sum).Sum
            $viejos | Remove-Item -Force -ErrorAction SilentlyContinue
            $mb = if ($sz) { [math]::Round($sz / 1MB, 1) } else { 0 }
            $totalMB += $mb
            if ($mb -gt 0) {
                Write-Host "  [OK] " -ForegroundColor Green -NoNewline
                Write-Host "Registros de errores antiguos eliminados  ($mb MB)" -ForegroundColor Cyan
            }
        }
    }

    # .NET GC
    [System.GC]::Collect()

    Write-Host ""
    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host ""
    $totalGB = [math]::Round($totalMB / 1024, 2)
    if ($totalMB -ge 1024) {
        Write-Host "  Limpieza completada. Se liberaron $totalGB GB en tu PC." -ForegroundColor Green
    } else {
        Write-Host "  Limpieza completada. Se liberaron $([math]::Round($totalMB, 0)) MB en tu PC." -ForegroundColor Green
    }
    Write-Host ""
    Write-Host "  Tu PC debería ir un poco más rápido ahora." -ForegroundColor DarkGray
    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host ""
}
