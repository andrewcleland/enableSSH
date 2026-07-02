<#
.SYNOPSIS
    Installs and configures the Windows OpenSSH Server for remote management.

.DESCRIPTION
    Installs the OpenSSH.Server capability, sets Windows PowerShell as the
    default SSH shell (as expected by Ansible), enables the firewall rule for
    the Domain and Private profiles, deploys sshd_config and
    administrators_authorized_keys with correct ACLs, and enables the sshd
    service. The service is only restarted when no SSH sessions are active.

.NOTES
    Author:  Andrew Cleland
    License: MIT
    Requires: Administrator, Windows 10 1809+ / Server 2019+

    sshd_config and administrators_authorized_keys must reside in the same
    directory as this script.

.EXAMPLE
    .\enableOpenSSH.ps1
#>

# Install the feature
if ((Get-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0').State -ne 'Installed') {
    Add-WindowsCapability -Online -Name 'OpenSSH.Server~~~~0.0.1.0'
}

# PowerShell as the default SSH shell (default for Ansible)
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Enable the Domain profile for SSH
Set-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -Profile Domain,Private

# Install sshd_config
$src  = Join-Path $PSScriptRoot 'sshd_config'
$dest = "$env:ProgramData\ssh\sshd_config"
Copy-Item $src $dest -Force

# Install administrators_authorized_keys
$src  = Join-Path $PSScriptRoot 'administrators_authorized_keys'
$dest = "$env:ProgramData\ssh\administrators_authorized_keys"
Copy-Item $src $dest -Force
icacls $dest /inheritance:r /grant 'Administrators:F' /grant 'SYSTEM:F' | Out-Null

# Enable and restart the SSH service in no active connections (connections are detected regardless of TCP port configured)
Set-Service -Name sshd -StartupType Automatic
$sshdPid = (Get-CimInstance Win32_Service -Filter "Name='sshd'").ProcessId
if (-not (Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | Where-Object {$_.OwningProcess -in $sshdPid})) {
    # no active sessions — safe to restart ssdh to apply any config changes, else wait until next cycle
    Restart-Service sshd
}
