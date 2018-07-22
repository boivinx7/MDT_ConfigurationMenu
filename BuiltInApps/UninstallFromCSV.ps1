$Appx = Get-Content -Path "$PSScriptRoot\To-UninstallAPPX.csv"

Foreach($item in $Appx)
{
    $Package = Get-AppxPackage -AllUsers | Where-Object {$_.PackageFamilyName -eq $item}
    if ($Package -ne $null)
    {
        
        Try
        {
            Remove-ProvisionedAppxPackage -Online -PackageName $Package -AllUsers -Verbose -ErrorAction SilentlyContinue
        }
        Catch
        {
            Write-Host "Unable to remove Package $Package From ProvisionedAppxPackage"
        }

        Try
        {
            Remove-AppxPackage -Package $Package -Verbose -ErrorAction SilentlyContinue
        }
        Catch
        {
            Write-Host "Unable to remove Package $Package From Current User"
        }

        Try
        {
            Remove-AppxPackage -Package $Package -AllUsers -Verbose -ErrorAction SilentlyContinue
        }
        Catch
        {
             Write-Host "Unable to remove Package $Package From All Users"
        }

        
    }

    
}