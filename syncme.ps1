#list of downloads (name, url)
#hello
$credentials = @{ 'OneDrive' = @{'username' = ''; 'pass' = ''};
                    'GOG' = @{'username' = ''; 'pass' = ''}
                }

$downloads = @{
                "UIAutomation" = @{"url" = "http://uiautomation.codeplex.com/downloads/get/878892"; "file" = ""};
                "GOG_Galaxy" = @{"url" = "http://cdn.gog.com/open/galaxy/client/setup_galaxy_1.1.5.28.exe"; "file" = ""}
            }

#$work_path = $env:UserProfile+"\Downloads"

#Set-Location $work_path

function DownloadFile
{
    Param (
        [Parameter(Mandatory=$true)]
        [String]$url
    )

    $name = [System.IO.Path]::GetFileName($url)
    Invoke-WebRequest $url -OutFile $name
    Unblock-File $name  # file downloaded from internet is "blocked", you cant import locked dlls

    return $name
}

# unzip function http://stackoverflow.com/a/27768628
Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)
    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

function DownLoadAll
{
    ForEach($key in $($args[0].keys))
    {
        $args[0][$key]["file"] = DownloadFile $args[0][$key]["url"]
    }
}

function CreateFolder
{
    Param (
        [Parameter(Mandatory=$true)]
        [String]$fpath
    )

    if(!(Test-Path -Path $fpath )){
        New-Item -ItemType directory -Path $fpath
    }
}

DownLoadAll $downloads

Unzip $PSScriptRoot\$($downloads['UIAutomation']['file']) $PSScriptRoot\UIAutomation
ipmo $PSScriptRoot\UIAutomation\UIAutomation.dll

<############## OneDrive Saves ######################>
Start-Process $env:UserProfile\AppData\Local\Microsoft\OneDrive\OneDrive.exe  # -Wait
$OneDriveWin = Get-UiaWindow -Name 'Microsoft OneDrive'
$OneDriveWin | Get-UiaButton -Name 'Get started' | Invoke-UiaButtonClick

Start-Sleep -s 7
$OneDriveWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::TAB);
$OneDriveWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::TAB);
$OneDriveWin.Keyboard.TypeText($credentials['OneDrive']['username']);
$OneDriveWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::TAB);
$OneDriveWin.Keyboard.TypeText($credentials['OneDrive']['pass']);
$OneDriveWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::RETURN);

Start-Sleep -s 3
$OneDriveWin | Get-UiaButton -Name 'Next' | Invoke-UiaButtonClick
Start-Sleep -s 5
#$OneDriveWin | Get-UiaCheckBox -Name 'Sync all files and folders in my OneDrive' | Invoke-UIAToggleStateSet $false;
#$GameSaveItem = $OneDriveWin | Get-UiaTree -Name 'Sync only these folders' | Get-UiaTreeItem -Name GameSave*
#$GameSaveItem | Invoke-UiaControlClick -X -20
$OneDriveWin | Get-UiaButton -Name 'Next' | Invoke-UiaButtonClick
Start-Sleep -s 1
$OneDriveWin | Get-UiaButton -Name 'Done' | Invoke-UiaButtonClick

Stop-Process -Name iexplore

$saves_dir = $env:UserProfile + '\OneDrive\GameSave'
CreateFolder $saves_dir

<####################### GOG ############################>

Start-Process $downloads['GOG_Galaxy']['file'] /VERYSILENT -Wait
Start-Process 'C:\Program Files (x86)\GalaxyClient\GalaxyClient.exe'
Start-Sleep -s 10
$GOGWin = Get-UiaWindow -Name *GOG* | Get-UiaChildWindow
$GOGWin | Invoke-UiaControlClick -X 750 -Y 250
$GOGWin.Keyboard.TypeText($credentials['GOG']['username']);
$GOGWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::TAB);
$GOGWin.Keyboard.TypeText($credentials['GOG']['pass']);
$GOGWin.Keyboard.KeyPress([WindowsInput.Native.VirtualKeyCode]::RETURN);

<##################### Witcher 3 ######################>
#Start-Sleep -s 10
$witcher="The Witcher 3"
CreateFolder $saves_dir\$witcher
cmd /c mklink /J $env:UserProfile\Documents\$witcher $saves_dir\$witcher
