# Starts the helper unless this folder's helper is already running and answering.
# Designer passes -OwnerPid so the helper stops when Designer exits.
param([int]$OwnerPid=0)
$ErrorActionPreference='Stop'
$config=Get-Content (Join-Path $PSScriptRoot 'plugin-config.json') -Raw|ConvertFrom-Json
$url='http://127.0.0.1:'+ $config.port;$server=Join-Path $PSScriptRoot 'server.mjs';$pidFile=Join-Path $PSScriptRoot 'helper.pid'
function Get-Health{try{return Invoke-RestMethod ($url+'/api/state') -TimeoutSec 3}catch{return $null}}
# This folder's helpers, found by command line so hung or older helpers are found too.
function Get-Helpers{@(Get-CimInstance Win32_Process -Filter "Name='node.exe'"|Where-Object {$_.CommandLine -and $_.CommandLine.IndexOf($server,[StringComparison]::OrdinalIgnoreCase) -ge 0})}

$health=Get-Health
if($health -and $health.app -ne $config.id){throw 'Port belongs to another application'}
$helpers=Get-Helpers
# A helper whose Designer has exited is already shutting down; replace it rather than reuse it.
$ownerGone=$health.owner -and -not (Get-Process -Id $health.owner -ErrorAction SilentlyContinue)
if($health -and $health.pid -and $helpers.ProcessId -contains $health.pid -and -not $ownerGone){exit 0}
# Anything else of ours is hung, outdated or shutting down: end it.
foreach($helper in $helpers){Stop-Process -Id $helper.ProcessId -Force -ErrorAction SilentlyContinue}
for($i=0;$i -lt 40 -and (Get-Health);$i++){Start-Sleep -Milliseconds 250}
if(Get-Health){throw "Port $($config.port) is held by a Videohub Monitor from another folder. Run that folder's Stop.cmd."}

$node=Join-Path $PSScriptRoot 'runtime\node.exe'
if(!(Test-Path $node)){$node='C:\Program Files\Companion\resources\node-runtimes\node22\node.exe'}
if(!(Test-Path $node)){$command=Get-Command node.exe -ErrorAction SilentlyContinue;if(!$command){throw 'Install Node.js 22 or Companion with Node 22'};$node=$command.Source}
$arguments='"'+$server+'"';if($OwnerPid){$arguments+=' --owner='+$OwnerPid}
$p=Start-Process -FilePath $node -ArgumentList $arguments -WorkingDirectory $PSScriptRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'backend-output.log') -RedirectStandardError (Join-Path $PSScriptRoot 'backend-error.log')
$p.Id | Set-Content $pidFile
for($i=0;$i -lt 40;$i++){Start-Sleep -Milliseconds 250;if((Get-Health).pid -eq $p.Id){exit 0};if($p.HasExited){break}}
throw 'Helper failed to start. See backend-error.log.'
