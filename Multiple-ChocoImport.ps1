$Packages = Get-Package -ProviderName Chocolatey
Import-Module "C:\Program Files\Microsoft Deployment Toolkit\bin\MicrosoftDeploymentToolkit.psd1"
    New-PSDrive -Name "DS001" -PSProvider MDTProvider -Root "\\billsnas\Softwares\DeploymentShare"
foreach ($Package in $Packages)
{
    $PackName = $Package.Name
    $PackVersion = $Package.Version
    $Provider = $Package.ProviderName

    $FoundPackageList = Find-Package -Name $PackName -RequiredVersion $PackVersion -ProviderName $Provider
    foreach($ChocoApplication in $FoundPackageList)
    {
        $ChocoApp = $ChocoApplication.name
        $ApplicationPublisher = $Provider
        $ApplicationShortname = $ChocoApplication.name
        $ApplicationName = $ApplicationPublisher + " " + $ApplicationShortname
        $ApplicationCommandLine = "choco install $ChocoApp"

        Import-MDTApplication -path "DS001:\Applications" -enable "True" -Name $ApplicationName -ShortName $ApplicationShortname -Version "" -Publisher $ApplicationPublisher -Language "" -CommandLine $ApplicationCommandLine -WorkingDirectory "" -NoSource -Verbose
 
    }
}