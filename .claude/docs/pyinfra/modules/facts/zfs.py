"""
Gather information about ZFS filesystems.
"""

from pyinfra.api import FactBase, ShortFactBase


def _process_zfs_props_table(output):
    datasets: dict = {}
    for line in output:
        dataset, property, value, source = tuple(line.split("\t"))
        if dataset not in datasets:
            datasets[dataset] = {}
        datasets[dataset][property] = value
    return datasets


class ZfsPools(FactBase):
    def command(self):
        return "zpool get -H all"

    def process(self, output):
        return _process_zfs_props_table(output)


class ZfsDatasets(FactBase):
    def command(self):
        return "zfs get -H all"

    def process(self, output):
        return _process_zfs_props_table(output)


class ZfsFilesystems(ShortFactBase):
    fact = ZfsDatasets

    def process_data(self, data):
        return {
            name: props
            for name, props in data.items()
            if props.get("type") == "filesystem"
        }


class ZfsSnapshots(ShortFactBase):
    fact = ZfsDatasets

    def process_data(self, data):
        return {
            name: props
            for name, props in data.items()
            if props.get("type") == "snapshot"
        }


class ZfsVolumes(ShortFactBase):
    fact = ZfsDatasets

    def process_data(self, data):
        return {
            name: props for name, props in data.items() if props.get("type") == "volume"
        }


# TODO: remove these in v4! Or flip the convention and remove all the other fact prefixes!
Pools = ZfsPools
Datasets = ZfsDatasets
Filesystems = ZfsFilesystems
Snapshots = ZfsSnapshots
Volumes = ZfsVolumes
