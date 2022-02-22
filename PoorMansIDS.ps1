Param(
    [bool]$saveReferenceFiles=$False # set to true to force creating new reference files
)
$PSDefaultParameterValues['out-file:width'] = 2000

if($saveReferenceFiles){ Write-Host "Called to Save Reference Files: ", $saveReferenceFiles }

# for options see: https://stackoverflow.com/questions/2085744/how-do-i-get-the-current-username-in-windows-powershell
$user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
#$user = $user.Substring( 1 + $user.IndexOf("\") )
Write-Host "Running as User: $user"

function runmain
{
    # set-Up Variables
    SETUP 
    # get Registry Key/Values and save to file
    RegKeys
    # get services:
    LocalServices
    # scheduled Tasks
    ScheduledTasks
}

function SETUP {
    #$MyWorkingDirectoryName = "PoorIDS"
    #$baseDirectory = $HOME + "\$MyWorkingDirectoryName\"
    $baseDirectory = $PSScriptRoot + "\"

    $Script:registry_output_file = $baseDirectory + "PoorIDS_Registry.txt"
    $Script:services_output_file = $baseDirectory + "PoorIDS_Services.txt"
    $Script:tasks_output_file    = $baseDirectory + "PoorIDS_Tasks.txt"

    $ALL_REFERENCE_FILES = @($registry_output_file, $services_output_file, $tasks_output_file )

    $Script:ReportOutputFile = $baseDirectory + "PoorIDS_Report.txt"
    $Script:reportCreated = $false

    #if((Test-Path -Path $baseDirectory -PathType Container) -eq $false){ 
    #    New-Item -path $HOME -ItemType Directory -Name $MyWorkingDirectoryName | Out-Null
    #    Write-Host "Creating Directory: $HOME\$MyWorkingDirectoryName "
    #} 
    
    # basedirectory exists: check for reference files
    
    foreach ( $var in $ALL_REFERENCE_FILES){
        if( (Test-Path -Path $var) -eq $false )
        {
                Write-Host "Missing Reference File:" $var
                $Script:saveReferenceFiles = $true # force creating of "ALL" reference files
        }
    }

Write-Host "BaseDirectory: $baseDirectory"
Write-Host "Registry Reference File: $registry_output_file"
Write-Host "Services Reference File: $services_output_file"
Write-Host "Tasks Reference File: $tasks_output_file"

}


function StripColor {
    [CmdletBinding()]
    Param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [string]$InputObject
    )
    Process {
        $InputObject = $InputObject -replace '\x1b\[[0-9;]*m',''
        $InputObject
    }
}

function GetAndWriteDiffString($InModuleName, $output_file, $current_output)
{
    $diff = Compare-Object -ReferenceObject (Get-Content $output_file) -DifferenceObject (Get-Content $current_output)
    if($diff){
        $diffstring = [string]$diff.InputObject
        $diffstring = $diffstring -replace '\s+', ' '
        $outstring = "************************`n$diffstring`n************************"
        Write-Host $outstring -ForegroundColor Red

        #(Get-Date -Format "yyyy_MM_dd_HH:mm:ss") + " $user found differences in " + $InModuleName  | Out-File -Append $Script:ReportOutputFile
        #"diff: " + $diff.InputObject | Out-File -Append $Script:ReportOutputFile

        $out = (Get-Date -Format "yyyy_MM_dd_HH:mm:ss") + " $user found differences in " + $InModuleName
        $out | Out-File -Append $Script:ReportOutputFile
        $outstring | Out-File -Append $Script:ReportOutputFile

        # true means exitcode=1 -> balloon in WPF App
        $Script:reportCreated = $true 
    }
}

function ScheduledTasks 
{
    $selfchangingTaskNames = @()
    $selfchangingTaskPaths = @()
    $selfchangingHashArray = @{ 
    #'\Microsoft\VisualStudio' = 'VSIX Auto Update'
    '\Microsoft\VisualStudio\Updates' = 'UpdateConfiguration'
      }

    $out = Get-ScheduledTask | select TaskName, TaskPath, Description, Triggers -ExpandProperty Actions -ExcludeProperty Description 
    #| format-table -AutoSize
    $outstring = ""
    $out | ForEach-Object {
            $taskpath = $_.TaskPath
            $taskname = $_.TaskName
            #$descr = $_.Description
            $triggers = $_.Triggers
            $exe = $_.Execute
            $args = $_.Arguments
            $skip = $false
            foreach ($key in $selfchangingHashArray.Keys)
            {
                if( $taskpath.Contains($key) )
                {
                    if( $taskname.Contains( $selfchangingHashArray[$key] ) )
                    {
                        $skip = $true
                    }
                }
            }
            if($skip -eq $false){
                $outstring += "$taskname, $taskpath, $exe, $args`n"
            }
        }
    $out = $outstring
    #$out = $out | Out-String -Width 2000 | StripColor

    if($saveReferenceFiles){ # create reference
        $out | Out-File $tasks_output_file
    } else {
        Write-Host "Comparing current with reference scheduled tasks"
        $current_output = $tasks_output_file + "_current.txt"
        $out | Out-File $current_output
        GetAndWriteDiffString -InModuleName "ScheduledTask" -output_file $tasks_output_file -current_output $current_output
    }

}

function LocalServices 
{
    # tasks per user with _[a-z0-9]+ string attached
    # https://docs.microsoft.com/en-us/windows/application-management/per-user-services-in-windows
    $underscoreServices = @(
    "AarSvc"
    "BcastDVRUserService"
    "BluetoothUserService"
    "CaptureService"
    "cbdhsvc"
    "CDPUserSvc"
    "ConsentUxUserSvc"
    "CredentialEnrollmentManagerUserSvc"
    "DeviceAssociationBrokerSvc"
    "DevicePickerUserSvc"
    "DevicesFlowUserSvc"
    "MessagingService"
    "OneSyncSvc"
    "PimIndexMaintenanceSvc"
    "PrintWorkflowUserSvc"
    "UdkUserSvc"
    "UnistoreSvc"
    "UserDataSvc"
    "WpnUserService"
)

$services = Get-CimInstance win32_service | Sort-Object -Property Name
$outServices = ""
$services | ForEach-Object {
        $name = $_.Name
        $displayName = $_.DisplayName 
        foreach($underscoreName in $underscoreServices)
        {
            if($name.Contains($underscoreName))
            {
                [string]$first, [string]$second =  $name.split("_")
                $name = $first
                [string]$first2, [string]$second2 = $displayName.split("_")
                $displayName = $first2
            }
        }
        $descr = $_.Description
        $startName = $_.StartName
        $pathName = $_.PathName
        $serviceType = $_.ServiceType
        #$outServices += "$name, $displayName, $pathName, $descr , Account:$startName, $serviceType `n"
        $outServices += "$name, $displayName, $pathName, Account:$startName, $serviceType `n"
 }

    $out = $outServices


    $out = $out | Out-String -Width 27000 | StripColor
    
    
    if($saveReferenceFiles) # create reference
    {
        $out | Out-File "${services_output_file}"
        $tmp = Get-Content ${services_output_file}
        $tmp | Sort-Object -Unique | Out-File $services_output_file 

    }
    else # compare with reference 
    {
        Write-Host "Comparing current with reference local services"
        $current_output = $services_output_file + "_current.txt"

        $out | Out-File "${current_output}"
        $tmp = Get-Content ${current_output}
        $tmp | Sort-Object -Unique | Out-File $current_output

        GetAndWriteDiffString -InModuleName "LocalServices" -output_file $services_output_file -current_output $current_output
    }
}


function RegKeys
{
    $RegKeysArray = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Run\"
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce\"
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run\"
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce\"
        "HKLM:\SOFTWARE\WOW6432NODE\Microsoft\Windows\CurrentVersion\Run"
        "HKLM:\SOFTWARE\WOW6432NODE\Microsoft\Windows\CurrentVersion\RunOnce" 
        )
    $out = ""

    foreach($i in $RegKeysArray)
    {
        $OFS = "`n"
        $out += "Keys in ${i}:" + $OFS
        $out += GetRegistryKeyValues -regkey $i
        $out += $OFS
    }

    if($saveReferenceFiles -eq $true)
    {
        $out | Out-File -NoNewline $registry_output_file
        #$out
    } else 
    {
        Write-Host "Comparing Current with reference Registry Keys"
        $current_output = $Script:registry_output_file + "_current.txt"
        $out | Out-File -NoNewline $current_output
        GetAndWriteDiffString -InModuleName "RegistryKeys" -output_file $registry_output_file -current_output $current_output
    }
}

function GetRegistryKeyValues ( [string]$regkey )
{
    $valueNames =   (Get-Item $regkey).GetValueNames()
    
    foreach ($i in $valueNames)
    {
        $value = (Get-Item $regkey).GetValue($i)
        $outString += $regkey + " Key: " + $i + " Value: " + $value + "`n"
    }
    if( $outString -and $outString.Length -ge 1){
        $outString = $outString.Substring(0, $outString.Length - 1) # remove last \n
    }
    return $outString
}


runmain

Write-Host "report of CHANGES generated:" $Script:reportCreated

if($reportCreated) # i.e. changes found
{
    Exit 1
}
