# 06 — Optional Hybrid Workloads

## Overview

With the core hybrid identity in place, this section covers optional enterprise workloads that extend the lab's realism: Exchange Hybrid, Hybrid Azure AD Join, and Microsoft Teams/SharePoint.

---

## Exchange Hybrid

Exchange Hybrid allows on-premises Exchange mailboxes to coexist with Exchange Online. For a lab environment, this is relevant if you want to simulate a real migration scenario.

### Prerequisites

- Exchange Server 2016 or 2019 installed on-prem
- M365 Exchange Online licenses assigned
- Entra Connect sync running

### Hybrid Configuration Wizard (HCW)

Microsoft provides a wizard to configure Exchange Hybrid:

1. Download the HCW from [https://aka.ms/HybridWizard](https://aka.ms/HybridWizard)
2. Run on the Exchange Server
3. Choose **Full Hybrid** or **Minimal Hybrid** (minimal is sufficient for testing mail flow)
4. Complete authentication with both on-prem Exchange admin and M365 Global Admin
5. The wizard configures:
   - Organization relationships
   - Connectors (inbound and outbound mail flow)
   - OAuth authentication
   - Free/busy calendar sharing

### Key HCW Selections

| Option | Lab Recommendation |
|--------|-------------------|
| Hybrid Type | Full Hybrid |
| Exchange Server | Select your on-prem Exchange server |
| Send Connector | Use Exchange Online Protection |
| Receive Connector | Auto-configured |

> **Note:** Exchange hybrid is complex. For a basic lab, consider Exchange Online-only and skip on-prem Exchange unless the goal is specifically migration simulation.

---

## Hybrid Azure AD Join

Hybrid Azure AD Join allows on-prem domain-joined Windows devices to also register in Entra ID, enabling conditional access and Intune co-management.

### Configure via Entra Connect

1. In Entra Connect → **Configure** → **Configure device options**
2. Select **Configure Hybrid Azure AD join**
3. Select your AD forest and domain
4. The wizard creates a Service Connection Point (SCP) in AD

### Verify SCP in AD

```powershell
$scp = New-Object System.DirectoryServices.DirectoryEntry
$scp.Path = "LDAP://CN=62a0ff2e-97b9-4513-943f-0d221bd30080,CN=Device Registration Configuration,CN=Services,CN=Configuration,DC=lab,DC=local"
$scp.Keywords
```

### On Client VM

After a Group Policy refresh and reboot, domain-joined clients will register automatically:

```powershell
# Force GP update
gpupdate /force

# Check device join status
dsregcmd /status
```

Look for:
```
AzureAdJoined : YES
DomainJoined  : YES
```

---

## Microsoft Teams & SharePoint Online

Teams and SharePoint Online are included in most M365 licenses and work natively with synced hybrid users.

### Verify Teams Access for Synced Users

1. Sign in to [https://teams.microsoft.com](https://teams.microsoft.com) as a synced user
2. Create a test Team and invite other lab users
3. Confirm chat, calls, and file sharing via SharePoint work

### SharePoint / OneDrive

- OneDrive is provisioned automatically on first login
- SharePoint sites can be created from the Admin Center
- Test document collaboration between synced lab users

---

## Microsoft Intune (Device Management)

Intune allows MDM/MAM for enrolled devices. Combined with Hybrid Join, you can achieve co-management.

### Enroll a Device

1. In Entra Admin Center → **Devices** → **Enrollment**
2. Configure auto-enrollment for Windows devices
3. On the client VM, go to **Settings** → **Accounts** → **Access work or school** → **Connect**
4. Sign in with a synced M365 user account

### Verify Enrollment

```
Intune Admin Center (intune.microsoft.com) → Devices → All Devices
```

---

## Validation Checklist

- [ ] (If configured) Exchange Hybrid Wizard completed without errors
- [ ] Mail flow tested between on-prem and Exchange Online mailboxes
- [ ] Hybrid Azure AD Join SCP created in AD
- [ ] Client VM shows `AzureAdJoined: YES` and `DomainJoined: YES`
- [ ] Synced users can sign in to Teams and SharePoint Online
- [ ] (Optional) Device enrolled in Intune and visible in admin portal
