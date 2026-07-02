# Install-OpenSSHServer

Installs and configures the Windows OpenSSH Server feature for remote management (e.g. Ansible over SSH).

## What it does

1. Installs the `OpenSSH.Server` Windows capability if not already present.
2. Sets Windows PowerShell (`powershell.exe`) as the default SSH shell — the default expected by Ansible.
3. Enables the built-in `OpenSSH-Server-In-TCP` firewall rule for the **Domain** and **Private** profiles.
4. Deploys `sshd_config` from the script directory to `%ProgramData%\ssh\sshd_config`.
5. Deploys `administrators_authorized_keys` to `%ProgramData%\ssh\` and applies the required ACL (inheritance removed; Full Control for `Administrators` and `SYSTEM` only).
6. Sets the `sshd` service to start automatically.
7. Restarts `sshd` to apply config changes — **only if there are no active SSH connections**. If sessions are established, the restart is skipped and changes apply on the next run/restart cycle.

## Files

| File | Purpose |
|------|---------|
| `Install-OpenSSHServer.ps1` | The install/configure script |
| `sshd_config` | Server configuration deployed to `%ProgramData%\ssh\` |
| `administrators_authorized_keys` | Public keys for members of the Administrators group |

Both `sshd_config` and `administrators_authorized_keys` must be in the same directory as the script.

## Requirements

- Windows 10 1809+ / Windows Server 2019+ (OpenSSH capability available)
- Run as Administrator
- Internet access or a configured Features on Demand source for `Add-WindowsCapability`

## Usage

```powershell
.\Install-OpenSSHServer.ps1
```

The script is idempotent and safe to re-run — suitable for scheduled deployment (e.g. GPO startup script or configuration management).

## Notes

- Active connection detection checks established TCP connections owned by the `sshd` process, so it works regardless of the configured listen port.
- `administrators_authorized_keys` ACLs are enforced on every run; sshd refuses the file if permissions are too open.
- To use PowerShell 7 as the default shell instead, change the `DefaultShell` value to the path of `pwsh.exe`.
