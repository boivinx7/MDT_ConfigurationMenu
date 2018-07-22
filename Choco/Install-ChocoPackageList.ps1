Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

if(Get-PackageProvider -Name chocolatey)
{
    
}
else
{
   Install-PackageProvider -Name chocolatey -Force
}

$ChocoPackagestxt = Get-Content -Path "$Psscriptroot\ChocoPackages.txt"

foreach($Pack in $ChocoPackagestxt)
{
    Install-Package -Name $Pack -Force -ProviderName chocolatey -ErrorAction SilentlyContinue
}