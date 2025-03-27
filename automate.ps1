# Define the directory and log file where all actions and outputs will be recorded
$LogDir = ".\logs"
$LogFile = "$LogDir\system_maintenance.log"

# Ensure the log directory exists; create it if it doesn't
If (-Not (Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir | Out-Null
}

# Define placeholders for system log files
$AuthLog = ".\auth.log"
$SysLog = ".\syslog"

# Ensure the log files exist; create them if they don't
If (-Not (Test-Path -Path $AuthLog)) {
    New-Item -ItemType File -Path $AuthLog | Out-Null
    Write-Host "ℹ️ Created placeholder for auth.log" | Tee-Object -FilePath $LogFile -Append
}

If (-Not (Test-Path -Path $SysLog)) {
    New-Item -ItemType File -Path $SysLog | Out-Null
    Write-Host "ℹ️ Created placeholder for syslog" | Tee-Object -FilePath $LogFile -Append
}

# Array of critical services to monitor and restart if necessary
$CriticalServices = @("W32Time", "wuauserv")  # Add more services as required

# Resource usage thresholds for alerts (percentage)
$DiskThreshold = 80   # Disk usage threshold
$CPUThreshold = 75    # CPU usage threshold
$MemThreshold = 75    # Memory usage threshold

# Function to log messages with a timestamp
Function Log {
    Param (
        [string]$Message
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Message"
    Write-Host $LogMessage
    Add-Content -Path $LogFile -Value $LogMessage
}

# Function to monitor system resources (CPU, memory, and disk usage)
Function Monitor-System {
    Log "Starting system monitoring..."
    
    # Gather CPU usage
    $CPUUsage = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    
    # Gather memory usage
    $Memory = Get-WmiObject Win32_OperatingSystem
    $MemUsage = [math]::Round((1 - ($Memory.FreePhysicalMemory / $Memory.TotalVisibleMemorySize)) * 100, 2)
    
    # Gather disk usage for the C: drive
    $Disk = Get-PSDrive -Name C
    $DiskUsage = [math]::Round((($Disk.Used / $Disk.Used + $Disk.Free) * 100), 2)
    
    # Log current resource usage
    Log "CPU Usage: $CPUUsage% | Memory Usage: $MemUsage% | Disk Usage: $DiskUsage%"

    # Check thresholds
    If ($CPUUsage -gt $CPUThreshold) {
        Log "⚠️ High CPU Usage detected: $CPUUsage%"
    }
    If ($MemUsage -gt $MemThreshold) {
        Log "⚠️ High Memory Usage detected: $MemUsage%"
    }
    If ($DiskUsage -gt $DiskThreshold) {
        Log "⚠️ Disk Usage exceeded threshold: $DiskUsage%"
    }
}

# Function to analyze system logs for potential issues
Function Analyze-Logs {
    Log "Analyzing system logs for potential security and error issues..."
    
    # Simulate counting failed login attempts and system errors
    $FailedLogins = (Select-String -Path $AuthLog -Pattern "Failed password" | Measure-Object).Count
    $SystemErrors = (Select-String -Path $SysLog -Pattern "error" | Measure-Object).Count

    Log "Failed SSH logins: $FailedLogins | System Errors: $SystemErrors"

    If ($FailedLogins -gt 5) {
        Log "🚨 Multiple failed SSH login attempts detected!"
    }
    If ($SystemErrors -gt 10) {
        Log "⚠️ High number of system errors detected!"
    }
}

# Function to clean up temporary files
Function Optimize-Performance {
    Log "Cleaning up temporary files..."
    
    # Delete files from Temp directory older than 7 days
    $TempDir = "$env:TEMP"
    Get-ChildItem -Path $TempDir -Recurse | Where-Object { $_.LastAccessTime -lt (Get-Date).AddDays(-7) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Log "Temporary files older than 7 days have been deleted."

    # Check critical services
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
}

# Function to apply system updates
Function Apply-Updates {
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
}

# Main function to execute all maintenance tasks in sequence
Function Main {
    Log "===== System Maintenance Script Started ====="
    Monitor-System
    Analyze-Logs
    Optimize-Performance
    Apply-Updates
    Log "===== System Maintenance Script Completed ====="
}

# Execute the Main function
Main
