#-----------------------------------------------
#
#   Windows ArcSight SmartConnector Restart Script
#
#   Created on: 09 MAR 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   2.5 : 06/04/2022 - New way of killing processes and the wrappers subprocesses.
#
#-----------------------------------------------
# User editable area:
$winc = "arc_Connector_2"
$wincb = "F:\arcsight\connectors\connector_2\current"
$sysmon = "arc_Container_5"
$sysmonb = "F:\arcsight\connectors\Container 5\current"
$powershell = "arc_connector_3"
$psb = "F:\arcsight\connectors\connector_3\current"

# DO NOT EDIT 
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

# User selection
$selection = Read-Host -Prompt 'Enter (1)-WINC   (2)-Sysmon   (3)-PowerShell'
Write-Host ""
if ($selection -eq '1'){
    $service = $winc
    $base = $wincb
} 
elseif ($selection -eq '2'){
    $service = $sysmon
    $base = $sysmonb
} 
else {
    $service = $powershell
    $base = $psb
}

# Stopping process in separate window then waiting 10 seconds before force killing process.
Write-Output "Stopping $service. Please wait..."
Start-Process PowerShell.exe -ArgumentList "-noexit", "-command Stop-Service $service; exit" -WindowStyle Minimized
Start-Sleep -Seconds 10
$mypid = 0
$myProcessToKill = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)

if ($myProcessToKill -eq "") {
    Write-Output "$service is not running."
    Write-Output ""
} else {
    $mypid = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)
    Write-Output "The $service PID is: $mypid"
    if ($mypid -gt 1) {
        Write-Output "Killing $service and all of it's child processes..."
        Write-Output ""
        fkproc $mypid
    }
}

Write-Output ""
Write-Output "$service is now stopped.."
Write-Output ""

# Removes stale cache files out of the \current\user\agent\agentdata\
Write-Output "Cleaning stale cache files."
Get-ChildItem -Path $base$adpath | Where-Object { $_.LastWriteTime -lt $oldfile } | Remove-Item
Get-ChildItem -Path $base$adpath | Where-Object { $_.Name.EndsWith(".size.dflt") } | Remove-Item


Start-Sleep -Seconds 1

# Removes HeapDumps from log dir
Write-Output "Removing HeapDump Files"
Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("HeapDump") } | Remove-Item
Start-Sleep -Seconds 1

# Removes Threaddump files from log dir
Write-Output "Removing Threaddump files"
Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("Thread") } | Remove-Item

# Removes any lock files that may be present from killing the service.
Write-Output "Removing agent.lock files."
Get-ChildItem -Path $base$runpath | Where-Object { $_.Name.EndsWith(".lock") } | Remove-Item

Write-Output ""
Write-Output "Starting $service. Please wait..."
Write-Output ""
# Lanching the services MMC so connector can be started.
Write-Output "Starting Service. Please wait..."
Start-Process PowerShell.exe -ArgumentList "-noexit", "-command Start-Service $service; exit" -WindowStyle Minimized
# Start-Service -Name $service

# Tailing agent.out.wrapper.log file to make sure connector comes up fully
Write-Output "Tailing agent.out.wrapper.log"
Write-Output ""
start-sleep -Seconds 1
Get-Content -Path $base$tail -Wait -Tail 1
