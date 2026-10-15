# Starts the helper unless this folder's helper is already running and answering.
# Designer passes -OwnerPid so the helper stops when Designer exits.
param([int]$OwnerPid=0)
$ErrorActionPreference = 'Stop'
$app = 'disguise-device-monitor-v2'
$port = 18743
$url = "http://localhost:$port/api/status"
$server = Join-Path $PSScriptRoot 'Monitor.ps1'
function Get-Health { try { return Invoke-RestMethod $url -TimeoutSec 3 } catch { return $null } }
# This folder's helpers, found by command line so hung or older helpers are found too.
function Get-Helpers { @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.IndexOf($server, [StringComparison]::OrdinalIgnoreCase) -ge 0 }) }

$health = Get-Health
if ($health -and $health.app -ne $app) { throw "Port $port is used by another application." }
$helpers = Get-Helpers
# A helper whose Designer has exited is already shutting down; replace it rather than reuse it.
$ownerGone = $health.owner -and -not (Get-Process -Id $health.owner -ErrorAction SilentlyContinue)
if ($health -and $health.pid -and $helpers.ProcessId -contains $health.pid -and -not $ownerGone) { Write-Host 'Device Monitor is already running.'; exit }
# Anything else is hung, outdated, shutting down or from another folder: stop it.
if ($health) { try { Invoke-RestMethod "http://localhost:$port/api/stop" -Method Post -Headers @{'X-Device-Monitor'='1'} -Body '{}' -TimeoutSec 3 | Out-Null } catch {} }
foreach ($helper in $helpers) { Stop-Process -Id $helper.ProcessId -Force -ErrorAction SilentlyContinue }
for ($attempt = 0; $attempt -lt 40 -and (Get-Health); $attempt++) { Start-Sleep -Milliseconds 250 }
if (Get-Health) { throw "Port $port is held by a Device Monitor from another folder. Run that folder's Stop.cmd." }

$arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-WindowStyle', 'Hidden', '-File', ('"{0}"' -f $server))
if ($OwnerPid) { $arguments += @('-OwnerPid', [string]$OwnerPid) }
$process = Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList $arguments
for ($attempt = 0; $attempt -lt 40; $attempt++) {
    Start-Sleep -Milliseconds 250
    if ((Get-Health).pid -eq $process.Id) { Write-Host "Device Monitor ready at http://localhost:$port/"; exit }
    if ($process.HasExited) { break }
}
throw "Device Monitor could not start. See $(Join-Path $PSScriptRoot 'monitor.log')."
