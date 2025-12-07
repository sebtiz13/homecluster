# Cluster backup/Restore

## Backup

The salamandre cluster is automatically backup each day all PVCs marked with `backup.local/enabled: true` label.

- The database run they backup with barman at 3am.
- The kubernetes PVC run they backup at 3:05 am.

  > **NOTE**: This create one full backup each first day of week (even database), and next days is incremental.

### Manual backup

The cron jobs is disabled on sandbox but it's can be run manually with following commands :

- Kubernetes PVC: `kubectl create job backup-$(date +%Y%m%d%H%M%S) --from=cronjob/zfs-s3-backup -n backup`

## Restore

> 🚧 This section is under construction

Run the following commands for restore the cluster.

- Restore Nextcloud data :

  If you doesn't restore the database, you need run the following commands :

  1. Retrieve pod name: run `kubectl get pods -n nextcloud -lapp.kubernetes.io/name=nextcloud,app.kubernetes.io/component=app`
  2. Run `kubectl exec <pod name> -n nextcloud -it -- su -m www-data -s /bin/sh -c 'php occ files:scan --all'` inside pod

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
