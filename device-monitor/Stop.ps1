# Asks the helper to stop, then ends this folder's helper if it does not exit (for example when hung).
$server = Join-Path $PSScriptRoot 'Monitor.ps1'
try { Invoke-RestMethod 'http://localhost:18743/api/stop' -Method Post -Headers @{'X-Device-Monitor'='1'} -Body '{}' -TimeoutSec 3 | Out-Null } catch {}
for ($attempt = 0; $attempt -lt 20; $attempt++) {
    $helpers = @(Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.IndexOf($server, [StringComparison]::OrdinalIgnoreCase) -ge 0 })
    if (-not $helpers.Count) { break }
    Start-Sleep -Milliseconds 250
}
foreach ($helper in $helpers) { Stop-Process -Id $helper.ProcessId -Force -ErrorAction SilentlyContinue }
Write-Host 'Device Monitor stopped.'
