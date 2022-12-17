#!/usr/bin/env bash
systemctl stop postgresql@13-main.service

chown barman:barman -R "$PGDATA"
barman recover main_backup "$BACKUP_ID" "$PGDATA"
chown postgres:postgres -R "$PGDATA" && chmod 750 -R "$PGDATA"

systemctl start postgresql@13-main.service
