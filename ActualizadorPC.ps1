param(
    [ValidateSet('gui','scan','update')][string]$Mode = 'gui',
    [string]$StateDir = '',
    [string]$SelectionFile = ''
)

$ErrorActionPreference = 'Stop'

function Save-Json([string]$Path, $Value) {
    $tmp = "$Path.tmp"
    ConvertTo-Json -InputObject $Value -Depth 6 | Set-Content -LiteralPath $tmp -Encoding UTF8
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Get-PendingWindowsUpdates {
    $session = New-Object -ComObject Microsoft.Update.Session
    $searcher = $session.CreateUpdateSearcher()
    $result = $searcher.Search('IsInstalled=0 and IsHidden=0')
    $items = @()
    foreach ($update in $result.Updates) {
        $items += [pscustomobject]@{
            Type = 'Windows'
            Name = $update.Title
            Id = $update.UpdateIdentity.UpdateID
            Current = ''
            Available = ($update.KBArticleIDs -join ', ')
        }
    }
    return $items
}

function Get-WingetUpdates {
    $lines = @(& winget upgrade --accept-source-agreements 2>&1 | ForEach-Object { $_.ToString() })
    $items = @()
    foreach ($line in $lines) {
        if ($line -notmatch '^\s*(.+?)\s+([A-Za-z][A-Za-z0-9_.+-]*\.[A-Za-z0-9_.+-]+)\s+((?:<\s*)?\d[^\s]*(?:\s+\([^)]+\))?)\s+(\d[^\s]*(?:\s+\([^)]+\))?)\s+(winget|msstore)\s*$') { continue }
        $items += [pscustomobject]@{
            Type = 'Programa'
            Name = $Matches[1].Trim()
            Id = $Matches[2].Trim()
            Current = $Matches[3].Trim()
            Available = $Matches[4].Trim()
        }
    }
    return $items
}

function Run-Scan {
    $items = @([pscustomobject]@{ Type='Defender'; Name='Definiciones de Microsoft Defender'; Id='__DEFENDER__'; Current=''; Available='Buscar la más reciente' })
    $warnings = @()
    try { $items += @(Get-PendingWindowsUpdates) } catch { $warnings += "Windows Update: $($_.Exception.Message)" }
    try { $items += @(Get-WingetUpdates) } catch { $warnings += "Programas: $($_.Exception.Message)" }
    Save-Json (Join-Path $StateDir 'scan.json') @{ Items = @($items); Warnings = @($warnings) }
}

function Run-Update {
    $chosen = @(Get-Content -LiteralPath $SelectionFile -Raw | ConvertFrom-Json)
    $results = @()
    foreach ($item in $chosen) {
        $status = 'Correcto'
        $details = ''
        $reboot = $false
        try {
            if ($item.Type -eq 'Defender') {
                Update-MpSignature
                $details = 'Definiciones actualizadas o ya al día.'
            } elseif ($item.Type -eq 'Programa') {
                $output = @(& winget upgrade --id $item.Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity 2>&1 | ForEach-Object { $_.ToString() })
                $details = ($output -join "`n").Trim()
                if ($LASTEXITCODE -ne 0) { $status = 'Pendiente' }
            } elseif ($item.Type -eq 'Windows') {
                $session = New-Object -ComObject Microsoft.Update.Session
                $found = $session.CreateUpdateSearcher().Search('IsInstalled=0 and IsHidden=0')
                $updates = New-Object -ComObject Microsoft.Update.UpdateColl
                foreach ($update in $found.Updates) {
                    if ($update.UpdateIdentity.UpdateID -eq $item.Id) {
                        if (-not $update.EulaAccepted) { $update.AcceptEula() }
                        [void]$updates.Add($update)
                    }
                }
                if ($updates.Count -eq 0) { $details = 'Ya no aparece como pendiente.' }
                else {
                    $downloader = $session.CreateUpdateDownloader()
                    $downloader.Updates = $updates
                    $download = $downloader.Download()
                    if ($download.ResultCode -ne 2) { throw "Descarga incompleta (código $($download.ResultCode))." }
                    $installer = $session.CreateUpdateInstaller()
                    $installer.Updates = $updates
                    $installed = $installer.Install()
                    $reboot = [bool]$installed.RebootRequired
                    $details = "Resultado de Windows Update: $($installed.ResultCode)."
                    if ($installed.ResultCode -ne 2) { $status = 'Pendiente' }
                }
            }
        } catch {
            $status = 'Pendiente'
            $details = $_.Exception.Message
        }
        $results += [pscustomobject]@{ Name=$item.Name; Status=$status; Details=$details; Reboot=$reboot }
        Save-Json (Join-Path $StateDir 'progress.json') @{ Results=@($results); Total=$chosen.Count }
    }
    Save-Json (Join-Path $StateDir 'result.json') @{ Results=@($results); Total=$chosen.Count }
}

if ($Mode -ne 'gui') {
    try {
        if ($Mode -eq 'scan') { Run-Scan } else { Run-Update }
    } catch {
        Save-Json (Join-Path $StateDir 'error.json') @{ Error=$_.Exception.Message }
        exit 1
    }
    exit 0
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Actualizador de PC'
$form.Size = New-Object System.Drawing.Size(1000, 630)
$form.StartPosition = 'CenterScreen'
$form.MinimumSize = New-Object System.Drawing.Size(800, 500)
$font = New-Object System.Drawing.Font('Segoe UI', 9)
$form.Font = $font

$scanButton = New-Object System.Windows.Forms.Button
$scanButton.Text = 'Buscar actualizaciones'
$scanButton.SetBounds(16, 15, 185, 34)
$form.Controls.Add($scanButton)
$updateButton = New-Object System.Windows.Forms.Button
$updateButton.Text = 'Instalar seleccionadas'
$updateButton.SetBounds(211, 15, 185, 34)
$updateButton.Enabled = $false
$form.Controls.Add($updateButton)
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = 'Listo para buscar.'
$statusLabel.SetBounds(412, 23, 550, 24)
$form.Controls.Add($statusLabel)

$grid = New-Object System.Windows.Forms.DataGridView
$grid.SetBounds(16, 61, 950, 345)
$grid.Anchor = 'Top,Left,Right,Bottom'
$grid.AllowUserToAddRows = $false
$grid.AllowUserToDeleteRows = $false
$grid.RowHeadersVisible = $false
$grid.MultiSelect = $false
$grid.SelectionMode = 'FullRowSelect'
$grid.AutoSizeColumnsMode = 'Fill'
[void]$grid.Columns.Add((New-Object System.Windows.Forms.DataGridViewCheckBoxColumn -Property @{Name='Selected'; HeaderText='Elegir'; FillWeight=35}))
[void]$grid.Columns.Add('Type','Tipo')
[void]$grid.Columns.Add('Name','Actualización')
[void]$grid.Columns.Add('Current','Instalada')
[void]$grid.Columns.Add('Available','Disponible')
$grid.Columns['Type'].FillWeight = 65
$grid.Columns['Name'].FillWeight = 290
$grid.Columns['Current'].FillWeight = 90
$grid.Columns['Available'].FillWeight = 100
$form.Controls.Add($grid)

$log = New-Object System.Windows.Forms.TextBox
$log.SetBounds(16, 420, 950, 155)
$log.Anchor = 'Left,Right,Bottom'
$log.Multiline = $true
$log.ReadOnly = $true
$log.ScrollBars = 'Vertical'
$log.Text = "Marca las actualizaciones que quieras instalar. No se desinstalará ningún programa automáticamente.`r`n"
$form.Controls.Add($log)

$script:items = @()
$script:process = $null
$script:stateDir = ''
$script:operation = ''
$script:seenResults = 0

function Add-Log([string]$message) {
    $log.AppendText("$message`r`n")
}
function Start-Worker([string]$operation, [string]$selection = '') {
    $script:stateDir = Join-Path $env:LOCALAPPDATA ('ActualizadorPC\' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Force -Path $script:stateDir)
    $script:operation = $operation
    $script:seenResults = 0
    if ($selection) { Set-Content -LiteralPath (Join-Path $script:stateDir 'selection.json') -Value $selection -Encoding UTF8 }
    $args = '-NoProfile -ExecutionPolicy Bypass -File "{0}" -Mode {1} -StateDir "{2}"' -f $PSCommandPath,$operation,$script:stateDir
    if ($selection) { $args += ' -SelectionFile "' + (Join-Path $script:stateDir 'selection.json') + '"' }
    $script:process = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -PassThru -WindowStyle Hidden
    $scanButton.Enabled = $false
    $updateButton.Enabled = $false
    $statusLabel.Text = if ($operation -eq 'scan') { 'Buscando...' } else { 'Instalando...' }
    $timer.Start()
}

$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 700
$timer.Add_Tick({
    if (-not $script:process) { return }
    if ($script:operation -eq 'update') {
        $progressPath = Join-Path $script:stateDir 'progress.json'
        if (Test-Path $progressPath) {
            try {
                $progress = Get-Content -LiteralPath $progressPath -Raw | ConvertFrom-Json
                $results = @($progress.Results)
                if ($results.Count -gt $script:seenResults) {
                    for ($i=$script:seenResults; $i -lt $results.Count; $i++) {
                        Add-Log ("{0}: {1}. {2}" -f $results[$i].Status,$results[$i].Name,$results[$i].Details)
                    }
                    $script:seenResults = $results.Count
                }
                $statusLabel.Text = "Procesadas $($results.Count) de $($progress.Total)"
            } catch { }
        }
    }
    $script:process.Refresh()
    if (-not $script:process.HasExited) { return }
    $timer.Stop()
    $errorPath = Join-Path $script:stateDir 'error.json'
    if (Test-Path $errorPath) {
        $message = (Get-Content -LiteralPath $errorPath -Raw | ConvertFrom-Json).Error
        Add-Log "Error: $message"
        $statusLabel.Text = 'No se pudo completar.'
    } elseif ($script:operation -eq 'scan') {
        $path = Join-Path $script:stateDir 'scan.json'
        if (Test-Path $path) {
            $data = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            $script:items = @($data.Items)
            $grid.Rows.Clear()
            foreach ($item in $script:items) {
                $index = $grid.Rows.Add()
                $grid.Rows[$index].Cells['Selected'].Value = ($item.Type -eq 'Defender')
                $grid.Rows[$index].Cells['Type'].Value = $item.Type
                $grid.Rows[$index].Cells['Name'].Value = $item.Name
                $grid.Rows[$index].Cells['Current'].Value = $item.Current
                $grid.Rows[$index].Cells['Available'].Value = $item.Available
            }
            $updateButton.Enabled = $true
            $statusLabel.Text = "$($script:items.Count) elementos encontrados."
            Add-Log "Búsqueda terminada: $($script:items.Count) elementos."
            foreach ($warning in @($data.Warnings)) { if ($warning) { Add-Log "Aviso: $warning" } }
        } else { Add-Log 'La búsqueda terminó sin resultados legibles.' }
    } else {
        $resultPath = Join-Path $script:stateDir 'result.json'
        if (Test-Path $resultPath) {
            $result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
            $ok = @($result.Results | Where-Object Status -eq 'Correcto').Count
            $pending = @($result.Results | Where-Object Status -ne 'Correcto').Count
            $statusLabel.Text = "Terminó: $ok correctas, $pending pendientes."
            if (@($result.Results | Where-Object Reboot).Count -gt 0) { Add-Log 'Windows indica que hace falta reiniciar.' }
            Add-Log 'Pulsa Buscar actualizaciones para revisar lo que queda.'
        } else { Add-Log 'La instalación terminó sin un resultado legible.' }
    }
    $scanButton.Enabled = $true
    $script:process.Dispose()
    $script:process = $null
})

$scanButton.Add_Click({ Start-Worker 'scan' })
$updateButton.Add_Click({
    $grid.EndEdit()
    $chosen = @()
    for ($i=0; $i -lt $grid.Rows.Count; $i++) {
        if ($grid.Rows[$i].Cells['Selected'].Value -eq $true) { $chosen += $script:items[$i] }
    }
    if ($chosen.Count -eq 0) { [void][System.Windows.Forms.MessageBox]::Show('Marca al menos una actualización.'); return }
    Add-Log "Instalando $($chosen.Count) elemento(s)..."
    Start-Worker 'update' (ConvertTo-Json -InputObject @($chosen) -Depth 5)
})
$form.Add_FormClosing({ if ($script:process -and -not $script:process.HasExited) { $_.Cancel = $true; [void][System.Windows.Forms.MessageBox]::Show('Espera a que termine la operación antes de cerrar.') } })
[void]$form.ShowDialog()
