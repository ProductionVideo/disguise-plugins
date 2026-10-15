# Ends this folder's helper, found by command line so a hung helper or one without a PID file is stopped too.
$server=Join-Path $PSScriptRoot 'server.mjs'
$helpers=@(Get-CimInstance Win32_Process -Filter "Name='node.exe'"|Where-Object {$_.CommandLine -and $_.CommandLine.IndexOf($server,[StringComparison]::OrdinalIgnoreCase) -ge 0})
foreach($helper in $helpers){Stop-Process -Id $helper.ProcessId -Force -ErrorAction SilentlyContinue}
Remove-Item -LiteralPath (Join-Path $PSScriptRoot 'helper.pid') -ErrorAction SilentlyContinue
if(!$helpers.Count){Write-Host 'Videohub Monitor was not running.'}
