# 03 — DNS Configuration

## Overview

Active Directory depends heavily on DNS. This section documents the DNS configuration on the Domain Controller, including forward/reverse lookup zones, SRV records, and external forwarders.

---

## DNS Zones Created Automatically by AD DS

When AD DS is installed and DNS is integrated, the following zones are auto-created:

| Zone | Type | Purpose |
|------|------|---------|
| `lab.local` | Primary / AD-Integrated | Forward lookup for internal domain |
| `_msdcs.lab.local` | AD-Integrated | SRV records for AD services (Kerberos, LDAP, GC) |

---

## Step 1 — Verify DNS Zones

```powershell
# List all DNS zones
Get-DnsServerZone

# Check that SRV records exist for AD
Resolve-DnsName -Name _ldap._tcp.lab.local -Type SRV
Resolve-DnsName -Name _kerberos._tcp.lab.local -Type SRV
```

---

## Step 2 — Create Reverse Lookup Zone

```powershell
Add-DnsServerPrimaryZone -NetworkID "192.168.x.0/24" -ReplicationScope "Forest"
```

Then add a PTR record for the DC:

```powershell
Add-DnsServerResourceRecordPtr `
  -ZoneName "x.168.192.in-addr.arpa" `
  -Name "x" `          # last octet of DC's IP
  -PtrDomainName "dc01.lab.local."
```

---

## Step 3 — Set DNS Forwarders

DNS forwarders allow internal clients to resolve external (internet) names:

```powershell
Set-DnsServerForwarder -IPAddress "8.8.8.8","8.8.4.4" -PassThru
```

Verify:

```powershell
Get-DnsServerForwarder
```

---

## Step 4 — Conditional Forwarder for M365 (Optional)

If you need to resolve Microsoft cloud domains internally:

```powershell
Add-DnsServerConditionalForwarderZone `
  -Name "microsoftonline.com" `
  -MasterServers "8.8.8.8"
```

---

## Step 5 — Add DNS TXT Record for M365 Domain Verification

When verifying your custom domain in M365 Admin Center, you'll receive a TXT record to add:

```powershell
Add-DnsServerResourceRecord `
  -ZoneName "yourdomain.com" `
  -Txt `
  -Name "@" `
  -DescriptiveText "MS=msXXXXXXXX"   # Value from M365 Admin Center
```

> **Note:** If your DNS is hosted externally (GoDaddy, Cloudflare, etc.), add this record through your registrar's portal instead.

---

## Common DNS Records for M365

After domain verification, add these records for Exchange Online / Teams:

| Type | Name | Value | TTL |
|------|------|-------|-----|
| MX | @ | yourtenant.mail.protection.outlook.com | 3600 |
| TXT | @ | v=spf1 include:spf.protection.outlook.com -all | 3600 |
| CNAME | autodiscover | autodiscover.outlook.com | 3600 |
| CNAME | lyncdiscover | webdir.online.lync.com | 3600 |
| CNAME | sip | sipdir.online.lync.com | 3600 |
| SRV | _sip._tls | sipdir.online.lync.com (port 443) | 3600 |
| SRV | _sipfederationtls._tcp | sipfed.online.lync.com (port 5061) | 3600 |

---

## Validation Checklist

- [ ] `lab.local` forward lookup zone exists and is AD-integrated
- [ ] SRV records for `_ldap` and `_kerberos` resolve correctly
- [ ] Reverse lookup zone created and PTR records added
- [ ] DNS forwarders set to external resolvers
- [ ] Internet name resolution works from DC (`nslookup google.com`)
- [ ] M365 TXT verification record added (if using external DNS)
