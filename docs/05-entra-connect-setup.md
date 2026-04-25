# 05 — Microsoft Entra Connect Setup

## Overview

Microsoft Entra Connect (formerly Azure AD Connect) is the on-premises agent that synchronizes AD identities to Entra ID (Azure AD). This section covers installation, OU scoping, sync configuration, and validation.

---

## Prerequisites

Before installing Entra Connect:

- [ ] Domain Controller is deployed and running (see [Section 02](02-ad-domain-controller.md))
- [ ] Custom domain is verified in M365 (see [Section 04](04-m365-tenant-setup.md))
- [ ] AD users have a **routable UPN suffix** (e.g., `@yourdomain.com`)
- [ ] Entra Connect server has internet access
- [ ] .NET Framework 4.7.2 or later installed
- [ ] TLS 1.2 enabled on the server

---

## Step 1 — Download Entra Connect

Download the latest version from:
[https://www.microsoft.com/en-us/download/details.aspx?id=47594](https://www.microsoft.com/en-us/download/details.aspx?id=47594)

Or use PowerShell:

```powershell
Invoke-WebRequest -Uri "https://download.microsoft.com/download/B/0/0/B00291D0-5A83-4DE7-86F5-980BC00DE05A/AzureADConnect.msi" `
  -OutFile "C:\Temp\AzureADConnect.msi"
```

---

## Step 2 — Install Entra Connect

1. Run `AzureADConnect.msi` on the Domain Controller (or a dedicated sync server)
2. Accept the license agreement
3. Choose installation type:

| Option | Use Case |
|--------|----------|
| **Express Settings** | Single AD forest, password hash sync, auto-configure |
| **Customize** | Multiple forests, specific OU filtering, custom sync rules |

> For this lab, **Express Settings** works for a single-forest setup. Use **Customize** if you want OU-level filtering.

---

## Step 3 — Express Settings Configuration

If using Express Settings:

1. Sign in with your **M365 Global Admin** credentials
2. Sign in with your **AD Enterprise Admin** credentials
3. Entra Connect will automatically:
   - Configure Password Hash Synchronization (PHS)
   - Sync all users in the domain
   - Enable auto-upgrade

4. Click **Install** and wait for initial sync to complete (~5–15 minutes)

---

## Step 4 — Custom Settings (OU Filtering)

If you chose **Customize** to scope sync to specific OUs:

```
Customize → Domain/OU Filtering → Select specific OUs
```

Recommended sync scope for this lab:

| OU | Sync? |
|----|-------|
| OU=Standard Users,OU=Users | ✅ Yes |
| OU=Admins,OU=Users | ✅ Yes |
| OU=Computers (Workstations) | Optional |
| OU=Service Accounts | Optional — be cautious |
| Domain Controllers | ❌ No |

---

## Step 5 — Choose Sign-In Method

| Method | Description | Lab Recommendation |
|--------|-------------|-------------------|
| **Password Hash Sync (PHS)** | Hash of AD password synced to cloud | ✅ Easiest for lab |
| **Pass-Through Authentication (PTA)** | Auth proxied to on-prem AD at login time | Good for realism |
| **Federation (ADFS)** | On-prem ADFS handles all auth | Complex — skip for basic lab |

---

## Step 6 — Verify Sync Status

After installation, verify sync from PowerShell:

```powershell
# Install the module if needed
Install-Module -Name ADSync -Force

# Check sync status
Import-Module ADSync
Get-ADSyncScheduler

# Trigger a manual delta sync
Start-ADSyncSyncCycle -PolicyType Delta

# Check for sync errors
Get-ADSyncRunStepResult | Sort-Object StartDate -Descending | Select-Object -First 10
```

---

## Step 7 — Validate in Entra Admin Center

1. Go to [https://entra.microsoft.com](https://entra.microsoft.com)
2. Navigate to **Identity** → **Users** → **All Users**
3. Confirm synced users show **Source: Windows Server AD** (not "Azure Active Directory")
4. Test sign-in with a synced user account at [https://portal.office.com](https://portal.office.com)

---

## Step 8 — Custom Attribute Mappings (Optional)

If you need to map additional AD attributes to Entra ID (e.g., department, phone number):

```
Entra Connect → Synchronization Rules Editor → Create new Inbound Rule
```

Common attribute mappings:

| AD Attribute | Entra ID Attribute |
|-------------|-------------------|
| `department` | `department` |
| `telephoneNumber` | `telephoneNumber` |
| `title` | `jobTitle` |
| `manager` | `manager` |

---

## Sync Schedule

By default, Entra Connect syncs every **30 minutes**. You can check or modify this:

```powershell
# Check current schedule
Get-ADSyncScheduler | Select-Object CurrentlyRunning, NextSyncCyclePolicyType, NextSyncCycleStartTimeInUTC, SyncCycleEnabled

# Trigger immediate full sync
Start-ADSyncSyncCycle -PolicyType Initial

# Trigger delta sync (incremental changes only)
Start-ADSyncSyncCycle -PolicyType Delta
```

---

## Validation Checklist

- [ ] Entra Connect installed without errors
- [ ] Initial sync completed successfully
- [ ] Synced users visible in Entra Admin Center with "Windows Server AD" as source
- [ ] Users can sign in to Microsoft 365 portal with on-prem credentials
- [ ] Password changes in AD replicate to M365 within 30 min (PHS)
- [ ] No sync errors in the Synchronization Service Manager
- [ ] Scheduler running on 30-minute cycle
