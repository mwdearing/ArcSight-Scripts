#-----------------------------------------------
#
#   Windows ArcSight SmartConnector Restart Script
#
#   Created on: 09 MAR 2022
#   Created By: Michael Dearing
#
#   Version Notes:
#   3.0 : 09/05/2022 - Display count of each file type deleted. Added funtion and cleaned up a ton of code. 
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
$service = ""
$base = ""
$logpath = "\logs"
$adpath = "\user\agent\agentdata"
$runpath = "\run"
$tail = "\logs\agent.out.wrapper.log"
 

#################################
#           Functions           #
#################################
# Force stopping the service before checking and allowing user to kill individual processes related to the service. 
Function Invoke-ProcKill {
    Param([int]$ppid)
    Write-Host "Stopping $ppid"
    Get-CimInstance Win32_Process | Where-Object { $_.ParentProcessId -eq $ppid } | ForEach-Object { Invoke-ProcKill $_.ProcessId }
    Stop-Process -Id $ppid -Force
}
# Stopping process in separate window then waiting 10 seconds before force killing process.
Function Stop-ArcSvc {
    Write-Host "Stopping $service. Please wait..."
    Start-Process PowerShell.exe -ArgumentList "-noexit", "-command Stop-Service $service; exit" -WindowStyle Minimized
    Start-Sleep -Seconds 15
    $mypid = 0
    $myProcessToKill = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)
    if ($myProcessToKill -eq "") {
        Write-Host "$service stopped cleanly."
    } else {
        $mypid = (Get-CimInstance -Class Win32_Service -Filter "Name LIKE '$service'" | Select-Object -ExpandProperty ProcessId)
        Write-Host "The $service PID is: $mypid"
        if ($mypid -gt 1) {
            Write-Host "Killing $service and all of it's child processes..."
            Invoke-ProcKill $mypid
        }
    }
    Write-Host "$service is now stopped.."
}

#################################
#         User Selection        #
#################################
$selection = Read-Host -Prompt 'Enter (1)-WINC   (2)-Sysmon   (3)-PowerShell'
# Setting variables based on selection. 
if ($selection -eq '1')
{   $service = $winc
    $base = $wincb} 
elseif ($selection -eq '2')
{    $service = $sysmon
    $base = $sysmonb}
elseif ($selection -eq '3')
{    $service = $powershell
    $base = $psb}
else 
{   Write-Output "Incorrect Selection. Exiting..."
    Start-Sleep -Seconds 2
    Exit}
# Verifying user wants to stop the service. 
$answer = Read-Host -Prompt "You are about to stop $service, do you wish to continue? [y/n]"
if ($answer -imatch 'y')
{    Stop-ArcSvc}
else 
{   Write-Host "Script will now exit..."
    Exit}

#################################
#         Script Execution      #
#################################
# Removes stale cache files out of the \current\user\agent\agentdata\
$oldcache = Get-ChildItem -Path $base$adpath | Where-Object { $_.LastWriteTime -lt (get-date).AddDays(-1) }
$oldcachecount = $oldcache | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "Removing $oldcachecount stale cache files."
$oldcache | Remove-Item
$sizedflt = Get-ChildItem -Path $base$adpath | Where-Object { $_.Name.EndsWith(".size.dflt") } 
$sizedflt | Remove-Item
Start-Sleep -Seconds 1
# Removes HeapDumps from log dir
$heapdump = Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("HeapDump") }
$heapdumpcount = $heapdump |  Measure-Object | Select-Object -ExpandProperty Count
Write-Host "Removing $heapdumpcount HeapDump files."
$heapdump | Remove-Item
Start-Sleep -Seconds 1
# Removes Threaddump files from log dir
$threaddump = Get-ChildItem -Path $base$logpath | Where-Object { $_.Name.StartsWith("Thread") } 
$threaddumpcount = $threaddump | Measure-Object | Select-Object -ExpandProperty Count
Write-Host "Removing $threaddumpcount Threaddump files"
$threaddump | Remove-Item
# Removes any lock files that may be present from killing the service.
Write-Host "Removing agent.lock files."
Get-ChildItem -Path $base$runpath | Where-Object { $_.Name.EndsWith(".lock") } | Remove-Item
Write-Host "Starting $service. Please wait..."
# Starting service in new window to keep main output clean.
Start-Process PowerShell.exe -ArgumentList "-noexit", "-command Start-Service $service; exit" -WindowStyle Minimized
# Tailing agent.out.wrapper.log file to make sure connector comes up fully
Write-Host "Tailing agent.out.wrapper.log"
start-sleep -Seconds 1
Get-Content -Path $base$tail -Wait -Tail 1
