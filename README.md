# MDT_ConfigurationMenu
MDT Easy Config Menu

![MDT-ConfigurationMenu.ps1](https://i.imgur.com/Wg5kvCH.png "MDT-ConfigurationMenu")

This Little Shell Program is made for users that would like to make there own Customized Windows image to reimage there own PC,
It could even help someone that would like to start to learn with MDT in a small business but that does not know where to start.
But it was made with the intend use this only for personnal Use.

The Script Contains Only one almost original File From MDT
Which is the "DeployWiz_Definition_ENU.xml"

Since this Menu is meant for personnal use, I added simple Menu Pane to Create a Local User, So Non Domain Computer.
It looks like this
![MDT-ConfigurationMenu.ps1](https://i.imgur.com/zP58hbt.png "MDT-ConfigurationMenu")
For now there is no way to Skip this Menu, and there is no validation in it.
I might do an update to fix this

# Pre-Req

So If you have absolutly nothing to do MDT on your Computers
The Script can take care of all Pre-Reqs
It will check if you have ADK 10 installed
For more information on ADK: https://docs.microsoft.com/en-us/windows-hardware/get-started/adk-install

Will Aslo check if you have MDT installed
For more information on MDT: https://docs.microsoft.com/en-us/sccm/mdt/

Then Menu The Menu will ask for a Deployment Share path,
If you continue and Enter Nothing, it will create the default one on your c: drive.
Then use option 4 and 5 to create your image.

# Menu Options 1

Will Switch the OS Selection, If ones are present in the Deployment Share.
For Exemple, From Windows 10 Home to Pro, or From Windows 10 1607 to 1703.
No OS is included in this Program, you will need to Download it yourself.

# Menu Options 2
This will add Applications option
Will Look Something Like this
![MDT-ConfigurationMenu.ps1](http://c-nergy.be/blog/wp-content/gallery/mdt_bundle/mdt_bundle13.png "MDT-ConfigurationMenu")

but these apps are not Local application
They are applications installed from https://chocolatey.org Repository
All Application will only have a command line and No Sources IE: "choco install chocolatey"

They will all have a Dependency Set to install Chocolatey Repository (There is nothing to do one your part)
![MDT-ConfigurationMenu.ps1](https://i.imgur.com/cxsjS9q.png "MDT-ConfigurationMenu")

# Menu Options 3
Simple is to Import Computer Drivers,
I suggest you download them from the manufacturer site.

# Menu Options 4
Will Direct you to 
https://www.microsoft.com/en-ca/software-download/windows10
So that you can create a Windows ISO
One you have the iso you can tell the program that you have an Source ISO and it will take care of 
everything to add it to the Deployment Share.

# Menu Options 5
Will Create a Task Sequence from my own Template
"ClientNew.xml" will be first copied in "C:\Program Files\Microsoft Deployment Toolkit\Templates" Folder
Then Will create the new Task Sequence
And Copy the 3 Folders
"BuiltInApps"
"Choco"
"Config"

The BuiltInApps Folder Contains a Script to Uninstall Windows 10 Default SideLoaded apps
Based on the CSV file "To-UninstallAPPX.csv"
I Use package family names
you can remove anything that you would like.
If you want to add stuff.

Run this Command in Powershell : Get-AppxPackage -AllUsers | select packagefamilyname
![MDT-ConfigurationMenu.ps1](https://i.imgur.com/lnSGmMP.png "MDT-ConfigurationMenu")

The Choco Folder Contains a Script to install Apps that you might want to force so not have in the selection Menu.
You will need to use the correct names: https://chocolatey.org/packages
In File "ChocoPackages.txt"

The Config Folder Contains a Script to Disable some settings on Windows,
in This Case it Disables;
- Cortana, Cloud Search and Location (So that Windows Search only search localy)
- Windows Consumer Features (I would Suggest you to not touch this one, as this is the settings that blocks windows 
from always reinstalling uninstalled apps, like Candy Crush)

# Menu Options 6
If you do not want to image from a remote share you can Create an offline Media,
But I did not test this setting extensively so I would suggest you to read a little on this first and maybe do it from the 
deployment workbench.

# Menu Options 7-9
This is really advanced stuff and you should really read on this before using anything.
