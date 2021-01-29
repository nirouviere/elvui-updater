Set-StrictMode -Version latest
$ErrorActionPreference = "Stop"

$ELVUI_DATA = @{
    DownloadPage    = "https://www.tukui.org/downloads"
    ZipPrefix       = "elvui-"
    TempDir         = "C:\Windows\Temp"
    VersionPage     = "https://www.tukui.org/download.php?ui=elvui"
    WoWAddonsDir    = "<PATH TO YOUR WOW ADDON FILE>"
    TocFilePath     = ""
    ArchiveName     = ""
    ArchivePath     = ""
    ExtractionDir   = ""
    FullDownloadUri = "" 
}


function GetLatestElvuiVersion {
    
    Write-Host -NoNewline Retrieving latest Elvui version from $ELVUI_DATA.VersionPage...
    $elvui_version_page = Invoke-WebRequest -Uri $ELVUI_DATA.VersionPage
    $version = $elvui_version_page.ParsedHtml.querySelector("div#version b.Premium")
    Write-Host -ForegroundColor Green OK
    return $version.innerText
}

function GetCurrentElvuiVersion {

    Write-Host  "Retreiving current Elvui version from file $ELVUI_DATA.TocFilePath...."
    $ElvuiCurrentVersion = "NOT_FOUND"
    try {
        $ElvuiCurrentVersion = (Select-String -Path $ELVUI_DATA.TocFilePath -Pattern "version") | `
            Out-String | ForEach-Object { $_.Split(":")[-1].Trim() }
    }
    catch [System.Management.Automation.ItemNotFoundException] {
        Write-Host "File $ELVUI_DATA.TocFilePath not found. Assuming no Elvui installation."
    }

    return $ElvuiCurrentVersion
}

function DownloadElvuiArchive {

    if ( (Test-Path -Path $ELVUI_DATA.ArchivePath) -eq $false ) {
        Write-Host Downloading Elvui archive at $ELVUI_DATA.FullDownloadURI to $ELVUI_DATA.ArchivePath
        Invoke-WebRequest -Uri $ELVUI_DATA.FullDownloadUri -OutFile $ELVUI_DATA.ArchivePath
    } else {
        Write-Host File already exists. Skipping
    }
}

function ExtractElvuiArchive {

    if ( (Test-Path -Path $ELVUI_DATA.ExtractionDir) -eq $true ) {
        Write-Host "Elvui archive already extracted. Skipping"
    } else {
        Write-Host Expanding Archive $ELVUI_DATA.ArchivePath to $ELVUI_DATA.ExtractionDir
        Expand-Archive -Path $ELVUI_DATA.ArchivePath -DestinationPath $ELVUI_DATA.ExtractionDir
    }
}

function BackupPreviousElvuiInstallation {
    [CmdletBinding()]
    param (
        [Parameter()][string] $ElvuiVersion
    )

    $ElvuiBackupFullPath = $ELVUI_DATA.TempDir,  ("backup-Elvui-" + $ElvuiVersion + ".zip") -join "\"
    Write-Host Backing up previous Elvui installation to $ElvuiBackupFullPath

    # Get All Elvui directories
    # Exclude SLE (Shadow And Light) directories
    $ElvuiDirectories =  Get-Item -Path ($ELVUI_DATA.WoWAddonsDir + "\elvui*") -Exclude *SLE*
    Write-Host "Backup $ElvuiDirectories"
    Compress-Archive `
        -Path $ElvuiDirectories `
        -Destination $ElvuiBackupFullPath `
        -Force

    return $ElvuiDirectories
}

function RemoveCurrentElvuiDirectories {
    [CmdletBinding()]
    param(
        [Parameter()][String[]] $ElvuiDirectories
    )

    foreach ($elvui_dir in $ElvuiDirectories) {
        Write-Host Removing Directory $elvui_dir
    }
}

function CopyElvuiFoldersToWow {
    $ElvuiFolderList = Get-ChildItem -Path $ELVUI_DATA.ExtractionDir

    $ElvuiFolderList | ForEach-Object {
        Write-Host Copying $_.Name to $ELVUI_DATA.WoWAddonsDir

        Copy-Item -Recurse -Path ($ELVUI_DATA.ExtractionDir, $_.Name -join "\") -Destination $ELVUI_DATA.WoWAddonsDir -Force
    }
}

function Cleanup {
    Write-Host Removing Elvui Archive: $ELVUI_DATA.ArchivePath
    Remove-Item -Path $ELVUI_DATA.ArchivePath

    Write-Host Removing Elvui directory $ELVUI_DATA.ExtractionDir
    Remove-Item -Path $ELVUI_DATA.ExtractionDir -Recurse
}

# Settings Elvui Toc file path
$ELVUI_DATA.TocFilePath = $ELVUI_DATA.WoWAddonsDir, "ElvUI\ElvUI.toc" -join "\"

$LatestElvuiVersion = GetLatestElvuiVersion
$CurrentElvuiVersion = GetCurrentElvuiVersion

Write-Host "Current version:    $CurrentElvuiVersion"
Write-Host "Latest version:     $LatestElvuiVersion"

if ($LatestElvuiVersion -eq $CurrentElvuiVersion) {
    Write-Host "Elvui is up to date"
} else {
    $ELVUI_DATA.ArchiveName = ($ELVUI_DATA.ZipPrefix, $LatestElvuiVersion, ".zip" -join "").Trim()
    $ELVUI_DATA.ArchivePath = $ELVUI_DATA.TempDir, $ELVUI_DATA.ArchiveName -join "\"
    $ELVUI_DATA.ExtractionDir = $ELVUI_DATA.TempDir, ($ELVUI_DATA.ZipPrefix, $LatestElvuiVersion -join "") -join "\"
    $ELVUI_DATA.FullDownloadUri = $ELVUI_DATA.DownloadPage, $ELVUI_DATA.ArchiveName -join "/"

    DownloadElvuiArchive
    ExtractElvuiArchive -ElvuiVersion $LatestElvuiVersion

    if ($CurrentElvuiVersion -ne "NOT_FOUND") {
        $ElvuiDirectories = BackupPreviousElvuiInstallation -ElvuiVersion $LatestElvuiVersion
        RemoveCurrentElvuiDirectories -ElvuiDirectories $ElvuiDirectories
    }

    CopyElvuiFoldersToWow
    Cleanup
}

Read-Host -Prompt "Press any key to close.... "
