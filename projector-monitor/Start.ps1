# Starts the helper unless this folder's helper is already running and answering.
# Designer passes -OwnerPid so the helper stops when Designer exits.
param([int]$OwnerPid=0)
$ErrorActionPreference='Stop'
$port=18745;$url="http://localhost:$port/api/status"
$monitor=Join-Path $PSScriptRoot 'Monitor.ps1';$pidFile=Join-Path $PSScriptRoot 'helper.pid'
function Get-Health{try{return Invoke-RestMethod $url -TimeoutSec 3}catch{return $null}}
function Get-SavedPid{try{return [int](Get-Content $pidFile -ErrorAction Stop)}catch{return 0}}
function Wait-Exit($id){for($i=0;$i -lt 40 -and (Get-Process -Id $id -ErrorAction SilentlyContinue);$i++){Start-Sleep -Milliseconds 250}}

$health=Get-Health
if($health){
 if($health.app -ne 'disguise-projector-monitor-v2'){throw "Port $port is used by another application."}
 # A helper whose Designer has exited is already shutting down; wait for it rather than reuse it.
 $ownerGone=$health.owner -and -not (Get-Process -Id $health.owner -ErrorAction SilentlyContinue)
 if($health.pid -and $health.pid -eq (Get-SavedPid) -and -not $ownerGone){exit}
 # Otherwise it is from another folder, an older version, or on its way out. Ask it to stop.
 try{Invoke-RestMethod "http://localhost:$port/api/stop" -Method Post -Headers @{'X-Projector-Monitor'='1'} -Body '{}' -TimeoutSec 3|Out-Null}catch{}
 if($health.pid){Wait-Exit $health.pid}else{Start-Sleep -Seconds 2}
}
# This folder's helper did not answer: it is hung, so end it. The command line check guards against PID reuse.
$saved=Get-SavedPid
if($saved){
 $process=Get-CimInstance Win32_Process -Filter "ProcessId=$saved" -ErrorAction SilentlyContinue
 if($process -and $process.CommandLine.IndexOf($monitor,[StringComparison]::OrdinalIgnoreCase) -ge 0){Stop-Process -Id $saved -Force -ErrorAction SilentlyContinue;Wait-Exit $saved}
 Remove-Item $pidFile -ErrorAction SilentlyContinue
}

$arguments=@('-NoProfile','-ExecutionPolicy','Bypass','-WindowStyle','Hidden','-File',('"'+$monitor+'"'))
if($OwnerPid){$arguments+=@('-OwnerPid',[string]$OwnerPid)}
$helper=Start-Process powershell.exe -WindowStyle Hidden -PassThru -ArgumentList $arguments -RedirectStandardOutput (Join-Path $PSScriptRoot 'helper.log') -RedirectStandardError (Join-Path $PSScriptRoot 'helper-error.log')
for($i=0;$i -lt 40;$i++){
 Start-Sleep -Milliseconds 250
 if((Get-Health).pid -eq $helper.Id){exit}
 if($helper.HasExited){break}
}
throw "Projector Monitor did not start. See $(Join-Path $PSScriptRoot 'helper-error.log')."
