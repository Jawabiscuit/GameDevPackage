Disable-UAC

# Allow unattended reboots
$Boxstarter.RebootOk = $true
$Boxstarter.NoPassword = $false
$Boxstarter.AutoLogin = $true

# No confirmation i.e. --yes
choco feature enable --name=allowGlobalConfirmation

# Allow execution of powershell scripts
Update-ExecutionPolicy Unrestricted

# Disable Microsoft and Windows update
Disable-MicrosoftUpdate


## System Configuration

$computername = "vrexton2"

# Regional Settings
& "$env:windir\system32\tzutil.exe" /s "Eastern Standard Time"
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortDate -Value 'dd MM yy'
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sShortTime -Value 'HH:mm tt'
Set-ItemProperty -Path "HKCU:\Control Panel\International" -Name sTimeFormat -Value 'HH:mm:ss tt'

# Enable developer mode on the system
Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1

# Turn off screensaver
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name ScreenSaveActive -Value 0

# Disable UAC popups
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name EnableLUA -Value 0 -Force

# Requires restart, or add the -Restart flag
if ($env:computername -ne $computername) {
	Rename-Computer -NewName $computername
}
    
# Set DNS upstreams
# Set-DNSClientServerAddress -InterfaceIndex $(Get-NetAdapter | Where-object {$_.Name -like "*Wi-Fi*" } | Select-Object -ExpandProperty InterfaceIndex) -ServerAddresses "8.8.8.8", "1.1.1.1", "2001:4860:4860::8888", "2001:4860:4860::8844"

Set-StartScreenOptions -EnableBootToDesktop

if (Test-PendingReboot) { Invoke-Reboot }


<#
Win10 Initial Startup Script

.Description
  Download git archive and preset file and run script to setup a new Windows 10 install.
  See https://github.com/Disassembler0/Win10-Initial-Setup-Script
.Example
  1) Open powershell as administrator
  2) `Set-ExecutionPolicy AllSigned -Force` to allow execution of scripts
  3) Find the raw URL to this gist
  4) Create your own preset and edit the `$presetUrl`
  4) `iex ((new-object net.webclient).DownloadString("https://gist.githubusercontent.com/<USER>/.../win10-iss.ps1")` to execute
#>

# Download the archive for the latest updates
$url = "https://github.com/Jawabiscuit/Win10-Initial-Setup-Script/archive/master.zip"
# $presetUrl = "https://gist.githubusercontent.com/Jawabiscuit/31bce47c991528541b6a4fdedff7b15a/raw/76f712cff3e47cdb4f5fb503dd92ab88ae23009d/win10-iss.preset"
$presetFile = "win10-iss.preset"
$archiveName = "master.zip"
$installDir = "C:\tools\win10-initial-setup-script"
$archive = Join-Path $installDir $archiveName
$win10IssDir = Join-Path $installDir "Win10-Initial-Setup-Script-master"

if (-not (Test-Path $installDir)) {
    New-Item $installDir -ItemType Directory
}

if (!(Test-Path $archive)) {
    Write-Host "[installer.win10-initial-setup-script] Downloading..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "$url" -OutFile "$archive"
}

if (Test-Path "$archive") {
    $zipfile = Get-Item "$archive"
    Write-Host "[installer.win10-initial-setup-script] Downloaded successfully"
    Write-Host "[installer.win10-initial-setup-script] Extracting $archive to ${installDir}..."
    if (Test-Path $win10IssDir) {
        Remove-Item -Recurse -Force -Path $win10IssDir
    }
    Expand-Archive $archive -DestinationPath $zipfile.DirectoryName
} else {
    Write-Error "[installer.win10-initial-setup-script] Download failed"
}

<#
if (Test-Path $win10IssDir) {
    $outFile = Join-Path $win10IssDir $presetFile
    wget $presetUrl -outfile $outFile
}
#>

# Set policy before executing scripts
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

if (Test-Path (Join-Path $win10IssDir $presetFile)) {
    $restoreDir = pwd
    cd $win10IssDir
    $script = '.\Win10.ps1'
    $params = '-include Win10.psm1 -include Win10-Plus.psm1 -preset ' + $presetFile + ' !DisableOneDrive !UninstallOneDrive !Restart !WaitForKey'
    iex "$script $params"
    cd $restoreDir
}


<#
Debloat Windows 10
.Description
  Download git archive and run scripts to debloat a new Windows 10 install.
.Example
  1) Open powershell as administrator
  2) `Set-ExecutionPolicy AllSigned -Force` to allow execution of scripts
  3) Find the raw URL to this gist
  4) `iex ((new-object net.webclient).DownloadString("https://gist.githubusercontent.com/<USER>/.../debloat-windows-10.ps1")` to execute
#>

# Download the archive for the latest updates
$url = "https://github.com/Jawabiscuit/Debloat-Windows-10/archive/master.zip"
$archiveName = "master.zip"
$installDir = "C:\tools\debloat-windows-10"
$archive = Join-Path $installDir $archiveName
$debloatDir = Join-Path $installDir "Debloat-Windows-10-master"

if (!(Test-Path $installDir)) {
    New-Item $installDir -ItemType Directory
}

if (!(Test-Path $archive)) {
    Write-Host "[installer.debloat-windows-10] Downloading..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "$url" -OutFile "$archive"
}

if (Test-Path "$archive") {
    $zipfile = Get-Item "$archive"
    Write-Host "[installer.debloat-windows-10] Downloaded successfully"
    Write-Host "[installer.debloat-windows-10] Extracting $archive to ${installDir}..."
    if (Test-Path $debloatDir) {
        Remove-Item -Recurse -Force -Path $debloatDir -ErrorAction SilentlyContinue
    }
    Expand-Archive $archive -DestinationPath $zipfile.DirectoryName -Force
} else {
    Write-Error "[installer.debloat-windows-10] Download failed"
}

# Set policy before importing modules or executing scripts
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

# Hard code module names for now
$mod_fnames = @(
    "New-FolderForced.psm1",
    "take-own.psm1"
)
$modules = @()
$moduleDir = Join-Path $debloatDir "lib"
foreach ($m in $mod_fnames) {
    $modules += (Join-Path $moduleDir $m)
}

foreach ($mod in $modules) {
    if (Test-Path $mod) {
        Import-Module $mod
    } else {
        Write-Error "[installer.debloat-windows-10] Error missing module: $mod"
    }
}

# Get scripts to run
$filenames = @(
    "remove-default-apps.ps1"
    # "remove-onedrive.ps1"
)

$scripts = @()
$scriptsDir = Join-Path $debloatDir "scripts"
foreach ($f in $filenames) {
    $scripts += (Join-Path $scriptsDir $f)
}

# Execute the scripts
foreach ($s in $scripts) {
    if (Test-Path $s) {
        iex ((Get-Content $s) -join [environment]::newline)
    }
}


## File Explorer
# Currenly rely on Win10-Initial-Setup-Script for these settings
# Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions -EnableShowFullPathInTitleBar -DisableOpenFileExplorerToQuickAccess -DisableShowRecentFilesInQuickAccess -DisableShowFrequentFoldersInQuickAccess -EnableExpandToOpenFolder -EnableShowRibbon

Set-BoxstarterTaskbarOptions -Size Small -Dock Bottom -Combine Always -MultiMonitorOn -MultiMonitorMode All -MultiMonitorCombine Always

# Sets window corner navigation options for Windows 8/8.5
# Set-CornerNavigationOptions -EnableUpperRightCornerShowCharms -EnableUpperLeftCornerSwitchApps -EnableUsePowerShellOnWinX

# Taskbar where window is open for multi-monitor
# Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarMode -Value 2


## Common Dev Tools
# Tools devs normally want
# NOTE: vscode is a separate script

choco install sysinternals
choco install dotnetcore-sdk
choco install javaruntime
choco install jdk8
choco install git.install -params "'/GitAndUnixToolsOnPath /WindowsTerminal /NoAutoCrlf'"
choco install python
choco install anaconda2
choco install cygwin
choco install 7zip.install

# File Xfer
choco install winscp
choco install putty
choco install filezilla

choco install chocolatey
choco install choco-cleaner --version 0.0.7.3
choco install boxstarter

RefreshEnv


## Custom Dev Tools
# Tools that vary from by machine and developer

# Editor
choco install emacs --version 24.5.0.20191123

choco install pandoc
choco install miktex
choco install vcxsrv

choco-cleaner

# Database
# Temporarily enable/disable features to bypass checksums
# choco feature disable -n=checksumFiles
# choco feature enable -n=allowEmptyChecksums
# 
# try {
#     # TODO: This is taking too long, something not right...
#     choco install pgadmin4
#     choco install postgresql10
# }
# finally {
#     choco feature enable -n=checksumFiles
#     choco feature disable -n=allowEmptyChecksums
# }

# Terminal
# TODO: This is hanging after install!
# choco install microsoft-windows-terminal    

# Package Mgmt
# choco install --limitoutput nugetpackageexplorer

# TODO: Radeon or NVidia graphics? #
# choco install evga-precision-xoc

# System Nfo & Tuner
choco install cue
choco install cpu-z
choco install gpu-z
choco install hwinfo
# TODO: Test on Win Pro
# choco install intel-rst-driver
# choco install intel-xtu
choco install gpg4win
choco install treesizefree


## Git Config
# Set HOME to user profile for git
[Environment]::SetEnvironmentVariable("HOME", $env:UserProfile, "User")


## VSCode
choco install vscode
RefreshEnv

# Need to launch vscode so user folders are created as we can install extensions
$process = Start-Process code -PassThru
Start-Sleep -s 10
$process.Close()

# code --install-extension ms-vscode.csharp
code --install-extension ms-vscode.PowerShell
code --install-extension DavidAnson.vscode-markdownlint
code --install-extension johnpapa.Angular2
code --install-extension donjayamanne.githistory
code --install-extension hnw.vscode-auto-open-markdown-preview
code --install-extension EditorConfig.editorconfig
# code --install-extension djabraham.vscode-yaml-validation
# code --install-extension robertohuertasm.vscode-icons
# code --install-extension PeterJausovec.vscode-docker
# code --install-extension ms-vscode-remote.remote-extensionpack

# pin apps that update themselves
choco pin add -n=vscode

choco-cleaner


## Visual Studio 2017 - GameDev
choco install visualstudio2017community

choco pin add -n=visualstudio2017community

# Workloads for game development in engines like UE4
choco install visualstudio2017-workload-manageddesktop --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-nativedesktop --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-universal --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-universalbuildtools --cacheLocation "C:\vs_cache"
# choco install visualstudio2017-workload-datascience --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-nativegame --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-managedgame --cacheLocation "C:\vs_cache"
choco install visualstudio2017-workload-nativecrossplat --cacheLocation "C:\vs_cache"

Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${env:ProgramFiles(x86)}\Microsoft Visual Studio\2017\Community\Common7\IDE\devenv.exe"

choco-cleaner


## Common Applications
# Internet
choco install firefox
choco install googlechrome.dev

# Utils
choco install f.lux
choco install adobereader
choco install etcher

# Social
choco install zoom

# Media
# TODO: Remote error
# choco install spotify
choco install vlc
choco install k-litecodecpack-standard

# VNC
choco install nomachine
choco install realvnc

# Image Editor
choco install inkscape
choco install gimp

# Document Creation
choco install libreoffice-fresh

# Security
# TODO: Spybot S&D and Anti-Beacon

# Pin apps that update themselves
choco pin add -n=firefox

# Pin items to the taskbar
Install-ChocolateyPinnedTaskBarItem -TargetFilePath "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"


## Common Game Apps
# TODO: Don't install in a VM environment
# choco install geforce-experience
# choco install geforce-game-ready-driver

choco install itch
choco install slack
choco install discord
choco install twitch

# Screenshot/Streaming
choco install sharex
choco install obs-studio

# Game launcher
choco install epicgameslauncher
choco install steam


## Setup PoB-Community
$url = 'https://github.com/PathOfBuildingCommunity/PathOfBuilding/archive/master.zip'
$archiveName = 'pob-community-1.4.170.20.zip'
$installDir = "C:\tools\Path of Building Community"
$pobDir = Join-Path $installDir "PathOfBuilding-master"
$archive = Join-Path $installDir $archiveName

if (-not (Test-Path installDir)) {
    New-Item $installDir -ItemType Directory
}

if(!(Test-Path $archive)) {
    Write-Host "[installer.pob-community] Downloading..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri "$url" -OutFile "$archive"
}

if(Test-Path "$archive") {
    $zipfile = Get-Item "$archive"
    Write-Host "[installer.pob-community] Downloaded successfully"
    Write-Host "[installer.pob-community] Extracting $archive to ${installDir}..."
    if (Test-Path $pobDir) {
        Remove-Item -Recurse -Force -Path $pobDir -ErrorAction SilentlyContinue
    }
    Expand-Archive $archive -DestinationPath $zipfile.DirectoryName
} else {
    Write-Error "[installer.pob-community] Download failed"
}

# Pin items to the taskbar
Install-ChocolateyPinnedTaskBarItem -TargetFilePath "$pobDir\Path of Building.exe"

choco-cleaner


## Hyper-V
# TODO: Requires Windows Pro
# choco install boxstarter.hyperv
# Next line is probably no longer necessary
# Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All


## Windows Subsystem for Linux
# TODO: Test on a Windows Pro machine
# choco install wsl-ubuntu-1804
#
# --- Ubuntu ---
# TODO: Move this to choco install once --root is included in that package
# Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~/Ubuntu.appx -UseBasicParsing
# Add-AppxPackage -Path ~/Ubuntu.appx
# run the distro once and have it install locally with root user, unset password
#
# RefreshEnv
# Ubuntu1804 install --root
# Ubuntu1804 run apt update
# Ubuntu1804 run apt upgrade -y
#
# write-host "Installing tools inside the WSL distro..."
# Ubuntu1804 run apt install python2.7 python-pip -y 
# # Ubuntu1804 run apt install python-numpy python-scipy -y
# # Ubuntu1804 run pip install pandas
#
# write-host "Finished installing tools inside the WSL distro"
#
# Enable-WindowsOptionalFeature -Online -FeatureName containers -All
# RefreshEnv
#
# choco install docker-for-windows
# choco install vscode-docker
#
# pin apps that update themselves
# choco pin add -n=docker-for-windows


## WSL2
# Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
# dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
# wsl --set-version 2


## Powershell Utilities
## Interferes with choco-cleaner as file handles do not get cleaned up
## So run it at the end
#
# Install without prompt
Set-PSRepository -Name PSGallery -InstallationPolicy Trusted

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Tools
Install-Module -Name Carbon -AllowClobber -Force
Install-Module -Name PowerShellHumanizer -Force

Set-PSRepository -Name PSGallery -InstallationPolicy Untrusted


## Cleanup
# Revert No confirmation feature
choco feature disable --name=allowGlobalConfirmation

if(Test-PendingReboot) { Invoke-Reboot }

# Enable Windows update
Write-BoxstarterMessage "Running Windows Update..."
Install-WindowsUpdate -AcceptEula

# Enable Microsoft Update
Enable-MicrosoftUpdate

# Remove temp directories
if (Test-Path "C:\vs_cache") {
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "C:\vs_cache"
}

Enable-UAC
