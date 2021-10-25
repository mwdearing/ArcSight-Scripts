# --------------------------------------------------------------------------------------------------------------------------------------------- #
# ------------------------------------------------- Removing Stale Connector Files ------------------------------------------------------------ #
# ------------------------------------------------- Added by Michael Dearing 20211019 --------------------------------------------------------- #
# --------------------------------------------------------------------------------------------------------------------------------------------- #
# User editable area: 
$ageout = "-1"
$currentDate = Get-Date
$oldfile = $currentDate.AddDays($ageout)
$service = "arc_connector_2"
$logpath = "F:\arcsight\connectors\connector_2\current\logs"
$adpath = "F:\arcsight\connectors\connector_2\current\user\agent\agentdata"
$runpath = "F:\arcsight\connectors\connector_2\current\run"
$tail = "F:\arcsight\connectors\connector_2\current\logs\agent.out.wrapper.log"

# Force stopping the service before checking and allowing user to kill individual processes related to the service. 
Write-Host("Stopping " + $service)
Stop-Service -Name $service -Force -PassThru
Write-Host "Waiting to make sure service is in 'Stopped' state"
Start-Sleep -Seconds 20
# Validating the service stopped and if not then the ability to kill individual processes kick in.
$servchk = Get-Service -Name $service
if ($servchk.Status -ne 'Stopped'){
    Get-WmiObject win32_process -Filter "name='wrapper.exe'" | Format-List -Property Name, Path, ProcessID # Queries the host for any wrapper.exe's if service fails to stop.
    Write-Host ""
    $wp = read-host -Prompt "Enter the process ID of the connector asssociated with this wrapper process" 
    Write-Host ""
    Get-WmiObject win32_process -Filter "name='java.exe'" | Format-List -Property Name, Path, ProcessID # Queries the host for any java.exe's if service fails to stop. 
    Write-Host ""
    $jp = Read-Host -Prompt "Enter the process ID of the connector associated with this java process"
    # Killing the process with a confirmation prompt so the user doesn't mistankenly kill the wrong service.
    Stop-Process -Id $wp -Confirm -PassThru

    # Killing the process with a confirmation prompt so the user doesn't mistankenly kill the wrong service.
    Stop-Process -Id $jp -Confirm -PassThru
    Start-Sleep -Seconds 5
}

# Removes stale cache files out of the \current\user\agent\agentdata\
Write-Host "Cleaning \agentdata\ folder of stale cache files..."
Write-Host ""
Get-ChildItem -Path $adpath | Where-Object { $_.LastWriteTime -lt $oldfile } | Remove-Item
Start-Sleep -Seconds 2

# Removes HeapDumps from log dir
Write-Host "Removing HeapDump Files"
Write-Host ""
Get-ChildItem -Path $logpath | Where-Object { $_.Name.StartsWith("HeapDump")} | Remove-Item
Start-Sleep -Seconds 2

# Removes Threaddump files from log dir
Write-Host "Removing Threaddump files"
Get-ChildItem -Path $logpath | Where-Object { $_.Name.StartsWith("Thread")} | Remove-Item
Start-Sleep -Seconds 2

# Removes any lock files that may be present from killing the service.
Write-Host "Removing any agent.lock files so connector can be started."
Write-Host ""
Get-ChildItem -Path $runpath | Where-Object {$_.Name.EndsWith(".lock")} | Remove-Item
Start-Sleep -Seconds 2


Write-Host "Starting Connector Service."
Write-Host ""
# Lanching the services MMC so connector can be started. 
Start-Service -Name $service -PassThru

# Tailing agent.out.wrapper.log file to make sure connector comes up fully
Write-Host "Tailing agent.out.wrapper.log"
start-sleep -Seconds 2
Get-Content -Path $tail -Wait -Tail 20  
