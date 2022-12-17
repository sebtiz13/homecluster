# Cluster backup/Restore

## Backup

The salamandre cluster is automatically backup each day.

- The database run they backup with barman at 1am.
- The kubernetes PVC run they backup at 2am.

  > **NOTE**: This create one full backup each first day of week (even database), and next days is incremental.

### Sandbox backup

The cron jobs is disabled on sandbox but it's can be run manually with following commands :

- Database: `sudo -u barman /usr/bin/barman -q backup --wait main_backup`
- Kubernetes PVC: `sudo -u backup /opt/backup-cluster/backup.sh`

## Restore

> 🚧 This section is under construction

Run the following commands for restore the cluster.

- List database backup : `barman list-backup main_backup`
- Restore database : `BACKUP_ID=<id> sudo /opt/backup-cluster/barman-restore.sh`

  _**NOTE**: Replace `<id>` by the backup if retrieve from the list of backup._

- Restore Kubernetes PVC: `sudo -u backup /opt/backup-cluster/restore.sh`

### Apps specific

#### Nextcloud

After restore files run this command in nextcloud pod: `su -m www-data -s /bin/sh -c 'php occ files:scan --all'`

### Troubleshooting

#### Barman: `error: unexpected termination of replication stream`

Full error :

```log
error: unexpected termination of replication stream

barman.command_wrappers INFO: main_backup: pg_receivewal: starting log streaming at 0/2D000000 (timeline 1)
barman.command_wrappers INFO: main_backup: pg_receivewal: error: unexpected termination of replication stream: ERROR:  requested WAL segment 00000001000000000000002D has already been removed
barman.command_wrappers INFO: main_backup: pg_receivewal: error: disconnected
```

If this error is thrown, you need to run the following command `barman receive-wal main_backup --reset`.
