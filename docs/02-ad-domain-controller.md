# 02 — On-Premises Active Directory Domain Controller

## Overview

This section covers the complete deployment of a Windows Server domain controller, including AD DS role installation, domain promotion, and initial hardening.

---

## Prerequisites

- Windows Server 2022 VM deployed and reachable
- Static IP assigned
- Server renamed (e.g., `DC01`)
- Windows Updates applied

---

## Step 1 — Set Static IP and Hostname

```powershell
# Rename the server
Rename-Computer -NewName "DC01" -Restart

# Set static IP (run after reboot)
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress 192.168.x.x -PrefixLength 24 -DefaultGateway 192.168.x.1
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses 127.0.0.1
```

---

## Step 2 — Install AD DS and DNS Roles

```powershell
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools
```

---

## Step 3 — Promote to Domain Controller (New Forest)

```powershell
Install-ADDSForest `
  -DomainName "lab.local" `
  -DomainNetbiosName "LAB" `
  -ForestMode "WinThreshold" `
  -DomainMode "WinThreshold" `
  -InstallDns:$true `
  -Force:$true
```

> The server will reboot automatically after promotion.

---

## Step 4 — Add Routable UPN Suffix

This is required for Entra Connect sync — users need a routable UPN to sign in to M365.

```powershell
# After logging back in as domain admin
Get-ADForest | Set-ADForest -UPNSuffixes @{Add="yourdomain.com"}
```

---

## Step 5 — Create OU Structure

```powershell
$domain = "DC=lab,DC=local"

New-ADOrganizationalUnit -Name "Servers"      -Path $domain
New-ADOrganizationalUnit -Name "Workstations" -Path $domain
New-ADOrganizationalUnit -Name "Users"        -Path $domain
New-ADOrganizationalUnit -Name "Groups"       -Path $domain

# Sub-OUs under Users
New-ADOrganizationalUnit -Name "Admins"           -Path "OU=Users,$domain"
New-ADOrganizationalUnit -Name "Standard Users"   -Path "OU=Users,$domain"
New-ADOrganizationalUnit -Name "Service Accounts" -Path "OU=Users,$domain"

# Sub-OUs under Groups
New-ADOrganizationalUnit -Name "Security Groups"     -Path "OU=Groups,$domain"
New-ADOrganizationalUnit -Name "Distribution Groups" -Path "OU=Groups,$domain"
```

---

## Step 6 — Create Test User Accounts

```powershell
$password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

New-ADUser -Name "John Smith" `
  -SamAccountName "jsmith" `
  -UserPrincipalName "jsmith@yourdomain.com" `
  -Path "OU=Standard Users,OU=Users,DC=lab,DC=local" `
  -AccountPassword $password `
  -Enabled $true

New-ADUser -Name "Admin User" `
  -SamAccountName "adm.admin" `
  -UserPrincipalName "adm.admin@yourdomain.com" `
  -Path "OU=Admins,OU=Users,DC=lab,DC=local" `
  -AccountPassword $password `
  -Enabled $true
```

---

## Step 7 — Verify AD Installation

```powershell
# Check AD services are running
Get-Service adws, kdc, netlogon, dns

# Confirm domain info
Get-ADDomain

# List domain controllers
Get-ADDomainController -Filter *

# Test DNS resolution
Resolve-DnsName lab.local
```

---

## Validation Checklist

- [ ] Server promoted to Domain Controller successfully
- [ ] AD DS and DNS services running
- [ ] Domain resolves correctly via DNS
- [ ] OU structure created as planned
- [ ] Test user accounts created with routable UPN (`@yourdomain.com`)
- [ ] Can log in with domain admin credentials
