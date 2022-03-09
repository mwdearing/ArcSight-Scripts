#-----------------------------------------------
#
#   Windows ArcSight SmartConnector Restart Script
#
#   Created on: 09 MAR 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   2.0 : 09/03/2022 - New way of killing processes and the wrappers subprocesses.
#
#-----------------------------------------------
# User editable area: 
$ageout = "-1"
$currentDate = Get-Date
$oldfile = $currentDate.AddDays($ageout)
$service = ""
$base = ""
$logpath = "\logs"
$adpath = "\user\agent\agentdata"
$runpath = "\run"
$tail = "\logs\agent.out.wrapper.log"
# Force stopping the service before checking and allowing user to kill individual processes related to the service. 
function fkproc {
    Param([int]$ppid)
    Write-Output "Stopping $ppid"
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid } | ForEach-Object { fkproc $_.ProcessId }
    Stop-Process -Id $ppid -Force
}
$selection = Read-Host -Prompt 'Enter (1)-WINC   (2)-Sysmon: '
Write-Host ""
if ($selection -eq '1'){
    $service = "arc_Container_1"
    $base = 'F:\ArcSight Containers\Container 1\current'
} else {
    $service = "arc_Container_2"
    $base = 'F:\ArcSight Containers\Container 2\current'
}
$mypid = 0
$myProcessToKill = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)

if ($myProcessToKill -eq "") {
    Write-Output "$service is not running."
} else {
    $mypid = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)
    Write-Output "The $service PID is: $mypid"
    if ($mypid -gt 1) {
        Write-Output "Killing $service and all of it's child processes..."
        fkproc $mypid
    }
}
Write-Output ""
Write-Output "$service is now stopped.."
Write-Output ""

# Removes stale cache files out of the \current\user\agent\agentdata\
Write-Output "Cleaning stale cache files."
Write-Output ""
Get-ChildItem -Path $base$adpath | Where-Object { $_.LastWriteTime -lt $oldfile } | Remove-Item
Start-Sleep -Seconds 2

# Removes HeapDumps from log dir
Write-Output "Removing HeapDump Files"
Write-Output ""
Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("HeapDump") } | Remove-Item
Start-Sleep -Seconds 2

# Removes Threaddump files from log dir
Write-Output "Removing Threaddump files"
Write-Output ""
Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("Thread") } | Remove-Item
Start-Sleep -Seconds 2

# Removes any lock files that may be present from killing the service.
Write-Output "Removing agent.lock files."
Write-Output ""
Get-ChildItem -Path $base$runpath | Where-Object { $_.Name.EndsWith(".lock") } | Remove-Item
Start-Sleep -Seconds 2


Write-Output "Starting Connector Service."
Write-Output ""
# Lanching the services MMC so connector can be started. 
Start-Service -Name $service

# Tailing agent.out.wrapper.log file to make sure connector comes up fully
Write-Output ""
Write-Output "Tailing agent.out.wrapper.log"
Write-Output ""
start-sleep -Seconds 2
Get-Content -Path $base$tail -Wait -Tail 20  
