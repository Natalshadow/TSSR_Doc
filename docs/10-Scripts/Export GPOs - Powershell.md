``` powershell
# Créer un dossier 
New-Item -Path "C:\GPO_Reports" -ItemType Directory -ErrorAction SilentlyContinue

# Exporter toutes les GPO en HTML
Get-GPO -All | ForEach-Object {
    $filename = "$($_.DisplayName -replace '[\\/:*?"<>|]', '_').html"
    Get-GPOReport -Guid $_.Id -ReportType HTML -Path "C:\GPO_Reports\$filename"
}
```