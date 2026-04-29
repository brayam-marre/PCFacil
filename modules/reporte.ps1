function Invoke-ReporteFacil {
    Clear-Host
    Show-HeaderFacil

    Write-Host "  GENERANDO TU REPORTE..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Analizando tu computador, por favor espera..." -ForegroundColor DarkGray
    Write-Host ""

    $d         = Get-EstadoPC
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $desktop   = [Environment]::GetFolderPath('Desktop')
    $htmlPath  = "$desktop\Reporte_PC_$timestamp.html"

    # Colores para HTML
    function Get-ColorHtml($score) {
        if ($score -ge 80) { return '#27ae60' }
        elseif ($score -ge 60) { return '#f39c12' }
        else { return '#e74c3c' }
    }
    function Get-ColorStatus($status) {
        switch ($status) {
            'BIEN'    { return '#27ae60' }
            'REGULAR' { return '#f39c12' }
            default   { return '#e74c3c' }
        }
    }

    # Calcular estados para HTML
    $cpuStatus  = if ($d.CPUGen -ge 10) {'BIEN'} elseif ($d.CPUGen -ge 7) {'REGULAR'} else {'REVISAR'}
    $cpuMsg     = if ($d.CPUGen -ge 10) {'Tu procesador es moderno y funciona bien'}
                  elseif ($d.CPUGen -ge 7) {'Tu procesador funciona, pero tiene algunos años de uso'}
                  else {'Tu procesador es antiguo y puede causar lentitud'}

    $ramStatus  = if ($d.RAMGB -ge 16) {'BIEN'} elseif ($d.RAMGB -ge 8) {'REGULAR'} else {'REVISAR'}
    $ramMsg     = if ($d.RAMGB -ge 16) {"Tienes $($d.RAMGB) GB de RAM. Suficiente para cualquier tarea cotidiana"}
                  elseif ($d.RAMGB -ge 8) {"Tienes $($d.RAMGB) GB de RAM. Funciona para uso normal"}
                  else {"Tienes solo $($d.RAMGB) GB de RAM. Es poco y causa lentitud"}

    $diskStatus = if ($d.DiskTipo -match 'NVMe') {'BIEN'} elseif ($d.DiskTipo -match 'SSD') {'BIEN'} else {'REVISAR'}
    $diskMsg    = if ($d.DiskTipo -match 'NVMe') {'Disco NVMe: el más rápido disponible'}
                  elseif ($d.DiskTipo -match 'SSD') {'Disco SSD: rápido, el PC enciende y responde bien'}
                  else {'Disco duro mecánico: lento. Cambiarlo por SSD sería una gran mejora'}

    $espStatus  = if ($d.CUsadoPct -lt 75) {'BIEN'} elseif ($d.CUsadoPct -lt 90) {'REGULAR'} else {'REVISAR'}
    $espMsg     = if ($d.CUsadoPct -lt 75) {"Tienes $($d.CLibreGB) GB libres. Está bien."}
                  elseif ($d.CUsadoPct -lt 90) {"Quedan $($d.CLibreGB) GB libres. Considera liberar espacio."}
                  else {"Solo $($d.CLibreGB) GB libres. El disco está casi lleno."}

    $winStatus  = if ($d.Win11Ok -and $d.IsWin11) {'BIEN'}
                  elseif (-not $d.Win11Ok -and $d.IsWin11) {'REGULAR'}
                  else {'BIEN'}
    $winMsg     = if ($d.Win11Ok -and $d.IsWin11) {'Windows 11 compatible con tu hardware'}
                  elseif (-not $d.Win11Ok -and $d.IsWin11) {'Windows 11 instalado pero hardware no es compatible oficialmente'}
                  else {'Windows 10 es adecuado para tu equipo'}

    $scoreColor = Get-ColorHtml $d.Score
    $veredicto  = if ($d.Score -ge 80) {'Tu PC está en buen estado'}
                  elseif ($d.Score -ge 60) {'Tu PC funciona bien pero tiene margen de mejora'}
                  elseif ($d.Score -ge 40) {'Tu PC necesita algunas mejoras'}
                  else {'Tu PC necesita atención o considerar reemplazo'}

    # Tarjetas de estado
    $cards = @(
        @{ Titulo="Procesador"; Valor=$d.CPU; Status=$cpuStatus; Msg=$cpuMsg }
        @{ Titulo="Memoria RAM"; Valor="$($d.RAMGB) GB $($d.RAMTipo)"; Status=$ramStatus; Msg=$ramMsg }
        @{ Titulo="Disco"; Valor=$d.DiskTipo; Status=$diskStatus; Msg=$diskMsg }
        @{ Titulo="Espacio libre"; Valor="$($d.CLibreGB) GB de $($d.CTotalGB) GB"; Status=$espStatus; Msg=$espMsg }
        @{ Titulo="Sistema operativo"; Valor=$d.SO; Status=$winStatus; Msg=$winMsg }
    )

    $cardHTML = ($cards | ForEach-Object {
        $c = Get-ColorStatus $_.Status
        "<div class='card'>
          <div class='card-title'>$($_.Titulo)</div>
          <div class='card-valor'>$($_.Valor)</div>
          <div class='badge' style='background:$c'>$($_.Status)</div>
          <div class='card-msg'>$($_.Msg)</div>
        </div>"
    }) -join ''

    # Mejoras
    $mejorasHTML = ""
    if ($d.Mejoras.Count -gt 0) {
        $items = ($d.Mejoras | ForEach-Object {
            "<li><span class='mejora-texto'>$($_.Texto)</span><br><span class='mejora-costo'>Costo aproximado: $($_.Costo)</span></li>"
        }) -join ''
        $mejorasHTML = "<div class='seccion'><h2>Que puedes mejorar</h2><ul class='mejoras'>$items</ul></div>"
    }

    # Alternativas SO
    $soAlts = switch -Wildcard ($d.SORec) {
        "*Linux*" { "<li>Linux Mint: gratuito, rapido en PC antiguas, facil de usar</li><li>Lubuntu: para PC con muy pocos recursos</li>" }
        "*10*"    { "<li>Windows 10 LTSC: version más liviana de Windows 10</li><li>Linux Mint: gratuito, fácil de usar, similar a Windows</li>" }
        default   { "" }
    }
    $soHTML = "<div class='seccion'><h2>Sistema operativo recomendado</h2>
      <div class='so-rec'>$($d.SORec)</div>
      <p>$($d.SODetalle)</p>
      $(if($soAlts){"<p><strong>Alternativas:</strong></p><ul>$soAlts</ul>"})</div>"

    # Barra de puntaje
    $barPct = $d.Score
    $barHTML = "<div class='score-bar'><div class='score-fill' style='width:$barPct%;background:$scoreColor'></div></div>"

    $html = @"
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Reporte de mi PC - $($d.NombrePC)</title>
<style>
* { box-sizing:border-box; margin:0; padding:0 }
body { font-family:'Segoe UI',Arial,sans-serif; background:#f5f6fa; color:#2d3436; padding:24px }
.header { background:linear-gradient(135deg,#2d3436,#636e72); color:white; border-radius:12px; padding:28px; margin-bottom:24px }
.header h1 { font-size:1.8em; margin-bottom:6px }
.header p { opacity:.8; font-size:.9em }
.score-box { display:flex; align-items:center; gap:20px; background:white; border-radius:12px; padding:20px; margin-bottom:24px; box-shadow:0 2px 8px rgba(0,0,0,.08) }
.score-num { font-size:3em; font-weight:bold; color:$scoreColor; min-width:90px }
.score-txt { flex:1 }
.score-veredicto { font-size:1.1em; font-weight:bold; color:$scoreColor; margin-bottom:8px }
.score-bar { background:#ecf0f1; border-radius:8px; height:12px; width:100% }
.score-fill { height:12px; border-radius:8px; transition:width .5s }
.cards { display:grid; grid-template-columns:repeat(auto-fit,minmax(240px,1fr)); gap:16px; margin-bottom:24px }
.card { background:white; border-radius:12px; padding:18px; box-shadow:0 2px 8px rgba(0,0,0,.08) }
.card-title { font-size:.8em; color:#636e72; text-transform:uppercase; letter-spacing:.5px; margin-bottom:6px }
.card-valor { font-size:.95em; font-weight:600; color:#2d3436; margin-bottom:8px }
.badge { display:inline-block; padding:3px 12px; border-radius:20px; color:white; font-size:.78em; font-weight:bold; margin-bottom:8px }
.card-msg { font-size:.82em; color:#636e72; line-height:1.4 }
.seccion { background:white; border-radius:12px; padding:20px; margin-bottom:16px; box-shadow:0 2px 8px rgba(0,0,0,.08) }
.seccion h2 { font-size:1em; color:#2d3436; margin-bottom:14px; padding-bottom:8px; border-bottom:2px solid #f5f6fa }
.mejoras { padding-left:18px }
.mejoras li { margin-bottom:12px; line-height:1.4 }
.mejora-texto { color:#2d3436; font-size:.9em }
.mejora-costo { color:#27ae60; font-size:.82em; font-weight:bold }
.so-rec { font-size:1.2em; font-weight:bold; color:#2980b9; margin-bottom:8px }
p { font-size:.88em; color:#636e72; line-height:1.5; margin-bottom:8px }
ul { padding-left:18px; font-size:.88em; color:#636e72 }
ul li { margin-bottom:4px }
.footer { text-align:center; color:#b2bec3; font-size:.78em; margin-top:20px }
.tag { background:#dfe6e9; border-radius:4px; padding:2px 8px; font-size:.8em; margin-right:6px }
</style>
</head>
<body>

<div class="header">
  <h1>Reporte de mi PC</h1>
  <p>
    <span class="tag">$($d.NombrePC)</span>
    <span class="tag">$(Get-Date -Format 'dd/MM/yyyy HH:mm')</span>
    <span class="tag">$($d.SO)</span>
  </p>
</div>

<div class="score-box">
  <div class="score-num">$($d.Score)<span style="font-size:.4em;color:#b2bec3">/100</span></div>
  <div class="score-txt">
    <div class="score-veredicto">$veredicto</div>
    $barHTML
  </div>
</div>

<div class="cards">$cardHTML</div>

$mejorasHTML

$soHTML

<div class="footer">Reporte generado por PCFacil &nbsp;|&nbsp; $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')</div>
</body>
</html>
"@

    $html | Out-File -FilePath $htmlPath -Encoding UTF8
    Write-Host "  [OK] " -ForegroundColor Green -NoNewline
    Write-Host "Reporte guardado en el Escritorio: " -NoNewline
    Write-Host "Reporte_PC_$timestamp.html" -ForegroundColor Cyan
    Write-Host ""

    $abrir = Read-Host "  ¿Quieres abrir el reporte ahora? (s/n)"
    if ($abrir -ieq 's') { Start-Process $htmlPath }
    Write-Host ""
}
