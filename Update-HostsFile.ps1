<#
.SYNOPSIS
Update hosts file with Hyper-V IPs
.DESCRIPTION
Long info
.PARAMETER DefaultDomain
Default DNS suffix if an entry doesn't arleady exist
.PARAMETER HostsFilePath
Allows for testing on sample hosts files
.PARAMETER VMName
Allows for a list of VMs to be specified, this will clobber configurations for omitted VMs as they'll be treated as if they are deleted
.PARAMETER NoWait
Don't wait for adapters to have status
.PARAMETER NoBackup
Don't backup old hosts file
.NOTES
Copyright (C) 2020  Tyler Szabo

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>
#>
[CmdletBinding(SupportsShouldProcess = $True, DefaultParameterSetName = "None")]
Param (
  [Parameter(Mandatory = $False, Position = 0)]
  [String]
  $DefaultDomain = "hyperv.localhost",

  [Parameter(Mandatory = $False)]
  [String]
  $HostsFilePath = "$env:windir\System32\drivers\etc\hosts",

  [Parameter(Mandatory = $False)]
  [String[]]
  $VMName = "*",

  [Parameter(Mandatory = $False)]
  [Switch]
  $NoWait = $False,

  [Parameter(Mandatory = $False)]
  [Switch]
  $NoBackup = $False
)

$ErrorActionPreference = "Stop"

$SECTION_START = "# Managed by HyperV-HostsFile-Tracker"
$SECTION_END = "# End of HyperV-HostsFile-Tracker section"

$Time = [DateTime]::Now

$VMNetworkAdapters = Get-VMNetworkAdapter -VMName $VMName
If (-Not $NoWait) {
  While ($VMNetworkAdapters | Where-Object { $_.Status -And $_.Status -NE "Ok" }) {
    Write-Verbose "Adapters not ready, waiting..."
    Start-Sleep -Seconds 20
    $VMNetworkAdapters = Get-VMNetworkAdapter -VMName $VMName
  }
}

If (-Not $NoBackup) {
  $TimeStamp = $Time.ToString("yyyyMMddTHHmmss");
  Copy-Item -Path $HostsFilePath -Destination "$HostsFilePath.backup-$TimeStamp.txt"
}

Write-Verbose "File: $HostsFilePath"

$HostsFileContents = (Get-Content -Path $HostsFilePath -Encoding ASCII)
Write-Verbose "Initial:`n$($HostsFileContents | Out-String)"

$SearchState = "Before"
$HostsFileBeforeSection = ""
$HostsFileAfterSection = ""

$PreviousEntries = @{}

$HostsFileContents | ForEach-Object {
  If ($SearchState -eq "Before") {
    If ($_ -Match "^$SECTION_START") {
      $SearchState = "Inside"
    } Else {
      $HostsFileBeforeSection += "$_`r`n"
    }
  } ElseIf ($SearchState -eq "Inside") {
    If ($_ -Match "^$SECTION_END") {
      $SearchState = "After"
    } Else {
      If ($_ -Match "^(\S+)\s+(\S+)\s*#\s*(.*)") {
        $ParsedData = $Matches[3] | ConvertFrom-Json
        $Id = $ParsedData.Id
        $IPAddress = $Matches[1]
        $FQDN = $Matches[2]
        $ModifiedTime = $ParsedData.Modified
        If (-Not $PreviousEntries[$Id]) {
          $PreviousEntries[$Id] = @{ FQDN = $FQDN; Modified = $ModifiedTime; IPs = @($IPAddress)}
        }
        Else {
          $PreviousEntries[$Id]["IPs"] += $IPAddress
        }
      }
    }
  } Else {
    $HostsFileAfterSection += "$_`r`n"
  }
}

$PreviousEntries.Keys | ForEach-Object { $_, $PreviousEntries[$_] } | Format-List | Out-String | Write-Verbose

$GeneratedContent = "$SECTION_START`r`n`r`n"

$VMNetworkAdapters | ForEach-Object {
  $IPs = $_.IPAddresses

  $PreviousEntry = $PreviousEntries[$_.Id]
  $ModifiedTime = $Time.ToString("yyyy-MM-ddTHH:mm:sszzz");

  $Fqdn = ""
  If ($PreviousEntry) {
    $Fqdn = $PreviousEntry["FQDN"]
    If (-Not $IPs) {
      If ($PreviousEntry["IPs"]) {
        $IPs = $PreviousEntry["IPs"]
      } Else {
        $IPs = @("0.0.0.0")
      }
      $ModifiedTime = $PreviousEntry["Modified"]
    }
  }

  If (-Not $Fqdn) {
    If ($_.AdapterId -and $_.VMId) {
      $Fqdn = ($_.AdapterId, $_.VMId, $DefaultDomain) -Join "."
    }
  }

  If ($IPs -And $Fqdn) {
    $GeneratedContent += "# $($_.VMName) [$($_.SwitchName)]`r`n"
    $Comment = @{ Id = $_.Id; Modified = $ModifiedTime; } | ConvertTo-Json -Compress

    $IPs | ForEach-Object {
      $GeneratedContent += "$_ $Fqdn # $Comment`r`n"
    }
    $GeneratedContent += "`r`n"
  }
}
$GeneratedContent += "$SECTION_END`r`n"

$NewHostsFileContents = $HostsFileBeforeSection + $GeneratedContent + $HostsFileAfterSection

Write-Verbose "Updated:`n`n$($NewHostsFileContents | Out-String)`n"

If ($PSCmdlet.ShouldProcess($HostsFilePath, "Write updated hosts file")) {
  $NewHostsFileContents | Out-File -FilePath $HostsFilePath -Encoding ASCII -NoNewline
}
