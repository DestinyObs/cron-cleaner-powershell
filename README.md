# Maintenance Script: Keeping Your Windows System in Shape

## Introduction

Welcome, Windows warriors, diligent IT admins, or daring adventurers navigating the labyrinth of updates and services. 🖥️⚡

System maintenance on Windows is just as crucial as on any other platform. It keeps your system efficient, secure, and reliable—avoiding those dreaded "Not Responding" moments. This PowerShell script is your reliable assistant for automating critical tasks like monitoring resource usage, managing essential services, cleaning temporary files, and applying updates.

Think of it as the Windows version of Alfred to your Batman: always prepared, always useful, and quietly keeping chaos at bay.

This guide will walk you through every aspect of the script, demystifying the automation and ensuring you're equipped to unleash its full potential.

---

## Why Is This Important?

### 1. Monitoring Resource Usage
Ever had your Windows system feel sluggish, as if it were asking for a nap? Monitoring resource usage helps you address bottlenecks before your workflow grinds to a halt.

This script keeps tabs on CPU, RAM, and disk usage, alerting you when thresholds are breached.

### 2. Detecting Potential Issues
Windows logs can reveal critical information—failed logins, unexpected errors, and more. Tracking these logs helps safeguard your system from intrusions or stability issues.

This script ensures you won't miss any red flags.

### 3. Keeping Essential Services Alive
Critical services crashing is a recipe for sleepless nights. Whether it’s Windows Time Service or Windows Update, this script monitors and restarts key services to keep your system running smoothly.

### 4. Automating Cleanup and Updates
Clutter and outdated systems are performance kryptonite. This script handles both, cleaning up temporary files and checking for updates to keep your system secure.

---

## Deep Dive Into the Code

### 1. Setting Up Logging

```powershell
$LogDir = ".\logs"
$LogFile = "$LogDir\system_maintenance.log"
```

All actions are logged in a custom directory, ensuring accessibility without elevated permissions. If the directory doesn't exist, the script creates it:

```powershell
If (-Not (Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}
```

### 2. Placeholder Log Files

Placeholders for `auth.log` and `syslog` are created if missing. These files simulate logs for demonstration purposes:

```powershell
$AuthLog = ".\auth.log"
$SysLog = ".\syslog"

If (-Not (Test-Path -Path $AuthLog)) {
    New-Item -ItemType File -Path $AuthLog | Out-Null
    Log "ℹ️ Created placeholder for auth.log."
}

If (-Not (Test-Path -Path $SysLog)) {
    New-Item -ItemType File -Path $SysLog | Out-Null
    Log "ℹ️ Created placeholder for syslog."
}
```

### 3. Defining Important Variables

```powershell
$CriticalServices = @("W32Time", "wuauserv")
$DiskThreshold = 80
$CPUThreshold = 75
$MemThreshold = 75
```

- **CriticalServices**: Lists essential Windows services to monitor (e.g., Windows Time and Windows Update).
- **Thresholds**: Defines limits for resource usage.

### 4. Logging Function

```powershell
Function Log {
    Param ([string]$Message)
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}
```

This function logs messages with timestamps for easy troubleshooting.

### 5. Monitoring System Resources

```powershell
$CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
$Memory = Get-WmiObject Win32_OperatingSystem
$MemUsage = [math]::Round((1 - ($Memory.FreePhysicalMemory / $Memory.TotalVisibleMemorySize)) * 100, 2)
$Disk = Get-PSDrive -Name C
$DiskUsage = [math]::Round((($Disk.Used / $Disk.Used + $Disk.Free) * 100), 2)
```

### 6. Cleaning Up Temporary Files

```powershell
$TempDir = "$env:TEMP"
Get-ChildItem -Path $TempDir -Recurse | Where-Object { $_.LastAccessTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
Log "Temporary files older than 7 days have been deleted."
```

### 7. Restarting Critical Services

```powershell
ForEach ($Service in $CriticalServices) {
    $ServiceStatus = Get-Service -Name $Service
    If ($ServiceStatus.Status -eq 'Running') {
        Log "✅ $Service is running."
    } Else {
        Log "⚠️ $Service is not running. Attempting restart..."
        Try {
            Start-Service -Name $Service
            Log "🔄 Successfully restarted $Service."
        } Catch {
            Log "❌ Failed to restart $Service!"
        }
    }
}
```

### 8. Applying System Updates (Run with Administrator Privileges)

```powershell
If (-Not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Log "⚠️ System updates require elevated permissions. Please run this script as an Administrator."
    Return
}

Log "Applying system updates..."
Try {
    Install-WindowsUpdate -AcceptAll -IgnoreReboot | Out-Null
    Log "✅ System updates completed successfully."
} Catch {
    Log "❌ System updates failed! Check the logs for details."
}
```

### 9. Granting Execution Permissions

Before running the script, ensure it has execution permissions:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

To allow the script to run without issues, you may need to manually grant permissions:

```powershell
Unblock-File -Path "C:\path\to\SystemMaintenance.ps1"
```

### 10. Running Everything in Sequence

```powershell
Function Main {
    Log "===== System Maintenance Script Started ====="
    Monitor-System
    Analyze-Logs
    Optimize-Performance
    Apply-Updates
    Log "===== System Maintenance Script Completed ====="
}
Main
```

---

## Automating with Task Scheduler

To schedule the script:
1. Save it as `SystemMaintenance.ps1`.
2. Open Task Scheduler and create a new task.
3. Set the action to:
   ```powershell
   powershell.exe -ExecutionPolicy Bypass -File "C:\path\to\SystemMaintenance.ps1"
   ```
4. Set a schedule for daily execution.

---

## Final Thoughts

This PowerShell script mirrors the Bash version but adapts it for the Windows ecosystem. It's a simple, efficient way to automate routine tasks and maintain your system's health.

Happy automating! 🖥️⚡

*I’m DestinyObs | iBuild | iDeploy | iSecure | iSustain*

