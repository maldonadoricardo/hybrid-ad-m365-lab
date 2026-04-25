# 07 — Operations Runbook

## Overview

This runbook covers day-to-day operations for the hybrid lab: onboarding new users, monitoring sync health, common troubleshooting steps, and full lab teardown/rebuild procedures.

---

## New User Onboarding

### Full Workflow (Hybrid)

```
On-prem AD → Wait for sync → Assign M365 License → User can sign in
```

**Step 1 — Create user in AD**

```powershell
$password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

New-ADUser `
  -Name "Jane Doe" `
  -GivenName "Jane" `
  -Surname "Doe" `
  -SamAccountName "jdoe" `
  -UserPrincipalName "jdoe@yourdomain.com" `
  -Path "OU=Standard Users,OU=Users,DC=lab,DC=local" `
  -Department "IT" `
  -Title "IT Technician" `
  -AccountPassword $password `
  -Enabled $true
```

**Step 2 — Force an immediate sync**

```powershell
Start-ADSyncSyncCycle -PolicyType Delta
```

**Step 3 — Assign M365 License**

```
M365 Admin Center → Users → Active Users → Select jdoe → Licenses and Apps → Assign
```

Or via PowerShell (requires MSOnline module):

```powershell
Connect-MsolService
Set-MsolUserLicense -UserPrincipalName "jdoe@yourdomain.com" -AddLicenses "yourtenant:ENTERPRISEPACK"
```

**Step 4 — Verify**

- User appears in Entra Admin Center → Users with Source: Windows Server AD
- User can sign in at [https://portal.office.com](https://portal.office.com)

---

## Sync Health Monitoring

### Check Entra Connect Sync Status

```powershell
# View sync scheduler info
Get-ADSyncScheduler

# View last sync run results
Get-ADSyncRunStepResult | Sort StartDate -Descending | Select -First 5

# Check for export errors
Get-ADSyncConnectorStatistics | Select ConnectorName, ExportErrors
```

### Synchronization Service Manager (GUI)

Open: `C:\Program Files\Microsoft Azure AD Sync\UIShell\miisclient.exe`

- Review **Operations** tab for recent sync runs
- Look for any **stopped-error** status entries
- Check **Connectors** tab for the AD and Entra ID connectors

---

## Common Troubleshooting

### Users Not Appearing in Entra ID

| Check | Command |
|-------|---------|
| UPN is routable | `Get-ADUser -Identity jdoe -Properties UserPrincipalName` |
| User is in synced OU | `Get-ADUser -Identity jdoe -Properties DistinguishedName` |
| Sync ran recently | `Get-ADSyncScheduler` |
| Sync errors exist | Synchronization Service Manager → Operations |

### Password Not Working in M365

| Check | Action |
|-------|--------|
| Password Hash Sync enabled | Entra Connect settings |
| Account is not locked | `Search-ADAccount -LockedOut` |
| Force password re-hash | Reset password in AD, then sync |

```powershell
# Unlock a locked AD account
Unlock-ADAccount -Identity jdoe

# Force a password hash re-sync for a user
Set-ADAccountPassword -Identity jdoe -Reset -NewPassword (ConvertTo-SecureString "NewP@ss123!" -AsPlainText -Force)
Start-ADSyncSyncCycle -PolicyType Delta
```

### Sync Errors — Duplicate Attribute

If you see `AttributeValueMustBeUnique` errors, a UPN or proxy address is duplicated:

```powershell
# Find duplicate UPNs
Get-ADUser -Filter * -Properties UserPrincipalName | Group-Object UserPrincipalName | Where-Object {$_.Count -gt 1}
```

---

## Lab Teardown Procedure

### Option A — Reset Without Rebuilding

1. Delete all synced test users from M365 (they will be soft-deleted for 30 days)
2. Run `Start-ADSyncSyncCycle -PolicyType Initial` to force full re-evaluation
3. Recreate test users in AD as needed

### Option B — Full Lab Rebuild

1. **Uninstall Entra Connect** from Add/Remove Programs on the sync server
2. **Remove directory sync** from Entra Admin Center:
   ```
   Entra Admin Center → Identity → Hybrid Management → Entra Connect → Disable sync
   ```
3. **Delete the M365 tenant** (if completely rebuilding):
   - Cancel all subscriptions
   - Delete tenant via M365 Admin Center
4. **Rebuild the DC VM** from snapshot or reinstall Windows Server
5. Follow this documentation from Section 01 to rebuild from scratch

---

## Useful Admin Links

| Resource | URL |
|----------|-----|
| Microsoft 365 Admin Center | https://admin.microsoft.com |
| Entra Admin Center | https://entra.microsoft.com |
| Exchange Admin Center | https://admin.exchange.microsoft.com |
| Intune Admin Center | https://intune.microsoft.com |
| Teams Admin Center | https://admin.teams.microsoft.com |
| Azure Portal | https://portal.azure.com |

---

## Useful PowerShell Modules

```powershell
# Install commonly used modules
Install-Module -Name Microsoft.Graph -Force
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name MSOnline -Force
Install-Module -Name AzureAD -Force

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "User.ReadWrite.All", "Directory.ReadWrite.All"

# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName admin@yourdomain.com
```
