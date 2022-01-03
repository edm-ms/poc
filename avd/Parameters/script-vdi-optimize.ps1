<#####################################################################################################################################

    This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.  
    THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, 
    INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE.  We grant 
    You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form 
    of the Sample Code, provided that You agree: (i) to not use Our name, logo, or trademarks to market Your software product in 
    which the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product in which the Sample Code 
    is embedded; and (iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, 
    including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.

    Microsoft provides programming examples for illustration only, without warranty either expressed or
    implied, including, but not limited to, the implied warranties of merchantability and/or fitness 
    for a particular purpose. 
 
    This sample assumes that you are familiar with the programming language being demonstrated and the 
    tools used to create and debug procedures. Microsoft support professionals can help explain the 
    functionality of a particular procedure, but they will not modify these examples to provide added 
    functionality or construct procedures to meet your specific needs. if you have limited programming 
    experience, you may want to contact a Microsoft Certified Partner or the Microsoft fee-based consulting 
    line at (800) 936-5200. 

    For more information about Microsoft Certified Partners, please visit the following Microsoft Web site:
    https://partner.microsoft.com/global/30000104 

######################################################################################################################################>

[Cmdletbinding(DefaultParameterSetName="Default")]
Param (
    # Parameter help description
    [ArgumentCompleter( { Get-ChildItem $PSScriptRoot -Directory | Where-Object { $_.Name -ne 'LGPO' } | Select-Object -ExpandProperty Name } )]
    [System.String]$WindowsVersion = (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").ReleaseId,

    [ValidateSet('All','WindowsMediaPlayer','AppxPackages','ScheduledTasks','DefaultUserSettings','Autologgers','Services','NetworkOptimizations','LGPO','DiskCleanup')] 
    [String[]]
    $Optimizations = "All",


    [Switch]$Restart,
    [Switch]$AcceptEULA
)
 
#Requires -RunAsAdministrator
#Requires -PSEdition Desktop

<#
- TITLE:          Microsoft Windows 10 Virtual Desktop Optimization Script
- AUTHORED BY:    Robert M. Smith and Tim Muessig (Microsoft)
- AUTHORED DATE:  11/19/2019
- CONTRIBUTORS:   Travis Roberts (2020), Jason Parker (2020)
- LAST UPDATED:   10/14/2021
- PURPOSE:        To automatically apply settings referenced in the following white papers:
                  https://docs.microsoft.com/en-us/windows-server/remote/remote-desktop-services/rds_vdi-recommendations-1909
                  
- Important:      Every setting in this script and input files are possible recommendations only,
                  and NOT requirements in any way. Please evaluate every setting for applicability
                  to your specific environment. These scripts have been tested on plain Hyper-V
                  VMs. Please test thoroughly in your environment before implementation

- DEPENDENCIES    1. On the target machine, run PowerShell elevated (as administrator)
                  2. Within PowerShell, set exectuion policy to enable the running of scripts.
                     Ex. Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
                  3. LGPO.EXE (available at https://www.microsoft.com/en-us/download/details.aspx?id=55319)
                  4. LGPO database files available in the respective folders (ex. \1909, or \2004)
                  5. This PowerShell script
                  6. The text input files containing all the apps, services, traces, etc. that you...
                     may be interested in disabling. Please review these input files to customize...
                     to your environment/requirements

- REFERENCES:
https://social.technet.microsoft.com/wiki/contents/articles/7703.powershell-running-executables.aspx
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://blogs.technet.microsoft.com/secguide/2016/01/21/lgpo-exe-local-group-policy-object-utility-v1-0/
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-service?view=powershell-6
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/remove-item?view=powershell-6
https://msdn.microsoft.com/en-us/library/cc422938.aspx
#>

<# Categories of cleanup items:
This script is dependent on the following:
LGPO Settings folder, applied with the LGPO.exe Microsoft app

The UWP app input file contains the list of almost all the UWP application packages that can be removed with PowerShell interactively.  
The Store and a few others, such as Wallet, were left off intentionally.  Though it is possible to remove the Store app, 
it is nearly impossible to get it back.  Please review the configuration files and change the 'VDIState' to anything but 'disabled' to keep the item.
#>
BEGIN {
    If  (19043 -lt (Get-ItemProperty "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\").CurrentBuildNumber) {
    $WindowsVersion = '21H2'   
    }

    $baseURI = "https://raw.githubusercontent.com/The-Virtual-Desktop-Team/Virtual-Desktop-Optimization-Tool/main/21H2/ConfigurationFiles"
    $fileList = @('AppxPackages.json','Autologgers.Json','DefaultUserSettings.json','LanManWorkstation.json','ScheduledTasks.json','Services.json')
    $outputPath = "C:\temp"

    if ((Test-Path $outputPath) -ne $true) { New-Item -ItemType Directory -Path $outputPath }

    foreach ($file in $fileList) {
        Invoke-WebRequest "$baseURI/$file" -OutFile "$outputPath\$file"
    }

    If (-not([System.Diagnostics.EventLog]::SourceExists("Virtual Desktop Optimization")))
    {
        # All VDOT main function Event ID's [1-9]
        $EventSources = @('VDOT', 'WindowsMediaPlayer', 'AppxPackages', 'ScheduledTasks', 'DefaultUserSettings', 'Autologgers', 'Services', 'NetworkOptimizations', 'LGPO', 'DiskCleanup')
        New-EventLog -Source $EventSources -LogName 'Virtual Desktop Optimization'
        Limit-EventLog -OverflowAction OverWriteAsNeeded -MaximumSize 64KB -LogName 'Virtual Desktop Optimization'
        Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Log Created"
    }
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "Starting VDOT by $env:USERNAME with the following options:`n$($PSBoundParameters | Out-String)" 

    $StartTime = Get-Date
    $CurrentLocation = Get-Location
    $WorkingLocation = (Join-Path $PSScriptRoot $WindowsVersion)

    try
    {
        Push-Location (Join-Path $PSScriptRoot $WindowsVersion)-ErrorAction Stop
    }
    catch
    {
        $Message = "Invalid Path $WorkingLocation - Exiting Script!"
        Write-EventLog -Message $Message -Source 'VDOT' -EventID 100 -EntryType Error -LogName 'Virtual Desktop Optimization'
        Write-Warning $Message
        Return
    }
}
PROCESS {


    Set-Location $outputPath

    #region Disable, then remove, Windows Media Player including payload
    If ($Optimizations -contains "WindowsMediaPlayer" -or $Optimizations -contains "All") {
        try
        {
            Write-EventLog -EventId 10 -Message "[VDI Optimize] Disable / Remove Windows Media Player" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
            Write-Host "[VDI Optimize] Disable / Remove Windows Media Player" -ForegroundColor Cyan
            Disable-WindowsOptionalFeature -Online -FeatureName WindowsMediaPlayer -NoRestart | Out-Null
            Get-WindowsPackage -Online -PackageName "*Windows-mediaplayer*" | ForEach-Object { 
                Write-EventLog -EventId 10 -Message "Removing $($_.PackageName)" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Information 
                Remove-WindowsPackage -PackageName $_.PackageName -Online -ErrorAction SilentlyContinue -NoRestart | Out-Null
            }
        }
        catch 
        { 
            $msg = ($_ | Format-List | Out-String)
            Write-EventLog -EventId 110 -Message "Disabling / Removing Windows Media Player - $msg" -LogName 'Virtual Desktop Optimization' -Source 'WindowsMediaPlayer' -EntryType Error 
        }
    }
    #endregion

    #region Begin Clean APPX Packages
    If ($Optimizations -contains "AppxPackages" -or $Optimizations -contains "All")
    {
        $AppxConfigFilePath = "$outputPath\AppxPackages.json"
        If (Test-Path $AppxConfigFilePath)
        {
            Write-EventLog -EventId 20 -Message "[VDI Optimize] Removing Appx Packages" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
            Write-Host "[VDI Optimize] Removing Appx Packages" -ForegroundColor Cyan
            $AppxPackage = (Get-Content $AppxConfigFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($AppxPackage.Count -gt 0)
            {
                Foreach ($Item in $AppxPackage)
                {
                    try
                    {                
                        Write-EventLog -EventId 20 -Message "Removing Provisioned Package $($Item.AppxPackage)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Removing Provisioned Package $($Item.AppxPackage)"
                        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -like ("*{0}*" -f $Item.AppxPackage) } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove [All Users] $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -AllUsers -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue 
                        
                        Write-EventLog -EventId 20 -Message "Attempting to remove $($Item.AppxPackage) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Information 
                        Write-Verbose "Attempting to remove $($Item.AppxPackage) - $($Item.Description)"
                        Get-AppxPackage -Name ("*{0}*" -f $Item.AppxPackage) | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null
                    }
                    catch 
                    {
                        $msg = ($_ | Format-List | Out-String)
                        Write-EventLog -EventId 120 -Message "Failed to remove Appx Package $($Item.AppxPackage) - $msg" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Error 
                        Write-Warning "Failed to remove Appx Package $($Item.AppxPackage) - $msg"
                    }
                }
            }
            Else 
            {
                Write-EventLog -EventId 20 -Message "No AppxPackages found to disable" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
                Write-Warning "No AppxPackages found to disable in $AppxConfigFilePath"
            }
        }
        Else 
        {

            Write-EventLog -EventId 20 -Message "Configuration file not found - $AppxConfigFilePath" -LogName 'Virtual Desktop Optimization' -Source 'AppxPackages' -EntryType Warning 
            Write-Warning "Configuration file not found -  $AppxConfigFilePath"
        }
    }
    #endregion

    #region Disable Scheduled Tasks

    # This section is for disabling scheduled tasks.  If you find a task that should not be disabled
    # change its "VDIState" from Disabled to Enabled, or remove it from the json completely.
    If ($Optimizations -contains 'ScheduledTasks' -or $Optimizations -contains 'All') {
        $ScheduledTasksFilePath = "$outputPath\ScheduledTasks.json"
        If (Test-Path $ScheduledTasksFilePath)
        {
            Write-EventLog -EventId 30 -Message "[VDI Optimize] Disable Scheduled Tasks" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
            Write-Host "[VDI Optimize] Disable Scheduled Tasks" -ForegroundColor Cyan
            $SchTasksList = (Get-Content $ScheduledTasksFilePath | ConvertFrom-Json).Where( { $_.VDIState -eq 'Disabled' })
            If ($SchTasksList.count -gt 0)
            {
                Foreach ($Item in $SchTasksList)
                {
                    $TaskObject = Get-ScheduledTask $Item.ScheduledTask
                    If ($TaskObject -and $TaskObject.State -ne 'Disabled')
                    {
                        Write-EventLog -EventId 30 -Message "Attempting to disable Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
                        Write-Verbose "Attempting to disable Scheduled Task: $($TaskObject.TaskName)"
                        try
                        {
                            Disable-ScheduledTask -InputObject $TaskObject | Out-Null
                            Write-EventLog -EventId 30 -Message "Disabled Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Information 
                        }
                        catch
                        {
                            $msg = ($_ | Format-List | Out-String)
                            Write-EventLog -EventId 130 -Message "Failed to disabled Scheduled Task: $($TaskObject.TaskName) - $msg" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Error 
                        }
                    }
                    ElseIf ($TaskObject -and $TaskObject.State -eq 'Disabled') 
                    {
                        Write-EventLog -EventId 30 -Message "$($TaskObject.TaskName) Scheduled Task is already disabled" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
                    }
                    Else
                    {
                        Write-EventLog -EventId 130 -Message "Unable to find Scheduled Task: $($TaskObject.TaskName)" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Error
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 30 -Message "No Scheduled Tasks found to disable" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
            }
        }
        Else 
        {
            Write-EventLog -EventId 30 -Message "File not found! -  $ScheduledTasksFilePath" -LogName 'Virtual Desktop Optimization' -Source 'ScheduledTasks' -EntryType Warning
        }
    }
    #endregion

    #region Customize Default User Profile

    # Apply appearance customizations to default user registry hive, then close hive file
    If ($Optimizations -contains "DefaultUserSettings" -or $Optimizations -contains "All")
    {
        $DefaultUserSettingsFilePath = "$outputPath\DefaultUserSettings.json"
        If (Test-Path $DefaultUserSettingsFilePath)
        {
            Write-EventLog -EventId 40 -Message "Set Default User Settings" -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information
            Write-Host "[VDI Optimize] Set Default User Settings" -ForegroundColor Cyan
            $UserSettings = (Get-Content $DefaultUserSettingsFilePath | ConvertFrom-Json).Where( { $_.SetProperty -eq $true })
            If ($UserSettings.Count -gt 0)
            {
                Write-EventLog -EventId 40 -Message "Processing Default User Settings (Registry Keys)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                Write-Verbose "Processing Default User Settings (Registry Keys)"

                & REG LOAD HKLM\VDOT_TEMP C:\Users\Default\NTUSER.DAT | Out-Null

                Foreach ($Item in $UserSettings)
                {
                    If ($Item.PropertyType -eq "BINARY")
                    {
                        $Value = [byte[]]($Item.PropertyValue.Split(","))
                    }
                    Else
                    {
                        $Value = $Item.PropertyValue
                    }

                    If (Test-Path -Path ("{0}" -f $Item.HivePath))
                    {
                        Write-EventLog -EventId 40 -Message "Found $($Item.HivePath) - $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information        
                        Write-Verbose "Found $($Item.HivePath) - $($Item.KeyName)"
                        If (Get-ItemProperty -Path ("{0}" -f $Item.HivePath) -ErrorAction SilentlyContinue)
                        {
                            try {
                                Write-EventLog -EventId 40 -Message "Set $($Item.HivePath) - $Value" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                                Set-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -Value $Value -Force 
                            } catch {
                                $msg = ($_ | Format-List | Out-String)
                                Write-EventLog -EventId 30 -Message "Set failed for $($Item.HivePath) - $Value - $msg" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Error
                            }
                        }
                        Else
                        {
                            try {
                                Write-EventLog -EventId 40 -Message "New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                                New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                            } catch {
                                $msg = ($_ | Format-List | Out-String)
                                Write-EventLog -EventId 30 -Message "Unable to create New $($Item.HivePath) Name $($Item.KeyName) PropertyType $($Item.PropertyType) Value $Value - $msg" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Error
                            }
                        }
                    }
                    Else
                    {
                        Write-EventLog -EventId 40 -Message "Registry Path not found $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                        Write-EventLog -EventId 40 -Message "Creating new Registry Key $($Item.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Information
                        try {
                            $newKey = New-Item -Path ("{0}" -f $Item.HivePath) -Force
                            $newKey.Handle.Close()
                            New-ItemProperty -Path ("{0}" -f $Item.HivePath) -Name $Item.KeyName -PropertyType $Item.PropertyType -Value $Value -Force | Out-Null
                        } catch {
                            $msg = ($_ | Format-List | Out-String)
                            Write-EventLog -EventId 30 -Message "Error creating new Registry Key $($Item.HivePath): $msg" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Error
                        }
                    }
                }

                [gc]::Collect()
                & REG UNLOAD HKLM\VDOT_TEMP | Out-Null
            }
            Else
            {
                Write-EventLog -EventId 40 -Message "No Default User Settings to set" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Warning
            }
        }
        Else
        {
            Write-EventLog -EventId 40 -Message "File not found: $DefaultUserSettingsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'DefaultUserSettings' -EntryType Warning
        }    }
    #endregion

    #region Disable Windows Traces
    If ($Optimizations -contains "AutoLoggers" -or $Optimizations -contains "All")
    {
        $AutoLoggersFilePath = "$outputPath\Autologgers.Json"
        If (Test-Path $AutoLoggersFilePath)
        {
            Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
            Write-Host "[VDI Optimize] Disable Autologgers" -ForegroundColor Cyan
            $DisableAutologgers = (Get-Content $AutoLoggersFilePath | ConvertFrom-Json).Where( { $_.Disabled -eq 'True' })
            If ($DisableAutologgers.count -gt 0)
            {
                Write-EventLog -EventId 50 -Message "Disable AutoLoggers" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
                Write-Verbose "Processing Autologger Configuration File"
                Foreach ($Item in $DisableAutologgers)
                {
                    Write-EventLog -EventId 50 -Message "Updating Registry Key for: $($Item.KeyName)" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Information
                    Write-Verbose "Updating Registry Key for: $($Item.KeyName)"
                    Try 
                    {
                        New-ItemProperty -Path ("{0}" -f $Item.KeyName) -Name "Start" -PropertyType "DWORD" -Value 0 -Force -ErrorAction Stop | Out-Null
                    }
                    Catch
                    {
                        $msg = ($_ | Format-List | Out-String)
                        Write-EventLog -EventId 150 -Message "Failed to add $($Item.KeyName)`n`n $msg" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Error
                    }
                    
                }
            }
            Else 
            {
                Write-EventLog -EventId 50 -Message "No Autologgers found to disable" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Warning
                Write-Verbose "No Autologgers found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 150 -Message "File not found: $AutoLoggersFilePath" -LogName 'Virtual Desktop Optimization' -Source 'AutoLoggers' -EntryType Error
            Write-Warning "File Not Found: $AutoLoggersFilePath"
        }
    }
    #endregion

    #region Disable Services
    If ($Optimizations -contains "Services" -or $Optimizations -contains "All")
    {
        $ServicesFilePath = "$outputPath\Services.json"
        If (Test-Path $ServicesFilePath)
        {
            Write-EventLog -EventId 60 -Message "Disable Services" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
            Write-Host "[VDI Optimize] Disable Services" -ForegroundColor Cyan
            $ServicesToDisable = (Get-Content $ServicesFilePath | ConvertFrom-Json ).Where( { $_.VDIState -eq 'Disabled' })

            If ($ServicesToDisable.count -gt 0)
            {
                Write-EventLog -EventId 60 -Message "Processing Services Configuration File" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                Write-Verbose "Processing Services Configuration File"
                Foreach ($Item in $ServicesToDisable)
                {
                    $service = Get-Service -Name $Item.name -ErrorAction SilentlyContinue
                    if ($null -ne $service){
                        if ($service.StartType -ne 'Disabled'){                        
                            Write-EventLog -EventId 60 -Message "Attempting to Stop Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                            Write-Verbose "Attempting to Stop Service $($Item.Name) - $($Item.Description)"
                            try
                            {
                                Stop-Service $Item.Name -Force
                            }
                            catch
                            {
                                $msg = ($_ | Format-List | Out-String)
                                Write-EventLog -EventId 160 -Message "Failed to disabled Service: $($Item.Name) `n $msg" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Error
                                Write-Warning "Failed to disabled Service: $($Item.Name) `n $msg"
                            }
                            Write-EventLog -EventId 60 -Message "Attempting to Disable Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                            Write-Verbose "Attempting to Disable Service $($Item.Name) - $($Item.Description)"
                            try {
                                Set-Service $Item.Name -StartupType Disabled 
                            } catch {
                                $msg = ($_ | Format-List | Out-String)
                                Write-EventLog -EventId 60 -Message "Unable to Disable Service $($Item.Name) - $($Item.Description) - $msg" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Error
                            }
                        } else {
                            Write-EventLog -EventId 60 -Message "Service was already disabled $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Information
                            Write-Verbose "Service was already disabled $($Item.Name) - $($Item.Description)"
                        }
                    } else {
                        Write-EventLog -EventId 60 -Message "Unable to find Service $($Item.Name) - $($Item.Description)" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Warning
                        Write-Warning "Unable to find Service $($Item.Name) - $($Item.Description)"

                    }
                }
            }  
            Else
            {
                Write-EventLog -EventId 60 -Message "No Services found to disable" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Warnnig
                Write-Verbose "No Services found to disable"
            }
        }
        Else
        {
            Write-EventLog -EventId 160 -Message "File not found: $ServicesFilePath" -LogName 'Virtual Desktop Optimization' -Source 'Services' -EntryType Error
            Write-Warning "File not found: $ServicesFilePath"
        }    }
    #endregion

    #region Network Optimization
    # LanManWorkstation optimizations
    If ($Optimizations -contains "NetworkOptimizations" -or $Optimizations -contains "All")
    {
        $NetworkOptimizationsFilePath = "$outputPath\LanManWorkstation.json"
        If (Test-Path $NetworkOptimizationsFilePath)
        {
            Write-EventLog -EventId 70 -Message "Configure LanManWorkstation Settings" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
            Write-Host "[VDI Optimize] Configure LanManWorkstation Settings" -ForegroundColor Cyan
            $LanManSettings = Get-Content $NetworkOptimizationsFilePath | ConvertFrom-Json
            If ($LanManSettings.Count -gt 0)
            {
                Write-EventLog -EventId 70 -Message "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                Write-Verbose "Processing LanManWorkstation Settings ($($LanManSettings.Count) Hives)"
                Foreach ($Hive in $LanManSettings)
                {
                    If (Test-Path -Path $Hive.HivePath)
                    {
                        Write-EventLog -EventId 70 -Message "Found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                        Write-Verbose "Found $($Hive.HivePath)"
                        $Keys = $Hive.Keys.Where{ $_.SetProperty -eq $true }
                        If ($Keys.Count -gt 0)
                        {
                            Write-EventLog -EventId 70 -Message "Create / Update LanManWorkstation Keys" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                            Write-Verbose "Create / Update LanManWorkstation Keys"
                            Foreach ($Key in $Keys)
                            {
                                If (Get-ItemProperty -Path $Hive.HivePath -Name $Key.Name -ErrorAction SilentlyContinue)
                                {
                                    Write-EventLog -EventId 70 -Message "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Verbose "Setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    try {
                                        Set-ItemProperty -Path $Hive.HivePath -Name $Key.Name -Value $Key.PropertyValue -Force
                                    } catch {
                                        $msg = ($_ | Format-List | Out-String)
                                        Write-EventLog -EventId 70 -Message "Error setting $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue) $msg" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Error
                                    }
                                }
                                Else
                                {
                                    Write-EventLog -EventId 70 -Message "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
                                    Write-Host "New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue)"
                                    try {
                                        New-ItemProperty -Path $Hive.HivePath -Name $Key.Name -PropertyType $Key.PropertyType -Value $Key.PropertyValue -Force | Out-Null
                                    } catch {
                                        $msg = ($_ | Format-List | Out-String)
                                        Write-EventLog -EventId 70 -Message "Error creating New $($Hive.HivePath) -Name $($Key.Name) -Value $($Key.PropertyValue) $msg" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Error
                                    }
                                }
                            }
                        }
                        Else
                        {
                            Write-EventLog -EventId 70 -Message "No LanManWorkstation Keys to create / update" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                            Write-Warning "No LanManWorkstation Keys to create / update"
                        }  
                    }
                    Else
                    {
                        Write-EventLog -EventId 70 -Message "Registry Path not found $($Hive.HivePath)" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                        Write-Warning "Registry Path not found $($Hive.HivePath)"
                    }
                }
            }
            Else
            {
                Write-EventLog -EventId 70 -Message "No LanManWorkstation Settings foun" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
                Write-Warning "No LanManWorkstation Settings found"
            }
        }
        Else
        {
            Write-EventLog -EventId 70 -Message "File not found - $NetworkOptimizationsFilePath" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Warning
            Write-Warning "File not found - $NetworkOptimizationsFilePath"
        }

        # NIC Advanced Properties performance settings for network biased environments
        Write-EventLog -EventId 70 -Message "Configuring Network Adapter Buffer Size" -LogName 'Virtual Desktop Optimization' -Source 'NetworkOptimizations' -EntryType Information
        Write-Host "[VDI Optimize] Configuring Network Adapter Buffer Size" -ForegroundColor Cyan
        Set-NetAdapterAdvancedProperty -DisplayName "Send Buffer Size" -DisplayValue 4MB
        <#  NOTE:
            Note that the above setting is for a Microsoft Hyper-V VM.  You can adjust these values in your environment...
            by querying in PowerShell using Get-NetAdapterAdvancedProperty, and then adjusting values using the...
            Set-NetAdapterAdvancedProperty command.
        #>
    }
    #endregion

    #region Disk Cleanup
    # Delete not in-use files in locations C:\Windows\Temp and %temp%
    # Also sweep and delete *.tmp, *.etl, *.evtx, *.log, *.dmp, thumbcache*.db (not in use==not needed)
    # 5/18/20: Removing Disk Cleanup and moving some of those tasks to the following manual cleanup
        If ($Optimizations -contains "DiskCleanup" -or $Optimizations -contains "All")
        {
            Write-EventLog -EventId 90 -Message "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing .tmp, .etl, .evtx, thumbcache*.db, *.log files not in use"
            Get-ChildItem -Path c:\ -Include *.tmp, *.dmp, *.etl, *.evtx, thumbcache*.db, *.log -File -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -ErrorAction SilentlyContinue

            # Delete "RetailDemo" content (if it exits)
            Write-EventLog -EventId 90 -Message "Removing Retail Demo content (if it exists)" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing Retail Demo content (if it exists)"
            Get-ChildItem -Path $env:ProgramData\Microsoft\Windows\RetailDemo\* -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -ErrorAction SilentlyContinue

            # Delete not in-use anything in the C:\Windows\Temp folder
            Write-EventLog -EventId 90 -Message "Removing all files not in use in $env:windir\TEMP" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing all files not in use in $env:windir\TEMP"
            Remove-Item -Path $env:windir\Temp\* -Recurse -Force -ErrorAction SilentlyContinue

            # Clear out Windows Error Reporting (WER) report archive folders
            Write-EventLog -EventId 90 -Message "Cleaning up WER report archive" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Cleaning up WER report archive"
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\Temp\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportArchive\* -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path $env:ProgramData\Microsoft\Windows\WER\ReportQueue\* -Recurse -Force -ErrorAction SilentlyContinue

            # Delete not in-use anything in your %temp% folder
            Write-EventLog -EventId 90 -Message "Removing files not in use in $env:temp directory" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Removing files not in use in $env:temp directory"
            Remove-Item -Path $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue

            # Clear out ALL visible Recycle Bins
            Write-EventLog -EventId 90 -Message "Clearing out ALL Recycle Bins" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Clearing out ALL Recycle Bins"
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue

            # Clear out BranchCache cache
            Write-EventLog -EventId 90 -Message "Clearing BranchCache cache" -LogName 'Virtual Desktop Optimization' -Source 'DiskCleanup' -EntryType Information
            Write-Host "Clearing BranchCache cache" 
            Clear-BCCache -Force -ErrorAction SilentlyContinue
        }    #endregion

    Set-Location $CurrentLocation
    $EndTime = Get-Date
    $ScriptRunTime = New-TimeSpan -Start $StartTime -End $EndTime
    Write-EventLog -LogName 'Virtual Desktop Optimization' -Source 'VDOT' -EntryType Information -EventId 1 -Message "VDOT Total Run Time: $($ScriptRunTime.Hours) Hours $($ScriptRunTime.Minutes) Minutes $($ScriptRunTime.Seconds) Seconds"
    Write-Host "`n`nThank you from the Virtual Desktop Optimization Team" -ForegroundColor Cyan

    If ($Restart) 
    {
        Restart-Computer -Force
    }
    Else
    {
        Write-Warning "A reboot is required for all changed to take effect"
    }
    ########################  END OF SCRIPT  ########################
}

Write-Host "Starting script to apply Azure baseline to Windows"

# Set TLS client version for GitHub downloads
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# Create GuestConfig folder
$gcFolder = New-Item -Path 'c:\ProgramData\' -Name 'GuestConfig' -ItemType 'Directory'

# Resolve latest details about PowerShell releases
$pwshLatestAssets = Invoke-RestMethod (Invoke-RestMethod https://api.github.com/repos/PowerShell/PowerShell/releases/latest).assets_url
$pwshDownloadUrl = ($pwshLatestAssets | Where-Object { $_.browser_download_url -like "*win-x64.zip" }).browser_download_url
$pwshZipFileName = $pwshDownloadUrl.split('/')[-1]

# Download latest stable release of PowerShell
Write-Host "Downloading PowerShell stand-alone binaries"
$pwshZipDownloadPath = Join-Path -Path $gcFolder -ChildPath $pwshZipFileName
$invokeWebParams = @{
    Uri     = $pwshDownloadUrl
    OutFile = $pwshZipDownloadPath
}
Invoke-WebRequest @invokeWebParams

# Extract zip file containing latest version of PowerShell
Write-Host "Extracting PowerShell package"
$ZipDestinationPath = Join-Path -Path $gcFolder -ChildPath $pwshZipFileName.replace('.zip', '')
Expand-Archive -Path $pwshZipDownloadPath -DestinationPath $ZipDestinationPath
$pwshExePath = Join-Path -Path (Join-Path -Path $gcFolder -ChildPath $pwshZipFileName.replace('.zip', '')) -ChildPath 'pwsh.exe'

# Save GuestConfiguration module
Write-Host "Saving GuestConfiguration module"
$modulesFolder = New-Item -Path 'c:\ProgramData\GuestConfig' -Name 'modules' -ItemType 'Directory'
Install-PackageProvider -Name "NuGet" -Scope CurrentUser -Force
Save-Module -Name GuestConfiguration -path $modulesFolder

# Workaround: until GC supports applying modules authored as audit type (with warning)
[scriptblock] $gcModuleDetails = {
    $env:PSModulePath += ';c:\ProgramData\GuestConfig\modules'
    Import-Module 'GuestConfiguration'
    Get-Module 'GuestConfiguration'
}
$gcModule = & $pwshExePath -Command $gcModuleDetails
$gcModulePath = Join-Path -Path $gcModule.ModuleBase -ChildPath $gcModule.RootModule
(Get-Content -Path $gcModulePath).replace('metaConfig.Type', 'true') | Set-Content -Path $gcModulePath

# Start guest config remediation
Write-Host "Applying Azure baseline"
[scriptblock] $remediation = {
    $env:PSModulePath += ';c:\ProgramData\GuestConfig\modules'
    Import-Module 'GuestConfiguration'
    <# Future
    $Parameter = @(
        @{
            ResourceType          = ''
            ResourceId            = 'User Account Control: Admin Approval Mode for the Built-in Administrator account'
            ResourcePropertyName  = 'ExpectedValue'
            ResourcePropertyValue = '0'
        },
        @{
            ResourceType          = ''
            ResourceId            = 'User Account Control: Admin Approval Mode for the Built-in Administrator account'
            ResourcePropertyName  = 'RemediateValue'
            ResourcePropertyValue = '0'
        }
    ) #>
    Start-GuestConfigurationPackageRemediation -Path 'https://oaasguestconfigwcuss1.blob.core.windows.net/builtinconfig/AzureWindowsBaseline/AzureWindowsBaseline_1.2.0.0.zip' # -Parameter $Parameter

    # Workaround: until GC module supports parameters for native code resources
    Start-GuestConfigurationPackageRemediation -Path 'https://oaasguestconfigeaps1.blob.core.windows.net/builtinconfig/FilterAdministratorToken/FilterAdministratorToken_1.10.0.0.zip'
}
& $pwshExePath -Command $remediation

# Workaround: allow admin WinRM connections from Packer but correct the setting on first boot
# Create Scheduled Task to add FilterAdministratorToken first system boot, xml here-string
$command = @'
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System -Name FilterAdministratorToken -Value 1 -Type DWord;
$schedServiceCom = New-Object -ComObject "Schedule.Service";
$schedServiceCom.Connect();
$rootTaskFolder = $schedServiceCom.GetFolder('\');
$rootTaskFolder.DeleteTask('FilterAdministratorTokenEnablement', 0)
'@
$encodedCommand = [convert]::ToBase64String([System.Text.encoding]::Unicode.GetBytes($command))
$taskDefinition = @'
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <URI>\FilterAdministratorTokenEnablement</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>false</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>C:\Windows\System32\cmd.exe</Command>
      <Arguments>/c PowerShell -ExecutionPolicy Bypass -OutputFormat Text -EncodedCommand #REPLACE</Arguments>
    </Exec>
  </Actions>
</Task>
'@ -replace '#REPLACE',$encodedCommand

$schedServiceCom = New-Object -ComObject "Schedule.Service"
$schedServiceCom.Connect()
$filterAdminTokenTask = $schedServiceCom.NewTask($null)
$filterAdminTokenTask.XmlText = $taskDefinition
$rootTaskFolder = $schedServiceCom.GetFolder('\')
[void] $rootTaskFolder.RegisterTaskDefinition('FilterAdministratorTokenEnablement', $filterAdminTokenTask, 6, 'SYSTEM', $null, 1, $null)

# Cleanup
Remove-Item -Path 'c:\ProgramData\GuestConfig' -Recurse -Force
Remove-Item -Path $env:LOCALAPPDATA\PackageManagement\ProviderAssemblies\NuGet -Recurse -Force