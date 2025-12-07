# Backup

This app use cronjob to backup and send it to Baku every days.

## Condition for PVC to be backup

- The PVC need to have `openebs-zfspv` class
- The PVC need to have `backup.local/enabled=true` annotation
