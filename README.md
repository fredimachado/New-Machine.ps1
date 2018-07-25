Modified version of Tatham Oddie's wonderful `New-Machine.ps1` script, available at: https://github.com/tathamoddie/New-Machine.ps1

    if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { throw "You need to run this from an elevated PS prompt" }; Set-ExecutionPolicy RemoteSigned -Force; iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/fredimachado/New-Machine.ps1/fredi/New-Machine.ps1'))

Yeah, I trust him!
