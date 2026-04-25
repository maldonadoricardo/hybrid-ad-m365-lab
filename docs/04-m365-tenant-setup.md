# 04 — Microsoft 365 Tenant Setup

## Overview

This section covers setting up a Microsoft 365 tenant, verifying a custom domain, assigning licenses, and configuring admin roles in preparation for hybrid identity sync.

---

## Step 1 — Create the M365 Tenant

1. Go to [https://admin.microsoft.com](https://admin.microsoft.com) or sign up at [https://www.microsoft.com/microsoft-365/business](https://www.microsoft.com/microsoft-365/business)
2. Choose a plan (or start a free trial — E3 trial provides 30 days)
3. Create the tenant using a **work email** (do not use a personal Gmail/Hotmail)
4. Your initial tenant domain will be: `yourtenant.onmicrosoft.com`

> **Tip:** For lab purposes, the Microsoft 365 Developer Program offers a free 90-day E5 sandbox at [https://developer.microsoft.com/microsoft-365/dev-program](https://developer.microsoft.com/microsoft-365/dev-program)

---

## Step 2 — Add a Custom Domain

A routable custom domain is required for Entra Connect UPN matching.

1. In **Microsoft 365 Admin Center** → **Settings** → **Domains** → **Add Domain**
2. Enter your domain (e.g., `yourdomain.com`)
3. Choose **Add a TXT record** for verification
4. Copy the TXT value provided (e.g., `MS=msXXXXXXXX`)
5. Add the TXT record to your DNS registrar (or your internal DNS if you control the zone)
6. Click **Verify** in the Admin Center

---

## Step 3 — Assign Licenses

```
Admin Center → Users → Active Users → Select a user → Licenses and Apps
```

| User | License Assigned |
|------|-----------------|
| Global Admin | M365 E3 / Business Premium |
| Test User 1 | M365 Business Basic (or E3) |
| Test User 2 | M365 Business Basic (or E3) |

> For Entra Connect sync, licenses are assigned **after** users are synced from on-prem AD.

---

## Step 4 — Configure Admin Roles

| Role | Assigned To | Purpose |
|------|-------------|---------|
| Global Administrator | Initial tenant admin | Full tenant control |
| User Administrator | Service account | Manage users/licenses |
| Exchange Administrator | As needed | Manage Exchange Online |
| Intune Administrator | As needed | Manage device enrollment |

To assign roles:

```
Admin Center → Users → Active Users → Select user → Manage roles
```

---

## Step 5 — Enable Security Defaults (or Conditional Access)

For a lab environment, decide whether to use **Security Defaults** (simpler) or **Conditional Access** (enterprise-like):

- **Security Defaults**: Enabled by default on new tenants — enforces MFA for all users
- **Conditional Access**: Requires Entra ID P1/P2 license; provides more granular control

For lab purposes, you may disable Security Defaults temporarily to simplify initial sync testing:

```
Entra Admin Center → Properties → Manage Security Defaults → Disabled
```

> Re-enable after testing is complete.

---

## Step 6 — Verify Tenant Settings

| Setting | Expected Value |
|---------|---------------|
| Tenant Domain | yourtenant.onmicrosoft.com |
| Custom Domain | yourdomain.com (Verified) |
| Directory Sync | Will show "Enabled" after Entra Connect is installed |
| MFA Status | Enabled via Security Defaults or Conditional Access |

---

## Validation Checklist

- [ ] Tenant created and accessible at admin.microsoft.com
- [ ] Custom domain added and verified (status = Verified)
- [ ] Global admin account secured (strong password + MFA)
- [ ] Test user accounts created manually (pre-sync)
- [ ] Licenses assigned to admin account
- [ ] Admin roles configured appropriately
- [ ] Ready for Entra Connect installation
