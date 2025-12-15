# Cluster backup/Restore

> Currently, only **salamandre** can be backup.

## Backup

The **salamandre** cluster automatically backup each day (around 3am) all PVCs marked with `backup.local/enabled: true` label and sended to **baku** in `.zvol.gz` format.

> **NOTE**: Automatic backup is suspended on sandbox.

Deep dive :

- The database run they backup at 3am.
- The kubernetes PVC run they backup at 3:05 am (This delay is to ensure that the database is backed up).
- An full backup is created each Monday or if yesterday backup could not be found on one server, otherwise an incremental backup is done.

### Manual backup

You can manually create an custom backup at anytime with following commands :

```text
Usage: ./scripts/manual-backup.sh [OPTIONS]

Launch an save Kubernetes job based on existing CronJob.

OPTIONS:
  -d, --date YYYYMMDD Force run an specific date backup (mainly for testing).
                      (Default: Today)
  -f, --full          Force an full backup (ignore incremental logic).
  -h, --help          Show this help message.
```

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
