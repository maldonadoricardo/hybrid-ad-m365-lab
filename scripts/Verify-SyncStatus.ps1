<#
.SYNOPSIS
    Verifies Microsoft Entra Connect synchronization health.

.DESCRIPTION
    Checks the sync scheduler status, reviews recent sync run results,
    and reports any export errors for the hybrid lab environment.

.EXAMPLE
    .\Verify-SyncStatus.ps1
#>

Import-Module ADSync -ErrorAction Stop

Write-Host "`n=== Entra Connect Sync Health Check ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Gray

# --- Scheduler Status ---
Write-Host "`n[Scheduler Status]" -ForegroundColor Yellow
$Scheduler = Get-ADSyncScheduler
$Scheduler | Select-Object SyncCycleEnabled, NextSyncCycleStartTimeInUTC, NextSyncCyclePolicyType, CurrentlyRunning | Format-List

# --- Last 5 Sync Runs ---
Write-Host "[Last 5 Sync Runs]" -ForegroundColor Yellow
Get-ADSyncRunStepResult | Sort-Object StartDate -Descending | Select-Object -First 5 |
    Select-Object ConnectorName, RunProfileName, StartDate, EndDate, StepResult |
    Format-Table -AutoSize

# --- Export Errors ---
Write-Host "[Connector Export Error Summary]" -ForegroundColor Yellow
$Stats = Get-ADSyncConnectorStatistics
$Stats | Select-Object ConnectorName, ExportErrors | Format-Table -AutoSize

if (($Stats | Measure-Object -Property ExportErrors -Sum).Sum -eq 0) {
    Write-Host "No export errors detected." -ForegroundColor Green
} else {
    Write-Host "Export errors found — check Synchronization Service Manager for details." -ForegroundColor Red
}

# --- Trigger Delta Sync Option ---
$Trigger = Read-Host "`nTrigger a Delta sync now? (Y/N)"
if ($Trigger -eq "Y" -or $Trigger -eq "y") {
    Write-Host "Starting delta sync..." -ForegroundColor Cyan
    Start-ADSyncSyncCycle -PolicyType Delta
    Write-Host "Delta sync started." -ForegroundColor Green
}
