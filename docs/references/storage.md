# Storage

The storage use ZFS with pool `data` (_default name_) for the applications data.

On the cluster, the applications use `openebs-zfspv` for access to ZFS pool.

## List of available `StorageClass`

- `local-path` (**default**): This storage class use [Rancher's Local Path Provisioner](https://github.com/rancher/local-path-provisioner) for enable ability to create persistent volume claims out of the box using local storage on the respective node.
- `openebs-zfspv`: This storage class use [OpenEBS ZFS CSI Driver](https://github.com/openebs/zfs-localpv) for enable ability to create persistent volume claims on ZFS pool.
- `zfspv-block`: This storage class enable ability to create raw block volume ([More information on documentation](https://github.com/openebs/zfs-localpv/blob/develop/docs/raw-block-volume.md)).

## List of available `VolumeSnapshotClass`

- `zfspv-snapclass` (**default**): This volume snapshot class enable ability to create ZFS snapshot from created `PersistentVolumeClaim`.
