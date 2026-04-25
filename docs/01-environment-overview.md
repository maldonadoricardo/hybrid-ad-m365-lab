# 01 — Environment Overview

## Lab Purpose

This lab simulates a small-to-medium enterprise environment using a hybrid identity model. All resources are hosted locally on a hypervisor with internet connectivity to Microsoft 365 cloud services.

---

## Network Topology

| Component | Role |
|-----------|------|
| Domain Controller | AD DS, DNS, Entra Connect host |
| Client VM(s) | Windows 10/11 workstations joined to the domain |
| M365 Tenant | Cloud identity and productivity workloads |

> **Note:** Update this table with your actual server names, IPs, and OS versions as you complete each build phase.

---

## VM Inventory

| VM Name | Role | OS | vCPU | RAM | IP Address |
|---------|------|----|------|-----|------------|
| DC01 | Domain Controller / DNS | Windows Server 2022 | 2 | 4 GB | 192.168.x.x |
| ENTRA-SYNC | Entra Connect (optional separate VM) | Windows Server 2022 | 2 | 4 GB | 192.168.x.x |
| CLIENT01 | Domain-joined workstation | Windows 11 Pro | 2 | 4 GB | DHCP |

> Fill in actual values from your environment.

---

## IP Addressing Plan

| Subnet | Purpose |
|--------|---------|
| 192.168.x.0/24 | Lab LAN |
| Gateway | 192.168.x.1 |
| DNS (Primary) | 192.168.x.x (DC01) |
| DNS (Forwarder) | 8.8.8.8 |

---

## AD Forest / Domain Design

| Setting | Value |
|---------|-------|
| Forest Root Domain | lab.local (or your domain) |
| NetBIOS Name | LAB |
| UPN Suffix (on-prem) | lab.local |
| UPN Suffix (routable, for M365) | yourdomain.com |
| Forest Functional Level | Windows Server 2016 or higher |
| Domain Functional Level | Windows Server 2016 or higher |

---

## Microsoft 365 Tenant

| Setting | Value |
|---------|-------|
| Tenant Name | yourtenant.onmicrosoft.com |
| Custom Domain | yourdomain.com |
| Licenses | Microsoft 365 Business / E3 (trial or purchased) |
| Entra Connect Server | DC01 or dedicated VM |

---

## OU Structure

```
lab.local
├── Domain Controllers
├── Servers
├── Workstations
├── Users
│   ├── Admins
│   ├── Standard Users
│   └── Service Accounts
└── Groups
    ├── Security Groups
    └── Distribution Groups
```

---

## Logical Diagram

```
Internet
    │
    ▼
[Router / Firewall]
    │
    ├──► [DC01] (AD DS, DNS, Entra Connect)
    │         │
    │         └──► Syncs to Entra ID via HTTPS
    │
    ├──► [CLIENT01] (Domain Joined)
    │
    └──► Microsoft 365 Cloud Tenant
              ├── Entra ID (Synced Users)
              ├── Exchange Online
              ├── Teams / SharePoint
              └── Intune (optional)
```
