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

$ErrorActionPreference = 'Stop';

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


@(
    "googlechrome",
    "git.install",
    "vscode",
    "slack",
    "conemu",
    "github-desktop",
    "7zip"
) | ForEach-Object {
    Write-Progress -Activity "Installing $_"
    choco install $_ -y
}

Write-Progress -Activity "Installing VS Code extensions"
@(
    "ms-vscode.csharp",
    "ms-vscode.powershell",
    "jchannon.csharpextensions",
    "k--kato.docomment",
    "editorconfig.editorconfig"
) | ForEach-Object {
    Write-Progress -Activity "Installing $_"
    & code --install-extension $_
}

Write-Progress -Activity "Uninstalling unwanted apps"
@(
    "SkypeApp",
    "Solitaire",
    "Zune"
) | ForEach-Object {
    Write-Progress -Activity "Uninstalling $_"
    Get-AppxPackage *$_* | Remove-AppxPackage
}

Write-Progress -Activity "Setting git identity"

$userName = $GitUserName
if (!$userName) {
    $userName = (Get-WmiObject Win32_Process -Filter "Handle = $Pid").GetRelated("Win32_LogonSession").GetRelated("Win32_UserAccount").FullName
    $userName = if ($value = Read-Host -Prompt "Git user.name to be used ($userName)") { $value } else { $userName }
}
Write-Verbose "Setting git user.name to $userName"
git config --global user.name $userName

$userEmail = $GitUserEmail
if (!$userEmail) {
    # This seems to the be MSA that was first used during Windows setup
    $userEmail = (Get-WmiObject -Class Win32_ComputerSystem).PrimaryOwnerName
    $userEmail = if ($value = Read-Host -Prompt "Git user.email to be used ($userEmail)") { $value } else { $userEmail }
}
Write-Verbose "Setting git user.email to $userEmail"
git config --global user.email $userEmail

Write-Progress -Activity "Installing PoshGit"
Install-Module posh-git -Scope CurrentUser

Write-Progress -Activity "Hide search box from the taskbar"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search -Name SearchboxTaskbarMode -Value 0

Write-Progress -Activity "Set Windows Explorer to start on This PC instead of Quick Access"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1

Write-Progress -Activity "Don't hide extensions for known file types"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name HideFileExt -Value 0

Write-Progress -Activity "Enabling PowerShell on Win+X"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name DontUsePowerShellOnWinX -Value 0

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

Write-Progress -Activity "Reloading PS profile"
. $PROFILE
