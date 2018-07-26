[CmdletBinding()]
param (
    # Defines the git username
    [Parameter(Mandatory=$false)]
    [string]
    $GitUserName,
    # Defines the git email
    [Parameter(Mandatory=$false)]
    [string]
    $GitUserEmail
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
    $MyPSProfileUrl = "https://raw.githubusercontent.com/fredimachado/New-Machine.ps1/fredi/Microsoft.PowerShell_profile.ps1"
    Invoke-WebRequest -Uri $MyPSProfileUrl -OutFile $PROFILE
}

Write-Progress -Activity "Download .gitconfig if it doesn't exist"
$GitConfigPath = "$env:HOME\.gitconfig"
if (-not (Test-Path $GitConfigPath)) {
    $MyGitConfigUrl = "https://raw.githubusercontent.com/fredimachado/dotfiles/master/.gitconfig"
    Invoke-WebRequest -Uri $MyGitConfigUrl -OutFile $GitConfigPath
}

Write-Progress -Activity "Ensuring Chocolatey is available"
$null = Get-PackageProvider -Name chocolatey

Write-Progress -Activity "Ensuring Chocolatey is trusted"
if (-not ((Get-PackageSource -Name chocolatey).IsTrusted)) {
    Set-PackageSource -Name chocolatey -Trusted
}

@(
    "google-chrome-x64",
    "git.install",
    "visualstudiocode",
    "fiddler4",
    "slack",
    "conemu",
    "github-desktop",
    "7zip"
) | ForEach-Object {
    Write-Progress -Activity "Installing $_"
    Install-Package -Name $_ -ProviderName chocolatey
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
Add-PoshGitToProfile

Write-Progress -Activity "Enabling PowerShell on Win+X"
Set-ItemProperty HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name DontUsePowerShellOnWinX -Value 0

Write-Progress "Closing explorer to start using last changes"
Get-Process explorer | Stop-Process
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
