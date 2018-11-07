# Some steps on this script were based on https://github.com/mauro-dasilva/MachineSetup/blob/master/Windows/SetupPC.ps1
[CmdletBinding()]
param (
    # Defines the git username
    [Parameter(Mandatory=$false)]
    [string]
    $GitUserName,
    # Defines the git email
    [Parameter(Mandatory=$false)]
    [string]
    $GitUserEmail,
    # Feel like cleaning the desktop?
    [Parameter(Mandatory=$false)]
    [switch]
    $CleanDesktop
)

$ErrorActionPreference = 'SilentlyContinue';

$IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal([System.Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $IsAdmin) {
    throw "You need to run this script elevated"
}

Write-Progress -Activity "Setting execution policy"
Set-ExecutionPolicy RemoteSigned

Write-Progress -Activity "Download PowerShell profile if it doesn't exist"
if (-not (Test-Path $PROFILE)) {
    New-Item $PROFILE -Force
    $MyPSProfileUrl = "https://raw.githubusercontent.com/fredimachado/New-Machine.ps1/fredi/Microsoft.PowerShell_profile.ps1"
    Invoke-WebRequest -Uri $MyPSProfileUrl -OutFile $PROFILE -UseBasicParsing | Out-Null
}

Write-Progress -Activity "Download .gitconfig if it doesn't exist"
$GitConfigPath = "$env:HOMEDRIVE$env:HOMEPATH\.gitconfig"
if (-not (Test-Path $GitConfigPath)) {
    $MyGitConfigUrl = "https://raw.githubusercontent.com/fredimachado/dotfiles/master/.gitconfig"
    Invoke-WebRequest -Uri $MyGitConfigUrl -OutFile $GitConfigPath -UseBasicParsing | Out-Null
}

Write-Progress -Activity "Installing Chocolatey"
Invoke-Expression ((New-Object net.webclient).DownloadString('https://chocolatey.org/install.ps1')) | Out-Null
Import-Module $env:chocolateyinstall\helpers\chocolateyInstaller.psm1 | Out-Null

Write-Progress -Activity "Setting up Environment Variables"

[Environment]::SetEnvironmentVariable('ChocolateyToolsLocation', ${env:ProgramFiles(x86)}, "User")
Update-SessionEnvironment

@(
    "googlechrome",
    "git.install",
    "vscode",
    "slack",
    "conemu",
    "7zip.install",
    "sysinternals",
    "vlc",
    "sql-server-management-studio",
    "github-desktop"
) | ForEach-Object {
    Write-Progress -Activity "Installing $_"
    choco install $_ -y
}

Update-SessionEnvironment

Write-Progress -Activity "Installing VS Code extensions"
@(
    "ms-vscode.csharp",
    "ms-vscode.powershell",
    "jchannon.csharpextensions",
    "k--kato.docomment",
    "editorconfig.editorconfig",
    "msjsdiag.debugger-for-chrome"
) | ForEach-Object {
    Write-Progress -Activity "Installing $_"
    & code --install-extension $_
}

Write-Progress -Activity "Uninstalling unwanted apps"
@(
    "SkypeApp",
    "Solitaire",
    "Zune",
    "Microsoft.BingFinance",
    "Microsoft.BingNews",
    "Microsoft.BingSports",
    "Microsoft.BingWeather",
    "Microsoft.Getstarted",
    "Microsoft.MicrosoftOfficeHub",
    "Microsoft.OneConnect",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsCamera",
    "Microsoft.WindowsMaps",
    "Microsoft.WindowsPhone",
    "Microsoft.Messaging",
    "Microsoft.OneConnect",
    "Microsoft.Print3D",
    "Microsoft.GetHelp"
) | ForEach-Object {
    Write-Progress -Activity "Uninstalling $_"

    $PackageFullName = (Get-AppxPackage $_).PackageFullName
    $ProPackageFullName = (Get-AppxProvisionedPackage -online | Where-Object {$_.Displayname -eq $_}).PackageName

    if ($PackageFullName) {
        Remove-AppxPackage -Package $PackageFullName | Out-Null
    }

    if ($ProPackageFullName) {
        Remove-AppxProvisionedPackage -Online -PackageName $ProPackageFullName | Out-Null
    }
}

Write-Progress -Activity "Setting git identity"

$userName = $GitUserName
if (!$userName) {
    $userEmail = git config --global user.name
    $userName = if ($value = Read-Host -Prompt "Git user.name to be used ($userName)") { $value } else { $userName }
}
Write-Verbose "Setting git user.name to $userName"
git config --global user.name $userName

$userEmail = $GitUserEmail
if (!$userEmail) {
    $userEmail = git config --global user.email
    $userEmail = if ($value = Read-Host -Prompt "Git user.email to be used ($userEmail)") { $value } else { $userEmail }
}
Write-Verbose "Setting git user.email to $userEmail"
git config --global user.email $userEmail

Write-Progress -Activity "Installing PoshGit"
Install-Module posh-git -Scope CurrentUser

Write-Progress -Activity "Hide search box from the taskbar"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0 -ErrorAction SilentlyContinue

Write-Progress -Activity "Set Windows Explorer to start on This PC instead of Quick Access"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1 -ErrorAction SilentlyContinue

Write-Progress -Activity "Don't hide extensions for known file types"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0 -ErrorAction SilentlyContinue

Write-Progress -Activity "Remove suggested apps"
Set-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Cloud Content" -Name DisableWindowsConsumerFeatures -Value 1 -ErrorAction SilentlyContinue

Write-Progress -Activity "Do not track on Edge"
Set-ItemProperty HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main -Name DoNotTrack -Value 1 -ErrorAction SilentlyContinue

Write-Progress -Activity "Hide task view button"
Set-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name ShowTaskViewButton -Value 0 -ErrorAction SilentlyContinue

Write-Progress -Activity "Show details when copying files"
New-Item HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager -ErrorAction SilentlyContinue
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\OperationStatusManager -Name EnthusiastMode -Value 1 -ErrorAction SilentlyContinue

Write-Progress -Activity "Hide recent shortcuts"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Value 0 -ErrorAction SilentlyContinue
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Value 0 -ErrorAction SilentlyContinue

Write-Progress -Activity "Hide the My People icon in the taskbar"
Set-ItemProperty HKCU:\Software\Policies\Microsoft\Windows\Explorer -Name HidePeopleBar -Value 1 -ErrorAction SilentlyContinue

Write-Progress "Closing explorer to start using last changes"
Get-Process explorer | Stop-Process

if ($CleanDesktop) {
    Remove-Item "$env:PUBLIC\Desktop\*.lnk"
    Remove-Item "$env:USERPROFILE\Desktop\*.lnk"
}

Write-Progress "Making c:\code"
if (-not (Test-Path c:\code)) {
    New-Item c:\code -ItemType Directory
}

Write-Progress "Making c:\temp"
if (-not (Test-Path c:\temp)) {
    New-Item c:\temp -ItemType Directory
}

Write-Progress -Activity "Removing windows features"
@(
    "MediaPlayback",
    "FaxServicesClientPackage",
    "Printing-Foundation-InternetPrinting-Client"
) | ForEach-Object {
    Write-Progress -Activity "Removing feature: $_"
    Disable-WindowsOptionalFeature -Online -FeatureName $_ -NoRestart -ErrorAction SilentlyContinue | Out-Null
}

Write-Progress -Activity "Cleaning up temp folders"
$Tempfolders = @("C:\Windows\Temp\*", "C:\Windows\Prefetch\*", "C:\Users\*\Appdata\Local\Temp\*")
Remove-Item $Tempfolders -Force -Recurse -ErrorAction SilentlyContinue

Write-Progress -Activity "Reloading PS profile"
.$PROFILE
