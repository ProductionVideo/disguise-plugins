# Starts the helper unless this folder's helper is already running and answering.
# Designer passes -OwnerPid so the helper stops when Designer exits.
param([int]$OwnerPid=0)
$ErrorActionPreference='Stop'
$url='http://127.0.0.1:18753/api/state';$server=Join-Path $PSScriptRoot 'Serve.ps1'
function Get-Health{try{return Invoke-RestMethod $url -TimeoutSec 3}catch{return $null}}
# This folder's helpers, found by command line so hung or older helpers are found too.
function Get-Helpers{@(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'"|Where-Object {$_.CommandLine -and $_.CommandLine.IndexOf($server,[StringComparison]::OrdinalIgnoreCase) -ge 0})}

$h=Get-Health
if($h -and $h.app -ne 'world-clock'){throw 'Port 18753 belongs to another application'}
$helpers=Get-Helpers
# A helper whose Designer has exited is already shutting down; replace it rather than reuse it.
$ownerGone=$h.owner -and -not (Get-Process -Id $h.owner -ErrorAction SilentlyContinue)
if($h -and $h.pid -and $helpers.ProcessId -contains $h.pid -and -not $ownerGone){exit 0}
# Anything else of ours is hung, outdated or shutting down: end it.
foreach($helper in $helpers){Stop-Process -Id $helper.ProcessId -Force -ErrorAction SilentlyContinue}
for($i=0;$i -lt 40 -and (Get-Health);$i++){Start-Sleep -Milliseconds 250}
if(Get-Health){throw "Port 18753 is held by a World Clock from another folder. Run that folder's Stop.cmd."}

$ps=Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+$server+'"'
if($OwnerPid){$arguments+=' -OwnerPid '+$OwnerPid}
$p=Start-Process -FilePath $ps -ArgumentList $arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'backend-output.log') -RedirectStandardError (Join-Path $PSScriptRoot 'backend-error.log')
for($i=0;$i -lt 40;$i++){Start-Sleep -Milliseconds 250;if((Get-Health).pid -eq $p.Id){exit 0};if($p.HasExited){break}}
throw 'World Clock failed to start; see backend-error.log'
