# Asks the helper to stop, then ends it if it does not exit (for example when hung).
$pidFile=Join-Path $PSScriptRoot 'helper.pid'
try{$saved=[int](Get-Content $pidFile -ErrorAction Stop)}catch{$saved=0}
foreach($port in @(18745,18746)){try{Invoke-RestMethod "http://localhost:$port/api/stop" -Method Post -Headers @{'X-Projector-Monitor'='1'} -Body '{}' -TimeoutSec 3|Out-Null}catch{}}
if($saved){
 for($i=0;$i -lt 20 -and (Get-Process -Id $saved -ErrorAction SilentlyContinue);$i++){Start-Sleep -Milliseconds 250}
 $process=Get-CimInstance Win32_Process -Filter "ProcessId=$saved" -ErrorAction SilentlyContinue
 if($process -and $process.CommandLine.IndexOf((Join-Path $PSScriptRoot 'Monitor.ps1'),[StringComparison]::OrdinalIgnoreCase) -ge 0){Stop-Process -Id $saved -Force -ErrorAction SilentlyContinue}
 Remove-Item $pidFile -ErrorAction SilentlyContinue
}
