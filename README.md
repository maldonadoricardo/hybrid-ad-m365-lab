# Hybrid Active Directory & Microsoft 365 Lab

[![Lab Status](https://img.shields.io/badge/Lab%20Status-Active-brightgreen)](https://github.com/maldonadoricardo/hybrid-ad-m365-lab)
[![Platform](https://img.shields.io/badge/Platform-Windows%20Server%20%7C%20Microsoft%20365-blue)](https://github.com/maldonadoricardo/hybrid-ad-m365-lab)
[![Identity](https://img.shields.io/badge/Identity-Entra%20Connect-purple)](https://github.com/maldonadoricardo/hybrid-ad-m365-lab)

## Overview

This repository documents a hands-on home lab environment that simulates a real-world enterprise setup combining an on-premises **Active Directory Domain Controller** with a **hybrid Microsoft 365 / Entra ID (Azure AD) tenant**. The lab is designed to replicate configurations encountered in production system administrator roles.

---

## Lab Goals

- Deploy and configure a Windows Server Active Directory Domain Controller from scratch
- Set up a Microsoft 365 tenant with custom domain verification
- Establish hybrid identity using **Microsoft Entra Connect** (formerly Azure AD Connect)
- Sync on-premises AD users and groups to Entra ID / M365
- Validate hybrid sign-in, device management, and optional workloads (Exchange, Teams)
- Document all steps in a format usable as an operations runbook

---

## Architecture

```
┌──────────────────────────────────┐          ┌──────────────────────────────────┐
│        On-Premises Network       │          │     Microsoft 365 / Entra ID     │
│                                  │          │                                  │
│  ┌──────────────┐                │  HTTPS   │  ┌──────────────────────────┐   │
│  │  Domain      │                │◄────────►│  │  Entra ID (Azure AD)     │   │
│  │  Controller  │                │          │  │  Tenant                  │   │
│  │  (AD DS/DNS) │                │          │  └──────────────────────────┘   │
│  └──────┬───────┘                │          │                                  │
│         │                        │          │  ┌──────────────────────────┐   │
│  ┌──────▼───────┐                │          │  │  Exchange Online         │   │
│  │  Entra       │────────────────┼─────────►│  │  Teams / SharePoint      │   │
│  │  Connect     │   Sync Agent   │          │  │  Intune (optional)       │   │
│  └──────────────┘                │          │  └──────────────────────────┘   │
│                                  │          │                                  │
│  ┌──────────────┐                │          │                                  │
│  │  Client VMs  │                │          │                                  │
│  │  (Win 10/11) │                │          │                                  │
│  └──────────────┘                │          │                                  │
└──────────────────────────────────┘          └──────────────────────────────────┘
```

---

## Repository Structure

```
hybrid-ad-m365-lab/
│
├── README.md                          # This file — project overview
├── docs/
│   ├── 01-environment-overview.md     # Network topology, VM inventory, IP plan
│   ├── 02-ad-domain-controller.md     # On-prem AD DS installation and config
│   ├── 03-dns-configuration.md        # DNS zones, records, and forwarders
│   ├── 04-m365-tenant-setup.md        # M365 tenant creation and domain verification
│   ├── 05-entra-connect-setup.md      # Entra Connect install, sync config, validation
│   ├── 06-optional-workloads.md       # Exchange hybrid, Teams, Hybrid Join, Intune
│   └── 07-operations-runbook.md       # Onboarding, troubleshooting, teardown steps
└── scripts/
    ├── New-LabUsers.ps1               # PowerShell: bulk create test AD users
    ├── Verify-SyncStatus.ps1          # PowerShell: check Entra Connect sync health
    └── Set-OUStructure.ps1            # PowerShell: create standard OU layout
```

---

## Documentation Sections

| # | Section | Description |
|---|---------|-------------|
| 1 | [Environment Overview](docs/01-environment-overview.md) | VM inventory, IPs, OS versions, network topology |
| 2 | [AD Domain Controller](docs/02-ad-domain-controller.md) | AD DS role installation, domain promotion, DNS |
| 3 | [DNS Configuration](docs/03-dns-configuration.md) | Forward/reverse zones, conditional forwarders |
| 4 | [M365 Tenant Setup](docs/04-m365-tenant-setup.md) | Tenant creation, domain verification, licensing |
| 5 | [Entra Connect](docs/05-entra-connect-setup.md) | Install, OU filtering, sync rules, validation |
| 6 | [Optional Workloads](docs/06-optional-workloads.md) | Exchange Hybrid, Hybrid Join, Teams |
| 7 | [Operations Runbook](docs/07-operations-runbook.md) | User onboarding, sync troubleshooting, teardown |

---

## Technologies Used

| Category | Technology |
|----------|-----------|
| Hypervisor | Hyper-V / VMware Workstation / VirtualBox |
| Server OS | Windows Server 2022 |
| Directory Services | Active Directory Domain Services (AD DS) |
| DNS | Windows DNS Server |
| Cloud Identity | Microsoft Entra ID (Azure AD) |
| Identity Sync | Microsoft Entra Connect |
| Productivity Suite | Microsoft 365 (Exchange Online, Teams, SharePoint) |
| Device Management | Microsoft Intune (optional) |
| Scripting | PowerShell |

---

## Skills Demonstrated

- Active Directory design, deployment, and administration
- DNS configuration and troubleshooting
- Microsoft 365 tenant management and licensing
- Hybrid identity architecture with Entra Connect
- PowerShell scripting for user provisioning and automation
- Enterprise network topology planning
- Documentation and runbook creation

---

## Status

> This lab is actively being built and documented. Sections will be updated as each phase is completed.

---

*Built by [Ricardo Maldonado](https://github.com/maldonadoricardo) — Aspiring Systems Administrator*
