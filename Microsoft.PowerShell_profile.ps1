Import-Module posh-git

# PoshGit settings
$Global:GitPromptSettings.DefaultPromptSuffix = '`n$(''>'' * ($nestedPromptLevel + 1)) '
$Global:GitPromptSettings.DefaultPromptAbbreviateHomeDirectory = $true

function Edit {
  & code --disable-gpu -g @args
}

function Reboot {
  & shutdown /r /t 0
}

function Get-WindowsBuild {
  [Environment]::OSVersion
}

function Touch($file) {
  New-Item $file -type file
}
