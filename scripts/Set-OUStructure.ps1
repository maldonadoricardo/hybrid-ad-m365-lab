<#
.SYNOPSIS
    Creates the standard OU structure for the hybrid lab Active Directory domain.

.DESCRIPTION
    Builds a clean, enterprise-style OU hierarchy suitable for use with
    Entra Connect OU filtering and GPO targeting.

.PARAMETER Domain
    The AD domain in DN format (default: DC=lab,DC=local)

.EXAMPLE
    .\Set-OUStructure.ps1
    .\Set-OUStructure.ps1 -Domain "DC=corp,DC=contoso,DC=com"
#>

param(
    [string]$Domain = "DC=lab,DC=local"
)

function New-OUSafe {
    param([string]$Name, [string]$Path)
    try {
        New-ADOrganizationalUnit -Name $Name -Path $Path -ErrorAction Stop
        Write-Host "[+] Created OU: $Name under $Path" -ForegroundColor Green
    }
    catch [Microsoft.ActiveDirectory.Management.ADException] {
        Write-Host "[~] OU already exists: $Name under $Path" -ForegroundColor Yellow
    }
    catch {
        Write-Host "[-] Error creating OU $Name : $_" -ForegroundColor Red
    }
}

Write-Host "`n=== Creating Lab OU Structure ===" -ForegroundColor Cyan
Write-Host "Domain: $Domain" -ForegroundColor Gray

# Top-level OUs
New-OUSafe -Name "Servers"       -Path $Domain
New-OUSafe -Name "Workstations"  -Path $Domain
New-OUSafe -Name "Users"         -Path $Domain
New-OUSafe -Name "Groups"        -Path $Domain
New-OUSafe -Name "Computers"     -Path $Domain

# Users sub-OUs
New-OUSafe -Name "Admins"           -Path "OU=Users,$Domain"
New-OUSafe -Name "Standard Users"   -Path "OU=Users,$Domain"
New-OUSafe -Name "Service Accounts" -Path "OU=Users,$Domain"

# Groups sub-OUs
New-OUSafe -Name "Security Groups"     -Path "OU=Groups,$Domain"
New-OUSafe -Name "Distribution Groups" -Path "OU=Groups,$Domain"

# Servers sub-OUs
New-OUSafe -Name "Domain Controllers" -Path "OU=Servers,$Domain"
New-OUSafe -Name "Member Servers"     -Path "OU=Servers,$Domain"

Write-Host "`nOU structure created. Verify in Active Directory Users and Computers." -ForegroundColor Cyan
