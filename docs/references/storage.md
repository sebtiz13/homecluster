# Storage

The storage uses ZFS with pool `data` (_default name_) for applications data, managed by the [OpenEBS ZFS CSI Driver](https://github.com/openebs/zfs-localpv).

On the cluster, applications use the `zfs.csi.openebs.io` provisioner to create persistent volume claims.

## List of available `StorageClass`

- `local-path` (**default**): Uses [Rancher's Local Path Provisioner](https://github.com/rancher/local-path-provisioner) for creating persistent volume claims using local storage on the respective node.
- `openebs-zfspv`: For general purpose workloads on ZFS pool with `recordsize=128k`.
- `openebs-zfspv-db`: Optimized for database workloads (e.g., PostgreSQL) on ZFS pool with `recordsize=16k`.

- `zfspv-block`: Enables raw block volume creation ([More information](https://github.com/openebs/zfs-localpv/blob/develop/docs/raw-block-volume.md)).

## List of available `VolumeSnapshotClass`

- `zfspv-snapclass` (**default**): This volume snapshot class enable ability to create ZFS snapshot from created `PersistentVolumeClaim`.
