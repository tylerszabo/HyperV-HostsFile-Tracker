#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# File location must also be changed in ScheduledTask.xml. Select a directory that does not grant write permissions to non-administrators.
$InstallFile = "$env:ProgramFiles\Hyper-V HostsFile Tracker\Update-HostsFile.ps1"
$InstallDir = (Split-Path -Path $InstallFile)

If (-Not (Test-Path -Path $InstallDir)) {
  New-Item -ItemType Directory -Path $InstallDir | Out-Null
}
Set-Location $PSScriptRoot
Copy-Item "Update-HostsFile.ps1", "LICENSE", "README.md" -Destination $InstallDir
Register-ScheduledTask -Xml (Get-Content "ScheduledTask.xml" | Out-String) -TaskName "Hyper-V HostsFile Tracker" -Force
