FROM mcr.microsoft.com/powershell:lts-ubuntu-22.04

# Update packages and Install cron
RUN apt-get update && apt-get install -y cron

WORKDIR /src

# Copy the backup script
COPY Backup-PterodactylServers.ps1 .
RUN chmod 0744 /src/Backup-PterodactylServers.ps1

# Copy the entrypoint file
COPY entrypoint /
RUN chmod 0744 /entrypoint

# Run the entrypoint
CMD /entrypoint 
