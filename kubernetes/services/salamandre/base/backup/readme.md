# Backup

This app use cronjob to backup and send it to Baku every days.

## Condition for PVC to be backup

- The PVC need to have `openebs-zfspv` class
- The PVC need to have `backup.local/enabled=true` annotation

## Available environment variables

- `PVC_STORAGE_CLASS`: PVC storage class (Default: `openebs-zfspv`)
- `SNAPSHOT_CLASS`: Snapshot class (Default: `zfspv-snapclass`)
- `FULL_BACKUP_DAY`: The day of full backup (0=Saturday, 1=Monday, Default: `1`)
- `S3_BUCKET_NAME`: S3 bucket name (Default: `backup`)
- `KEEP_DAYS`: Keep snapshot on machine duration (in days, Default: `3`)
- `FORCE_FULL_BACKUP`: Force an full backup (Default: `false`)
- `MANUAL_DATE`: Custom date for running script (Format: YYYYMMDD, Default: Today)
