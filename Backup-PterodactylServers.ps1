$PterodactylURI = $env:PTERODACTYLURL
$APIKey = $env:PTERODACTYLAPIKEY
$BackupLocation = "/backups"
$BackupsToKeep = $env:BACKUPSTOKEEP

$LogFile = "/src/backup.log"

function Log {
    param (
        [String]$Message
    )
    Write-Output "$(Get-Date -Format G) - $Message"
    Add-Content -Path $LogFile -Value "$(Get-Date -Format G) - $Message"
}

Log -Message "Starting Backup Script"

$Headers = @{
    "Authorization" = "Bearer $APIKey"

}
$PterodactylServers = Invoke-RestMethod -URI "$PterodactylURI/client" -Headers $Headers
$PterodactylServers = $PterodactylServers.data.attributes
$PterodactylServersForBackup = $PterodactylServers | Where-Object {$_.feature_limits.backups -ne 0}

Log "Found $($PterodactylServersForBackup.Count) servers to backup."

foreach ($Server in $PterodactylServersForBackup) {
    $ServerID = $Server.identifier
    $ServerName = $Server.name
    Log "Backing up $ServerName"

    # Create backup
    Log "Creating Backup of $ServerName"
    $BackupRequest = Invoke-RestMethod -URI "$PterodactylURI/client/servers/$ServerID/backups" -Headers $Headers -Method Post
    $BackupUUID = $BackupRequest.attributes.uuid
    if ($null -eq $BackupUUID) {
        # Backup failed
        Log "!!! Unable to create backup of $ServerName !!!"
    } else {
        # Wait for backup to complete
        do {
            Log "Waiting for backup of $ServerName to complete"
            Start-Sleep -Seconds 20 # So we don't trigger rate limits
            $Backup = Invoke-RestMethod -URI "$PterodactylURI/client/servers/$ServerID/backups/$BackupUUID" -Headers $Headers
        } until ($Backup.attributes.is_successful -eq $true)
        
        # Download Backup
        Log "Downloading Backup of $ServerName"
        $BackupDownload = Invoke-RestMethod -URI "$PterodactylURI/client/servers/$ServerID/backups/$BackupUUID/download" -Headers $Headers
        $BackupURL = $BackupDownload.attributes.url 
        New-Item -ItemType Directory -Path (Join-Path $BackupLocation "$ServerName") -ErrorAction SilentlyContinue | Out-Null
	    $BackupFile = Join-Path $BackupLocation "$ServerName/$ServerName - $(Get-Date -Format "yyyy-MM-dd HH-mm-ss").tar.gz"
        Invoke-WebRequest -Uri $BackupURL -OutFile "$BackupFile"

        # Delete Backup
        Log "Deleting Backup of $ServerName"
        $Backup = Invoke-RestMethod -URI "$PterodactylURI/client/servers/$ServerID/backups/$BackupUUID" -Headers $Headers -Method Delete

        # Prune old backups
        $BackupsToPrune = Get-ChildItem -Path (Join-Path $BackupLocation "$ServerName") -Filter "*.tar.gz" | Sort-Object LastWriteTime -Descending | Select-Object -Skip $BackupsToKeep
        $BackupsToPrune | ForEach-Object {
            Log "Pruning old backup: $($_.Name)"
            Remove-Item -Path $_.FullName
        }
    }
}

Log -Message "Finished Backup Script"
