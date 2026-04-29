function Get-EstadoPC {
    $os      = Get-CimInstance Win32_OperatingSystem
    $cs      = Get-CimInstance Win32_ComputerSystem
    $cpu     = Get-CimInstance Win32_Processor
    $ramArr  = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction SilentlyContinue
    $ramMods = Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue
    $disks   = Get-PhysicalDisk -ErrorAction SilentlyContinue
    $tpm     = Get-WmiObject -Namespace "root\cimv2\security\microsofttpm" -Class Win32_Tpm -ErrorAction SilentlyContinue
    $sb      = Confirm-SecureBootUEFI -ErrorAction SilentlyContinue

    $ramGB   = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $usedPct = [math]::Round((($ramGB - $freeGB) / $ramGB) * 100, 0)
    $cpuName = $cpu.Name.Trim()
    $osName  = $os.Caption

    # Detectar tipo de disco principal
    $diskTipo = "Desconocido"
    $hasNVMe  = $disks | Where-Object { $_.BusType -eq 'NVMe' }
    $hasSSD   = $disks | Where-Object { $_.MediaType -eq 'SSD' -and $_.BusType -ne 'NVMe' }
    $hasHDD   = $disks | Where-Object { $_.MediaType -eq 'HDD' }
    if ($hasNVMe) { $diskTipo = "NVMe (muy rápido)" }
    elseif ($hasSSD) { $diskTipo = "SSD (rápido)" }
    elseif ($hasHDD) { $diskTipo = "Disco duro mecánico (lento)" }

    # Espacio en disco C:
    $cDrive    = Get-PSDrive C -ErrorAction SilentlyContinue
    $cTotalGB  = if ($cDrive) { [math]::Round(($cDrive.Used + $cDrive.Free) / 1GB, 1) } else { 0 }
    $cLibreGB  = if ($cDrive) { [math]::Round($cDrive.Free / 1GB, 1) } else { 0 }
    $cUsadoPct = if ($cTotalGB -gt 0) { [math]::Round(($cDrive.Used / ($cDrive.Used + $cDrive.Free)) * 100, 0) } else { 0 }

    # Detectar generación CPU
    $cpuGen = 0; $cpuBrand = ""
    if ($cpuName -match 'Intel') {
        $cpuBrand = "Intel"
        if    ($cpuName -match '12th|13th|14th')              { $cpuGen = 13 }
        elseif($cpuName -match '11th')                         { $cpuGen = 11 }
        elseif($cpuName -match '10th')                         { $cpuGen = 10 }
        elseif($cpuName -match 'Core.*i[3579]-(\d{2})\d{3}')  { $cpuGen = [int]$Matches[1] }
        elseif($cpuName -match 'Core.*i[3579]-(\d)\d{3}')     { $cpuGen = [int]$Matches[1] }
        elseif($cpuName -match 'Core 2|Pentium|Celeron|Atom')  { $cpuGen = 2 }
    } elseif ($cpuName -match 'AMD') {
        $cpuBrand = "AMD"
        if    ($cpuName -match 'Ryzen.*7[0-9]{3}')    { $cpuGen = 12 }
        elseif($cpuName -match 'Ryzen.*[56][0-9]{3}') { $cpuGen = 10 }
        elseif($cpuName -match 'Ryzen.*[34][0-9]{3}') { $cpuGen = 8 }
        elseif($cpuName -match 'Ryzen.*[12][0-9]{3}') { $cpuGen = 7 }
        elseif($cpuName -match 'FX|Phenom|Athlon')     { $cpuGen = 3 }
    }

    # Tipo RAM
    $ramTipo = "Desconocida"
    if ($ramMods) {
        $t = ($ramMods | Select-Object -First 1).MemoryType
        $ramTipo = switch ($t) { 26{'DDR4'}; 34{'DDR5'}; 24{'DDR3'}; 21{'DDR2'}; default{'Desconocida'} }
    }

    # Slots RAM
    $slotsLibres = 0
    if ($ramArr) { $slotsLibres = $ramArr.MemoryDevices - ($ramMods | Measure-Object).Count }

    # Windows 11 ready
    $tpmOk   = $tpm -and $tpm.IsEnabled_InitialValue
    $sbOk    = $sb -eq $true
    $win11Ok = $tpmOk -and $sbOk -and ($cpuGen -ge 8)
    $isWin11 = $osName -match 'Windows 11'

    # Puntuación interna
    $score = 0
    if ($cpuGen -ge 10) { $score += 30 } elseif ($cpuGen -ge 7) { $score += 20 } elseif ($cpuGen -ge 4) { $score += 10 }
    if ($ramGB -ge 16) { $score += 25 } elseif ($ramGB -ge 8) { $score += 18 } elseif ($ramGB -ge 4) { $score += 8 }
    if ($hasNVMe) { $score += 25 } elseif ($hasSSD) { $score += 20 } elseif ($hasHDD -and $disks.Count -gt 1) { $score += 12 } elseif ($hasHDD) { $score += 5 } else { $score += 15 }
    if ($win11Ok -and $isWin11) { $score += 20 } elseif ($win11Ok) { $score += 18 } elseif (-not $win11Ok -and $isWin11) { $score += 5 } else { $score += 15 }
    $pct = [math]::Round($score / 100 * 100, 0)

    # Mejoras
    $mejoras = @()
    if ($ramGB -lt 8)    { $mejoras += @{ Texto = "Agregar más memoria RAM (actualmente tienes $ramGB GB, lo ideal es 16 GB)"; Costo = "`$15.000 - `$40.000 CLP" } }
    elseif ($ramGB -lt 16) { $mejoras += @{ Texto = "Ampliar la RAM de $ramGB GB a 16 GB para mayor velocidad"; Costo = "`$25.000 - `$50.000 CLP" } }
    if ($hasHDD -and -not $hasSSD -and -not $hasNVMe) { $mejoras += @{ Texto = "Cambiar el disco duro por un SSD (el equipo seria 5 veces más rapido al encender y abrir programas)"; Costo = "`$25.000 - `$55.000 CLP" } }
    if (-not $win11Ok -and $isWin11) { $mejoras += @{ Texto = "Tu computador tiene Windows 11 pero el hardware no es compatible oficialmente. Puede tener problemas con actualizaciones futuras"; Costo = "Sin costo (informacion)" } }
    if ($cUsadoPct -gt 85) { $mejoras += @{ Texto = "El disco C: está casi lleno ($cUsadoPct%). Libera espacio o agrega almacenamiento"; Costo = "`$20.000 - `$40.000 CLP" } }

    # SO recomendado
    $soRec = ""; $soDetalle = ""
    if ($pct -ge 75 -and $win11Ok) { $soRec = "Windows 11"; $soDetalle = "Tu PC es compatible y funciona bien con Windows 11." }
    elseif ($pct -ge 55)           { $soRec = "Windows 10";  $soDetalle = "Windows 10 es la mejor opción para tu equipo. Windows 11 puede ser inestable." }
    elseif ($pct -ge 35)           { $soRec = "Windows 10 o Linux Mint"; $soDetalle = "Tu PC es antigua. Windows 10 liviano o Linux Mint son la mejor opción." }
    else                            { $soRec = "Linux Mint o Lubuntu"; $soDetalle = "Tu PC es muy antigua para Windows 10/11. Linux funciona mucho mejor en equipos viejos y es gratuito." }

    return @{
        NombrePC    = $env:COMPUTERNAME
        SO          = $osName
        CPU         = $cpuName
        CPUGen      = $cpuGen
        RAMGB       = $ramGB
        RAMTipo     = $ramTipo
        RAMUsadaPct = $usedPct
        SlotsLibres = $slotsLibres
        DiskTipo    = $diskTipo
        CLibreGB    = $cLibreGB
        CTotalGB    = $cTotalGB
        CUsadoPct   = $cUsadoPct
        TPMOk       = $tpmOk
        SecureBoot  = $sbOk
        Win11Ok     = $win11Ok
        IsWin11     = $isWin11
        Score       = $pct
        Mejoras     = $mejoras
        SORec       = $soRec
        SODetalle   = $soDetalle
    }
}

function Invoke-DiagnosticoFacil {
    Clear-Host
    Show-HeaderFacil

    Write-Host "  Revisando tu computador, por favor espera..." -ForegroundColor DarkGray
    Write-Host ""
    $d = Get-EstadoPC

    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host "  ESTADO DE TU COMPUTADOR" -ForegroundColor White
    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host ""

    # -- Procesador --
    Write-Host "  Tu procesador (CPU)" -ForegroundColor Yellow
    $cpuColor = if ($d.CPUGen -ge 10) {'Green'} elseif ($d.CPUGen -ge 7) {'Yellow'} else {'Red'}
    $cpuMsg   = if ($d.CPUGen -ge 10) {'Esta en buen estado para las tareas del día a día'}
                elseif ($d.CPUGen -ge 7) {'Funciona bien para uso normal, pero tiene algunos años de uso. Puede ir lento en tareas pesadas'}
                elseif ($d.CPUGen -ge 4) {'Es antiguo. Puede causar lentitud al usar varios programas a la vez'}
                else {'Muy antiguo. Es probable que el equipo vaya lento constantemente'}
    Write-Host "  $($d.CPU)" -ForegroundColor DarkGray
    Write-Host "  Estado: " -NoNewline; Write-Host $cpuMsg -ForegroundColor $cpuColor
    Write-Host ""

    # -- RAM --
    Write-Host "  Tu memoria RAM" -ForegroundColor Yellow
    $ramColor = if ($d.RAMGB -ge 16) {'Green'} elseif ($d.RAMGB -ge 8) {'Yellow'} else {'Red'}
    $ramMsg   = if ($d.RAMGB -ge 16) {"Tienes $($d.RAMGB) GB de RAM. Es suficiente para la mayoría de tareas"}
                elseif ($d.RAMGB -ge 8) {"Tienes $($d.RAMGB) GB de RAM. Suficiente para uso normal, pero puede ir lento con muchas cosas abiertas"}
                else {"Tienes solo $($d.RAMGB) GB de RAM. Es poco y puede causar mucha lentitud"}
    Write-Host "  Estado: " -NoNewline; Write-Host $ramMsg -ForegroundColor $ramColor
    if ($d.SlotsLibres -gt 0) {
        Write-Host "  Tienes $($d.SlotsLibres) espacio(s) libre(s) para agregar más RAM sin quitar la actual." -ForegroundColor Green
    } else {
        Write-Host "  Los espacios de RAM estan llenos. Habría que reemplazar los modulos para ampliar." -ForegroundColor DarkGray
    }
    Write-Host ""

    # -- Disco --
    Write-Host "  Tu disco (almacenamiento)" -ForegroundColor Yellow
    $diskColor = if ($d.DiskTipo -match 'NVMe|SSD') {'Green'} else {'Yellow'}
    $diskMsg   = if ($d.DiskTipo -match 'NVMe') {"Tienes un disco NVMe, el más rápido que existe. Muy bien."}
                 elseif ($d.DiskTipo -match 'SSD') {"Tienes un disco SSD. Tu PC enciende y abre programas rápido."}
                 else {"Tienes un disco duro mecánico (HDD). Es lento. Cambiarlo a SSD sería la mejora más notoria."}
    Write-Host "  Tipo de disco: " -NoNewline; Write-Host $d.DiskTipo -ForegroundColor $diskColor
    Write-Host "  $diskMsg" -ForegroundColor $diskColor
    Write-Host ""

    # -- Espacio disponible --
    Write-Host "  Espacio disponible en tu PC" -ForegroundColor Yellow
    $espColor = if ($d.CUsadoPct -lt 75) {'Green'} elseif ($d.CUsadoPct -lt 90) {'Yellow'} else {'Red'}
    $espMsg   = if ($d.CUsadoPct -lt 75) {"Tienes $($d.CLibreGB) GB libres de $($d.CTotalGB) GB. Está bien."}
                elseif ($d.CUsadoPct -lt 90) {"Quedan solo $($d.CLibreGB) GB libres de $($d.CTotalGB) GB. Considera liberar espacio."}
                else {"El disco está casi lleno. Solo $($d.CLibreGB) GB libres de $($d.CTotalGB) GB. Esto puede causar lentitud."}
    Write-Host "  " -NoNewline; Write-Host $espMsg -ForegroundColor $espColor
    Write-Host ""

    # -- Windows --
    Write-Host "  Tu sistema operativo (Windows)" -ForegroundColor Yellow
    Write-Host "  Tienes: $($d.SO)" -ForegroundColor DarkGray
    if ($d.Win11Ok -and $d.IsWin11) {
        Write-Host "  Tu computador es compatible con Windows 11. Todo está correcto." -ForegroundColor Green
    } elseif (-not $d.Win11Ok -and $d.IsWin11) {
        Write-Host "  Tienes Windows 11 pero tu hardware no es oficialmente compatible." -ForegroundColor Yellow
        Write-Host "  Puede funcionar ahora, pero podrías tener problemas con futuras actualizaciones." -ForegroundColor DarkGray
    } else {
        Write-Host "  Windows 10 es adecuado para tu equipo." -ForegroundColor Green
    }
    Write-Host ""

    # -- Puntaje --
    $vColor = if ($d.Score -ge 80) {'Green'} elseif ($d.Score -ge 60) {'Yellow'} else {'Red'}
    $vTexto = if ($d.Score -ge 80) {'Tu PC está en buen estado'}
               elseif ($d.Score -ge 60) {'Tu PC funciona bien pero tiene margen de mejora'}
               elseif ($d.Score -ge 40) {'Tu PC está envejeciendo, algunas mejoras ayudarían mucho'}
               else {'Tu PC necesita atención o considerar reemplazo'}

    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host "  RESULTADO GENERAL" -ForegroundColor White
    Write-Host ""
    $bar = ('#' * [math]::Round($d.Score / 5, 0)).PadRight(20, '-')
    Write-Host "  [$bar] $($d.Score) / 100" -ForegroundColor Cyan
    Write-Host "  $vTexto" -ForegroundColor $vColor
    Write-Host "  $('=' * 65)" -ForegroundColor DarkGray
    Write-Host ""

    if ($d.Mejoras.Count -gt 0) {
        Write-Host "  QUÉ PODRÍAS MEJORAR:" -ForegroundColor Yellow
        $d.Mejoras | ForEach-Object {
            Write-Host "  -> $($_.Texto)" -ForegroundColor White
            Write-Host "     Costo aproximado: $($_.Costo)" -ForegroundColor DarkGray
        }
        Write-Host ""
    }

    Write-Host "  SISTEMA OPERATIVO RECOMENDADO:" -ForegroundColor Yellow
    Write-Host "  $($d.SORec)" -ForegroundColor Cyan
    Write-Host "  $($d.SODetalle)" -ForegroundColor DarkGray
    Write-Host ""
}
