# Azure Deployment: Domain Controller Setup

This guide covers deploying a Windows Server Active Directory Domain Controller in Microsoft Azure as cheaply as possible — ideal for a home lab environment.

---

## Cost Overview

| Scenario | VM Size | Monthly Cost |
|----------|---------|-------------|
| **Free (new Azure account, first 12 months)** | B1s (1 vCPU, 1 GB RAM) | **$0** — 750 hrs/month free |
| **Pay-as-you-go, running 24/7** | B2s (2 vCPU, 4 GB RAM) | ~$30–35/month |
| **Pay-as-you-go, lab use only (~10 hrs/week)** | B2s deallocated when idle | ~$5–10/month (disk + IP only) |

> **Key tip:** Azure does NOT charge compute when a VM is **deallocated** (properly stopped from the portal). For a lab, spin it up when you're working and stop it when done. You only pay for the managed disk (~$1.28–3/month for 32 GB Standard HDD) and a static public IP (~$3/month).

**New to Azure?** Sign up at https://azure.microsoft.com/free — you get **$200 in credits** for 30 days and a **free B1s VM for 12 months**.

---

## Prerequisites

- Microsoft account (Outlook, Hotmail, or work/school account)
- Azure subscription (free account or pay-as-you-go)
- RDP client (built into Windows; use Microsoft Remote Desktop on Mac/Linux)
- Basic familiarity with Windows Server

---

## Phase 1 — Azure Infrastructure Setup

### Step 1 — Create a Resource Group

A resource group is a logical container for all your lab resources.

1. In the [Azure Portal](https://portal.azure.com), search **Resource Groups** → **+ Create**
2. Settings:
   - **Subscription:** Your subscription
   - **Resource group name:** `AD-Lab-RG`
   - **Region:** `East US` (cheapest US region)
3. Click **Review + Create** → **Create**

---

### Step 2 — Create a Virtual Network

1. Search **Virtual Networks** → **+ Create**
2. **Basics** tab:
   - Resource group: `AD-Lab-RG`
   - Name: `AD-Lab-VNet`
   - Region: `East US`
3. **IP Addresses** tab:
   - Address space: `10.0.0.0/16`
   - Click the default subnet → rename to `AD-Subnet`, set range to `10.0.1.0/24`
4. Click **Review + Create** → **Create**

---

## Phase 2 — Deploy the Domain Controller VM

### Step 3 — Create the VM

1. Search **Virtual Machines** → **+ Create** → **Azure Virtual Machine**

**Basics tab:**

| Field | Value |
|-------|-------|
| Resource group | `AD-Lab-RG` |
| VM name | `DC01` |
| Region | `East US` |
| Availability options | No infrastructure redundancy |
| Security type | Standard |
| Image | **Windows Server 2022 Datacenter - Gen2** |
| VM Size | **Standard_B2s** (click "See all sizes" → search B2s) |
| Username | `labadmin` |
| Password | Strong password — save this |
| Public inbound ports | **RDP (3389)** |

> **Free tier users:** Select **Standard_B1s** instead of B2s to use your 750 free hours/month.

**Disks tab:**
- OS disk type: **Standard HDD** (saves ~$5/month vs. Premium SSD — fine for a lab)

**Networking tab:**
- Virtual network: `AD-Lab-VNet`
- Subnet: `AD-Subnet`
- Public IP: auto-created (leave default)
- NIC security group: **Basic**
- Inbound ports: `RDP (3389)`

**Management tab:**
- **Auto-shutdown:** ✅ Enable → set time: `11:00 PM` in your timezone
  - This automatically deallocates the VM nightly so you're not billed overnight

Click **Review + Create** → **Create** (deployment takes ~2–3 minutes)

---

### Step 4 — Set a Static Private IP

Active Directory requires a static IP address on the DC.

1. Portal → **Virtual Machines** → `DC01`
2. **Networking** → click the **Network Interface** name (e.g., `dc01123`)
3. **IP configurations** → click `ipconfig1`
4. Under **Private IP address assignment** → change to **Static**
5. Set IP address to: `10.0.1.10`
6. Click **Save**

---

### Step 5 — Connect via RDP

1. Portal → `DC01` → **Connect** → **RDP**
2. Click **Download RDP File**
3. Open the file → log in with:
   - Username: `labadmin`
   - Password: your password
4. Accept the certificate warning

---

## Phase 3 — Install Active Directory

All commands below are run in **PowerShell as Administrator** inside the VM.

### Step 6 — Rename the Server

```powershell
Rename-Computer -NewName "DC01" -Restart
```

Reconnect via RDP after the reboot.

---

### Step 7 — Configure DNS to Loopback

```powershell
# View adapter name
Get-NetAdapter

# Point DNS to itself (required for AD DS install)
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "127.0.0.1"
```

---

### Step 8 — Install AD DS and DNS Roles

```powershell
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
```

---

### Step 9 — Promote to Domain Controller (New Forest)

```powershell
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -Force:$true
```

The server will reboot automatically. Reconnect via RDP and log in as `LAB\labadmin`.

---

### Step 10 — Add a Routable UPN Suffix

Required later for Entra Connect / M365 hybrid sync:

```powershell
# Replace yourdomain.com with the domain you will verify in M365
Get-ADForest | Set-ADForest -UPNSuffixes @{Add="yourdomain.com"}
```

---

### Step 11 — Build the OU Structure

```powershell
$d = "DC=lab,DC=local"

New-ADOrganizationalUnit -Name "Servers"      -Path $d
New-ADOrganizationalUnit -Name "Workstations" -Path $d
New-ADOrganizationalUnit -Name "Users"        -Path $d
New-ADOrganizationalUnit -Name "Groups"       -Path $d

New-ADOrganizationalUnit -Name "Admins"            -Path "OU=Users,$d"
New-ADOrganizationalUnit -Name "Standard Users"    -Path "OU=Users,$d"
New-ADOrganizationalUnit -Name "Service Accounts"  -Path "OU=Users,$d"

New-ADOrganizationalUnit -Name "Security Groups"     -Path "OU=Groups,$d"
New-ADOrganizationalUnit -Name "Distribution Groups" -Path "OU=Groups,$d"
```

---

### Step 12 — Create Test Users

```powershell
$pw = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

New-ADUser -Name "John Smith" `
  -SamAccountName "jsmith" `
  -UserPrincipalName "jsmith@yourdomain.com" `
  -Path "OU=Standard Users,OU=Users,DC=lab,DC=local" `
  -AccountPassword $pw -Enabled $true

New-ADUser -Name "Lab Admin" `
  -SamAccountName "adm.admin" `
  -UserPrincipalName "adm.admin@yourdomain.com" `
  -Path "OU=Admins,OU=Users,DC=lab,DC=local" `
  -AccountPassword $pw -Enabled $true
```

> Or run the included [New-LabUsers.ps1](../scripts/New-LabUsers.ps1) script for bulk creation.

---

### Step 13 — Verify AD Installation

```powershell
# Check AD services are running
Get-Service adws, kdc, netlogon, dns

# Confirm domain
Get-ADDomain

# List domain controllers
Get-ADDomainController -Filter *

# Test DNS
Resolve-DnsName lab.local
```

---

## Phase 4 — Cost Control

### Step 14 — Deallocate When Not in Use

Always stop the VM from the **Azure Portal** (not just OS shutdown) to stop compute billing:

**Portal method:**
`DC01` → **Stop** → confirm → wait for status **Stopped (deallocated)**

**CLI method (Azure Cloud Shell):**
```bash
az vm deallocate --resource-group AD-Lab-RG --name DC01
```

**To start it back up:**
```bash
az vm start --resource-group AD-Lab-RG --name DC01
```

> ⚠️ If you shut down from inside Windows (Start → Shut Down), Azure still bills you. You MUST use the portal or CLI to deallocate.

---

### Step 15 — Set a Billing Alert

Prevent surprise charges:

1. Portal → **Cost Management + Billing** → **Budgets** → **+ Add**
2. Set a monthly budget of **$10**
3. Add an alert at **80%** — you'll receive an email if approaching the limit

---

## Full Cost Summary

| Resource | Estimated Monthly Cost |
|----------|----------------------|
| B1s VM compute (free tier, 12 months) | **$0.00** |
| B2s VM compute (lab use, ~10 hrs/week) | **~$4–6** |
| Standard HDD OS disk (32 GB) | **~$1.28** |
| Static public IP | **~$3.00** |
| VNet, NSG, outbound bandwidth (lab scale) | **~$0–1** |
| **Total (lab use after free tier)** | **~$8–11/month** |

---

## Validation Checklist

- [ ] VM deployed and accessible via RDP
- [ ] Static private IP `10.0.1.10` assigned
- [ ] Server renamed to `DC01`
- [ ] AD DS and DNS roles installed
- [ ] Domain `lab.local` created (new forest)
- [ ] Routable UPN suffix added (`yourdomain.com`)
- [ ] OU structure created
- [ ] Test user accounts created
- [ ] Auto-shutdown enabled
- [ ] Billing alert configured

---

## Next Step

Proceed to [M365 Tenant Setup →](04-m365-tenant-setup.md) to create your Microsoft 365 tenant and verify your custom domain in preparation for Entra Connect hybrid sync.
