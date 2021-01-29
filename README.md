# elvui-updater
PowerShell script to update Elvui automatically

# Description

This is a PowerShell script I created to automatically update Elvui. it will

  - Check if you have the latest version installed
  - Fetch the new version from tukui.org
  - Backup the previous Elvui version
  - Fully replace Elvui
  - Cleanup the backup files

:warning: **Disclaimer**: I built this script on my free time without full validation whatsoever. Use it at your own risk

# How To

Replace the `<PATH TO YOUR WOW ADDON FILE>` variable at the beginning of the script with your wow Addons path (e.g: `"D:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"`)


```Powershell
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
```

You can then run the script, (right click, or through the CLI).

You might need to bypass powershell's exectuion policy

