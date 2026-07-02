
# GPO: Enable OpenSSH Server
 
Deploys and configures the Windows OpenSSH Server across domain-joined machines.
 
## Overview
 
The GPO uses a **Scheduled Task preference item** (Computer Configuration) to run the
`enableSSH.ps1` script on each target machine. The script installs the
OpenSSH.Server capability, sets PowerShell as the default SSH shell, opens the
firewall rule for the Domain/Private profiles, deploys `sshd_config` and
`administrators_authorized_keys`, and enables the `sshd` service. Because the script
is idempotent, the task can safely run on a recurring schedule to enforce
configuration drift correction — config changes are picked up on the next cycle,
and `sshd` is only restarted when no SSH sessions are active.

Configuration is updated / reapplied each time the group policy refresh cycle is executed (via an Immeditate Task).
 
## Configuration steps
 
### 1. Create the GPO
 
1. Open **Group Policy Management** (`gpmc.msc`).
2. Right-click the domain or target OU → **Create a GPO in this domain, and Link it here…**
3. Name: `Enable OpenSSH Server`.
### 2. Stage the script files
 
Place the script and its companion files on a share readable by computer accounts
(e.g. SYSVOL or NETLOGON):
 
```
%SYSVOL%\scripts\enableSSH\
├── enableSSH.ps1
├── sshd_config
└── administrators_authorized_keys
```
 
`sshd_config` and `administrators_authorized_keys` must be in the same directory as
the script (it resolves them via `$PSScriptRoot`).
 
### 3. Create the Scheduled Task preference
 
1. Edit the GPO → **Computer Configuration → Preferences → Control Panel Settings → Scheduled Tasks**.
2. Right-click → **New → Immediate Task (At least Windows 7)**.
3. **General** tab:
   - Action: `Create`
   - Name: e.g. `Enable OpenSSH Server`
   - Security options: run as `NT AUTHORITY\SYSTEM`, **Run whether user is logged on or not**, **Run with highest privileges**.
4. **Actions** tab — **Start a program**:
   - Program: `powershell.exe`
   - Arguments:
```
     -NoProfile -ExecutionPolicy Bypass -File "\\rwhl.net\SYSVOL\rwhl.net\scripts\enableSSH\enableSSH.ps1"
```
6. **Settings** tab: allow task to be run on demand; stop if running longer than a sensible limit (e.g. 1 hour).
### 4. Scope the GPO
 
- **Security Filtering:** default `Authenticated Users` applies it to all computers
  in the linked OU. To target a subset, remove Authenticated Users from filtering,
  add a computer group (e.g. `SSH-Enabled-Computers`), and ensure Authenticated
  Users retains **Read** on the Delegation tab (required for GPO processing).
- **Link** the GPO to the OU(s) containing the target computer objects.
### 5. Apply and verify
 
On a target machine:
 
```cmd
gpupdate /force
```
 
Test connectivity :
 
```cmd
ssh <user>@<hostname>

ssh <user>@<hostnameFQDN> #to use kerberos auth
```
 
## Notes
 
- The task runs as SYSTEM, so the file share hosting the script must grant read
  access to **Domain Computers** (SYSVOL does by default).
- Changes to `sshd_config` or `administrators_authorized_keys` on the share are
  applied on the next task run; `sshd` restarts only when idle.
 
