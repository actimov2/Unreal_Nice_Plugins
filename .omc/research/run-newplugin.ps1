$ErrorActionPreference = 'Stop'
$env:PATH = 'C:\Program Files\GitHub CLI;' + $env:PATH
$env:TEMP = 'C:\Users\Windows-10\AppData\Local\Temp'
$env:TMP = $env:TEMP
Write-Host "PATH gh ok: $((Get-Command gh).Source)"
Write-Host "TEMP: $env:TEMP"
& "$PSScriptRoot\..\..\scripts\new-plugin.ps1" -Name 'OptimizePrime' -Description 'Scene heaviness analyzer for VP / Broadcast / Game scenes.'
