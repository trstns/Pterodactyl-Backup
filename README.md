# Pterodactyl Backup

This is a simple script which will find all of your servers in Pterodactyl and export a backup file which can then be stored anywhere you need.

The script will create a backup of the server, download it and then delete it from Pterodactyl so that you don't use up all the backup slots for the server.

I have wrapped the script in an ubuntu docker container so that I can have it running on my homelab server, but the script can be used standalone with a few updates.

**Currently there is no error checking or alerting.  I hope to add this at some point.**

## How to use

- Clone this repository onto your docker server.
- Update the enviroment variables in compose.yml
- Update the mountpoint for /backups so that the backups are saved somewhere safe
- Run `docker compose up -d` to start the container
