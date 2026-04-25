<#
.SYNOPSIS
    Creates bulk test users in Active Directory for the hybrid lab.

.DESCRIPTION
    Creates a set of test users across different OUs with routable UPN suffixes
    suitable for syncing to Microsoft 365 via Entra Connect.

.PARAMETER Domain
    The AD domain in DN format (default: DC=lab,DC=local)

.PARAMETER UPNSuffix
    The routable UPN suffix for M365 sign-in (e.g., yourdomain.com)

.PARAMETER DefaultPassword
    Default password for all test accounts

.EXAMPLE
    .\New-LabUsers.ps1 -UPNSuffix "yourdomain.com"
#>

param(
    [string]$Domain        = "DC=lab,DC=local",
    [string]$UPNSuffix     = "yourdomain.com",
    [string]$DefaultPassword = "P@ssw0rd123!"
)

$SecurePassword = ConvertTo-SecureString $DefaultPassword -AsPlainText -Force

$Users = @(
    @{ GivenName="John";   Surname="Smith";   Sam="jsmith";   OU="Standard Users"; Dept="IT";          Title="Help Desk Technician" },
    @{ GivenName="Maria";  Surname="Garcia";  Sam="mgarcia";  OU="Standard Users"; Dept="HR";          Title="HR Coordinator" },
    @{ GivenName="Kevin";  Surname="Lee";     Sam="klee";     OU="Standard Users"; Dept="Finance";     Title="Financial Analyst" },
    @{ GivenName="Sarah";  Surname="Johnson"; Sam="sjohnson"; OU="Standard Users"; Dept="Operations";  Title="Operations Manager" },
    @{ GivenName="Admin";  Surname="User";    Sam="adm.admin";OU="Admins";         Dept="IT";          Title="System Administrator" },
    @{ GivenName="Svc";    Surname="Sync";    Sam="svc.sync"; OU="Service Accounts";Dept="IT";         Title="Entra Connect Service Account" }
)

foreach ($User in $Users) {
    $UPN  = "$($User.Sam)@$UPNSuffix"
    $Path = "OU=$($User.OU),OU=Users,$Domain"
    $Name = "$($User.GivenName) $($User.Surname)"

    try {
        New-ADUser `
            -Name              $Name `
            -GivenName         $User.GivenName `
            -Surname           $User.Surname `
            -SamAccountName    $User.Sam `
            -UserPrincipalName $UPN `
            -Path              $Path `
            -Department        $User.Dept `
            -Title             $User.Title `
            -AccountPassword   $SecurePassword `
            -Enabled           $true `
            -ErrorAction Stop

        Write-Host "[+] Created: $Name ($UPN)" -ForegroundColor Green
    }
    catch {
        Write-Host "[-] Failed to create $Name : $_" -ForegroundColor Red
    }
}

Write-Host "`nUser creation complete. Run 'Start-ADSyncSyncCycle -PolicyType Delta' to sync to M365." -ForegroundColor Cyan
