#Region Functions
$Global:ControlPath = ""
$Global:TaskSequence = ""
$Global:OperatingSystems = ""
$Global:OperatingSystemsGroups = ""
$Global:MDTLocalPath = ""
$Global:CatalogFilePath

Function Select-OS {
    $OSChoices = $Global:OperatingSystems.oss.os | select name,Guid
    $OSArray = @()

    foreach($Os in $OSChoices)
    {
        $GUID = $Os.Guid
        if($Global:OperatingSystemsGroups.groups.group | Where-Object {$_.Name -eq 'Hidden' -and $_.Member -ccontains $GUID})
        {
       
        }
        else
        {
            $OSArray += $Os
        }

    }

    $OSChoice = $OSArray | Out-GridView -Title "Select OS" -OutputMode Single
    $OSGUID = $OSChoice.GUID
    $TSChoice = $Global:TaskSequence.tss.ts | select name,ID
    $SelectedTS = $TSChoice | Out-GridView -Title "Select OS" -OutputMode Single
    $IDPath = $SelectedTS.ID
    $TSPath = "$Global:ControlPath\$IDPath\ts.xml"
    $TSXML = [xml](Get-Content $TSPath)
    $TSXML.sequence.globalVarList.variable | Where {$_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $OSGUID}
    $TSXML.sequence.group | Where {$_.Name -eq "Install"} | ForEach-Object {$_.step} | Where {
    $_.Name -eq "Install Operating System"} | ForEach-Object {$_.defaultVarList.variable} | Where {
    $_.name -eq "OSGUID"} | ForEach-Object {$_."#text" = $OSGUID}
    $TSXML.Save($TSPath)
    pause
}

function Set-ChocoAppDependency ($ApplicationName) {

    Start-Sleep 5
    $AppPath = "$Global:ControlPath\Applications.xml"
    $AppXML = [xml](Get-Content $AppPath)
    $ChocoApp = $AppXML.applications.application | Where-Object {$_.ShortName -eq "Chocolatey"}
    if([string]::IsNullOrEmpty($ChocoApp) -eq $true)
    {
        $ChocoCommandLine = Get-Content "$PSScriptRoot\Choco\ChocoCommandLine.txt"

        Import-MDTApplication -path "DS001:\Applications" -enable "True" -Name Chocolatey -ShortName Chocolatey -Version "" -Publisher "" -Language "" -CommandLine $ChocoCommandLine -WorkingDirectory "" -NoSource -Verbose
    }

    else
    {
        
    }
    
    $AppPath = "$Global:ControlPath\Applications.xml"
    $ChocoAppGuid = $ChocoApp.guid
    $AppXML2 = [xml](Get-Content $AppPath -Force)
    $AppXML2.applications.application
    $SelectedApp = $AppXML2.applications.application | Where-Object {$_.ShortName -eq $ApplicationName}
    $Child = $AppXML2.CreateElement("Dependency")
    $Child.InnerText = $ChocoAppGuid
    $SelectedApp.AppendChild($Child)
    $AppXML2.Save($AppPath)

}

Function Create-ChocoApp {

    $ChocoAppSearch = Read-Host -Prompt 'Input The App that you want to seach for'

    if (Get-PackageProvider -Name chocolatey)
    {
    
    }
    else
    {
        Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }

    $FoundPackageList = Find-Package -Name $ChocoAppSearch -ProviderName Chocolatey | Out-GridView -Title "Application Found" -OutputMode Multiple
    foreach($ChocoApplication in $FoundPackageList)
    {
        $ChocoApp = $ChocoApplication.name
        $ApplicationPublisher = Read-Host -Prompt 'Input your Application Publisher'
        $ApplicationShortname = Read-Host -Prompt 'Input your Application Name'
        $ApplicationName = $ApplicationPublisher + " " + $ApplicationShortname
        $ApplicationCommandLine = "choco install $ChocoApp"

        Import-MDTApplication -path "DS001:\Applications" -enable "True" -Name $ApplicationName -ShortName $ApplicationShortname -Version "" -Publisher $ApplicationPublisher -Language "" -CommandLine $ApplicationCommandLine -WorkingDirectory "" -NoSource -Verbose
    
        Set-ChocoAppDependency -ApplicationName $ApplicationShortname
    }
    pause


}

Function Import-NewOS {

$msgBoxInput =  [System.Windows.MessageBox]::Show('Do you Have the ISO with Windows Sources ?','ISO Selection','YesNo','Information')

  switch  ($msgBoxInput) 
  {

    'Yes' {

        $ISO = Read-Host -Prompt 'Input ISO Path'

        $destionationFolder = Read-Host -Prompt 'Image Name'

        Mount-DiskImage -ImagePath $ISO

        $Drive = Get-WmiObject Win32_Volume | where-object {$_.Label -eq 'ESD-ISO'}
        $DriveLetter = $Drive.DriveLetter
        $DriveCaption = $drive.Caption
        $EsdImagePath = "$DriveLetter\sources\install.esd"

        $ESDImageIndexInfo = Get-WindowsImage -ImagePath $EsdImagePath | select ImageName, ImageIndex
        $ESDSelected = $ESDImageIndexInfo | Out-GridView -Title "Select Image Version" -OutputMode Single
        $index = $ESDSelected.ImageIndex

        Export-WindowsImage -SourceImagePath $EsdImagePath -DestinationImagePath "$env:Userprofile\Downloads\install.wim" -SourceIndex $index -CheckIntegrity -CompressionType MAX

        import-mdtoperatingsystem -path "DS001:\Operating Systems" -SourceFile "$env:Userprofile\Downloads\install.wim" -DestinationFolder $destionationFolder -SetupPath $DriveCaption -Verbose

        Dismount-DiskImage -ImagePath $ISO

    }

    'No' {

  
      $msgBoxInput =  [System.Windows.MessageBox]::Show("You will need to Download IT`n`nClicking Yes Will open a WebPage`n`nDownload the Microsoft Tool`n`nAnd Follow instructions to Create ISO",'ISO Selection','OKCancel','Information')

      switch  ($msgBoxInput) 
      
      {

          'OK'{

                Start "https://www.microsoft.com/en-ca/software-download/windows10"
          }

          'Cancel'{

          Break;

          }

      }

    }

  }
  pause



}

Function Import-Drivers {

    $DriverPath = Read-Host -Prompt 'Input The Drivers Path'
    $Path = Read-Host -Prompt 'Input name of the DeviceModel'
    Import-MDTDriver -SourcePath $DriverPath -Path $Path -ImportDuplicates $false -Verbose
    pause
}

Function Create-MDTMedia ($DeploymentShare, $MediaPath){
    if($DeploymentShare -ne $MediaPath)
    {
        New-Item -Path "$MediaPath\Content\Deploy" -ItemType directory
        New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root $DeploymentShare
        new-item -path "DS001:\Media" -enable "True" -Name "MEDIA001" -Comments "" -Root $MediaPath -SelectionProfile "Everything" -SupportX86 "False" -SupportX64 "True" -GenerateISO "True" -ISOName "LiteTouchMedia.iso" -Verbose
        new-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root "$MediaPath\Content\Deploy" -Description "Embedded media deployment share" -Force -Verbose
        Update-MDTMedia -path "DS001:\Media\MEDIA001" -Verbose
    }
    else
    {
        Write-Output "DeploymentShare Path and Media Path cannot be the same"
    }
    pause
}

function Create-MDTTaskSequence {
    
    $TSName = Read-Host -Prompt 'Enter An Name for Your Task Sequence'
    $TSID = Read-Host -Prompt 'Enter An ID for Your Task Sequence EI:TS01'
    $OSChoices = $Global:OperatingSystems.oss.os | select name,Guid
    $OSArray = @()
    foreach($Os in $OSChoices)
    {
        $GUID = $Os.Guid
        if($Global:OperatingSystemsGroups.groups.group | Where-Object {$_.Name -eq 'Hidden' -and $_.Member -ccontains $GUID})
        {
       
        }
        else
        {
            $OSArray += $Os
        }

    }
    Start-Sleep 5
    $OSChoice = $OSArray | Out-GridView -Title "Select OS" -OutputMode Single
    $OSName = $OSChoice.Name
    Import-mdttasksequence -path "DS001:\Task Sequences" -Name $TSName -Template "ClientNew.xml" -Comments "" -ID $TSID -Version "1.0" -OperatingSystemPath "DS001:\Operating Systems\$OSName" -FullName "Windows User" -OrgName "HOME" -HomePage "www.google.com" -Verbose
    
    if(Test-Path "$Global:MDTLocalPath\Scripts\BuiltInApps"){}
    else
    {
        Copy-item "$psscriptroot\BuiltInApps" "$Global:MDTLocalPath\Scripts" -Recurse
    }

    if(Test-Path "$Global:MDTLocalPath\Scripts\Choco"){}
    else
    {
        Copy-item "$psscriptroot\Choco" "$Global:MDTLocalPath\Scripts" -Recurse
    }

    if(Test-Path "$Global:MDTLocalPath\Scripts\Config"){}
    else
    {
        Copy-item "$psscriptroot\Config" "$Global:MDTLocalPath\Scripts" -Recurse
    }
    if(Test-Path "$Global:MDTLocalPath\Scripts\DeployWiz_LocalAccount.xml"){}
    else
    {
        Copy-item "$psscriptroot\Scripts\*.xml" "$Global:MDTLocalPath\Scripts" -Recurse -force
		Copy-item "$psscriptroot\Scripts\*.vbs" "$Global:MDTLocalPath\Scripts" -Recurse -force
		Copy-item "$psscriptroot\Scripts\*.enu" "$Global:MDTLocalPath\Scripts" -Recurse -force
    }
    pause
}

Function Invoke-Menu {
[cmdletbinding()]
Param(
[Parameter(Position=0,Mandatory=$True,HelpMessage="Enter your menu text")]
[ValidateNotNullOrEmpty()]
[string]$Menu,
[Parameter(Position=1)]
[ValidateNotNullOrEmpty()]
[string]$Title = "My Menu",
[Alias("cls")]
[switch]$ClearScreen
)
 
#clear the screen if requested
if ($ClearScreen) { 
 Clear-Host 
}
 
#build the menu prompt
$menuPrompt = $title
#add a return
$menuprompt+="`n"
#add an underline
$menuprompt+="-"*$title.Length
#add another return
$menuprompt+="`n"
#add the menu
$menuPrompt+=$menu
 
Read-Host -Prompt $menuprompt
 
} #end function

Function Edit-Unattend {
    $OSChoices = $Global:OperatingSystems.oss.os | Select name,guid,imagefile,source
    $OSArray = @()
    foreach($Os in $OSChoices)
    {
        $GUID = $Os.Guid
        if($Global:OperatingSystemsGroups.groups.group | Where-Object {$_.Name -eq 'Hidden' -and $_.Member -ccontains $GUID})
        {
       
        }
        else
        {
            $OSArray += $Os
        }

    }
    $OSChoice = $OSArray | Out-GridView -Title "Select OS" -OutputMode Single
    $OSFile = $OSChoice.ImageFile
    $OsSource = $OSChoice.Source
    $TSChoice = $Global:TaskSequence.tss.ts | select name,ID
    $SelectedTS = $TSChoice | Out-GridView -Title "Select OS" -OutputMode Single
    $IDPath = $SelectedTS.ID
    $OSImageFile = $OSFile.trimstart('.\')
    $OsSourceLocation = $OsSource.trimstart('.\')
    $OSSourcePath = "$Global:MDTDeploymentSharePath\$OsSourceLocation"
    $OsImagefilePath = "$Global:MDTDeploymentSharePath\$OSImageFile"
    $unattendPath = "$Global:MDTDeploymentSharePath\Control\$IDPath\Unattend.xml"
    if(Test-Path -Path "$OSSourcePath\*.clg")
    {
        $CatalogFile = Get-ChildItem -Path "$OSSourcePath\*.clg"
        $CatalogFileName = $CatalogFile.name
        $Global:CatalogFilePath =  "$OSSourcePath\$CatalogFileName"
    }
    else
    {
        Get-MDTOperatingSystemCatalog -ImageFile $OsImagefilePath -Index "1" -Verbose
    }
    
    Start-process -FilePath "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\WSIM\imgmgr.exe" -ArgumentList "$([char]34)$unattendPath$([char]34) -d $([char]34)$Global:MDTDeploymentSharePath$([char]34) -i $([char]34)$Global:CatalogFilePath$([char]34)" -Verb RUnAs
    pause
}
#EndRegion Functions

##############################################################################################################################################
################################                                                                              ################################
################################                                  Test MDT Prereq                             ################################
################################                                                                              ################################
##############################################################################################################################################
if (Test-Path "${env:ProgramFiles(x86)}\Windows Kits\10")
{
    
}
else
{

$msgBoxInput =  [System.Windows.MessageBox]::Show("To Use this tool you need to Install Windows ADK`nDo You Want it To be installed Automatically ?",'ADK Not Installed','YesNoCancel','Information')

  switch  ($msgBoxInput) {

  'Yes' {

    $url = "http://download.microsoft.com/download/6/8/9/689E62E5-C50F-407B-9C3C-B7F00F8C93C0/adk/adksetup.exe"
    $output = "$env:Userprofile\Downloads\adksetup.exe"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
    $start_time = Get-Date
    Write-Host "Will Install Windows ADK, This Will Take some Time, Please Be Patient"
    Start-Process -FilePath "$output" -ArgumentList "/features  OptionId.DeploymentTools OptionId.WindowsPreinstallationEnvironment OptionId.ImagingAndConfigurationDesigner OptionId.ICDConfigurationDesigner OptionId.UserStateMigrationTool /norestart /q /ceip off" -Wait
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

  }

  'No' {

  Exit

  }

  'Cancel' {

  Break;

  }

  }
    

}
if (Test-Path "$env:ProgramFiles\Microsoft Deployment Toolkit\Bin\DeploymentWorkbench.msc")
{
    
}
else
{

$msgBoxInput =  [System.Windows.MessageBox]::Show("To Use this tool you need to Install Microsoft Deployment Tool`nDo You Want it To be installed Automatically ?",'ADK Not Installed','YesNoCancel','Information')

  switch  ($msgBoxInput) {

  'Yes' {

    $url = "https://download.microsoft.com/download/3/3/9/339BE62D-B4B8-4956-B58D-73C4685FC492/MicrosoftDeploymentToolkit_x64.msi"
    $output = "$env:Userprofile\Downloads\MicrosoftDeploymentToolkit_x64.msi"
    $start_time = Get-Date
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

    $start_time = Get-Date
    
    Start-Process -FilePath "$env:windir\System32\msiexec.exe" -ArgumentList "/i $output /qb" -Wait
    Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

  }

  'No' {

  Exit

  }

  'Cancel' {

  Break;

  }

  }
  
}

if(Test-Path "$env:ProgramFiles\Microsoft Deployment Toolkit\Templates\ClientNew.xml")
{
}
Else
{
    Copy-Item "$PSScriptRoot\Template\ClientNew.xml" -Destination "$env:ProgramFiles\Microsoft Deployment Toolkit\Templates\ClientNew.xml"
}

##############################################################################################################################################
################################                                                                              ################################
################################                            Configure MDT                                     ################################
################################                                                                              ################################
##############################################################################################################################################

$Global:MDTDeploymentSharePath = Read-Host -Prompt 'Input your MDT Deployment Share UNC Path If Not Create Yet Just leave Empty'

if([string]::IsNullOrEmpty($Global:MDTDeploymentSharePath) -eq $true)
{
    
$msgBoxInput =  [System.Windows.MessageBox]::Show("Do you want the Deployment Share to be Created Automatically ?",'ADK Not Installed','YesNoCancel','Information')

  switch  ($msgBoxInput) {

  'Yes' {

    $Global:MDTLocalPath = "C:\DeploymentShare" 
    New-Item -Path $Global:MDTLocalPath -ItemType directory
    New-SmbShare -Name "DeploymentShare$" -Path $Global:MDTLocalPath -FullAccess Administrators
    Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
    New-PSDrive -Name "DS001" -PSProvider "MDTProvider" -Root $Global:MDTLocalPath -Description "MDT Deployment Share" -NetworkPath "\\$env:COMPUTERNAME\DeploymentShare$" -Verbose | add-MDTPersistentDrive -Verbose
    Copy-item "$psscriptroot\BuiltInApps" "$Global:MDTLocalPath\Scripts" -Recurse
    Copy-item "$psscriptroot\Choco" "$Global:MDTLocalPath\Scripts" -Recurse
    Copy-item "$psscriptroot\Config" "$Global:MDTLocalPath\Scripts" -Recurse
    Copy-item "$psscriptroot\Scripts\*.xml" "$Global:MDTLocalPath\Scripts" -Recurse -force
    $Global:MDTDeploymentSharePath = "\\$env:COMPUTERNAME\DeploymentShare$"
  }

  'No' {

  Exit

  }

  'Cancel' {

  Break;

  }

  }
}

if (Get-PSDrive -name "DS001" -ErrorAction SilentlyContinue)
{
}
else
{
    Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
    New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root $Global:MDTDeploymentSharePath
}

$Global:ControlPath = "$Global:MDTDeploymentSharePath\Control"

if (Test-Path "$Global:ControlPath\OperatingSystemGroups.xml")
{
    [XML]$Global:OperatingSystemsGroups = Get-Content -Path "$Global:ControlPath\OperatingSystemGroups.xml"
}

if (Test-Path "$Global:ControlPath\OperatingSystems.xml")
{
    [XML]$Global:OperatingSystems = Get-Content -Path "$Global:ControlPath\OperatingSystems.xml"
}

if (Test-Path "$Global:ControlPath\TaskSequences.xml")
{
    [XML]$Global:TaskSequence = Get-Content -Path "$Global:ControlPath\TaskSequences.xml"
}

$menu=@"
1 Change OS in TaskSequence
2 Create Application From Chocolatey
3 Import Computer Drivers
----------- Start From Nothing -----------
4 Import New OS Version from Windows Creation Tool 
5 Create New Task Sequence
---------------- Advanced ----------------
6 Create MDT Offline Media
7 Edit Unattend.XML
8 Edit CustomSettings.ini
9 Edit Bootstrap.ini
Q Quit
 
Select a task by number or Q to quit
"@

Do {
    #use a Switch construct to take action depending on what menu choice
    #is selected.
    Switch (Invoke-Menu -menu $menu -title "MDT Configuration Menu" -clear) {
     "1" {
            Write-Host "Select OS Version" -ForegroundColor Green
            if (Test-Path "$Global:ControlPath\OperatingSystems.xml")
            {
                Write-Host "You do not have Any OS in this Deployment Share Please Import One First" -ForegroundColor Red
            }
            else
            {
                Select-OS
            }
            sleep -seconds 2
         }
     "2" {
            Write-Host "Enter Application info" -ForegroundColor Green
            Create-ChocoApp
            sleep -seconds 2
          }
     "3" {
            Write-Host "Import Computer Drivers" -ForegroundColor Green
            Import-Drivers
            sleep -seconds 2
         }
     "4" {
            Write-Host "Import New OS Version" -ForegroundColor Green
            Import-NewOS
            sleep -seconds 2
         }
     "5" {
            Write-Host "Create New Task Sequence" -ForegroundColor Green
            Create-MDTTaskSequence
            sleep -seconds 2
         }
     "6" {
            Write-Host "Create MDT Offline Media" -ForegroundColor Green
            $MDTMediaPath = Read-Host -Prompt 'Input your MDT Media Path'
            Create-MDTMedia -DeploymentShare $Global:MDTDeploymentSharePath -MediaPath $MDTMediaPath
            sleep -seconds 2
         }
     "7" {
            Write-Host "Edit Unattend.XML file" -ForegroundColor Green
            Edit-Unattend
            sleep -seconds 2
         }
     "8" {
            Write-Host "Edit CustomSettings.ini File" -ForegroundColor Green
            Start-Process -FilePath "$env:windir\system32\notepad.exe" -ArgumentList "$Global:ControlPath\CustomSettings.ini"
            sleep -seconds 2
         }
     "9" {
            Write-Host "Edit Bootstrap.ini File" -ForegroundColor Green
            Start-Process -FilePath "$env:windir\system32\notepad.exe" -ArgumentList "$Global:ControlPath\Bootstrap.ini"
            sleep -seconds 2
         }
         
     "Q" {
            Write-Host "Quitting" -ForegroundColor Green
            Remove-PsDrive -name "DS001"
            Return
         }
     Default {Write-Warning "Invalid Choice. Try again."
              sleep -milliseconds 750}
    } #switch
} While ($True)

#end switch