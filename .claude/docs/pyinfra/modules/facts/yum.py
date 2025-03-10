from __future__ import annotations

from pyinfra.api import FactBase

from .util import make_cat_files_command
from .util.packaging import parse_yum_repositories


class YumRepositories(FactBase):
    """
    Returns a list of installed yum repositories:

    .. code:: python

        [
            {
                "name": "CentOS-$releasever - Apps",
                "baseurl": "http://mirror.centos.org/$contentdir/$releasever/Apps/$basearch/os/",
                "gpgcheck": "1",
                "enabled": "1",
                "gpgkey": "file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial",
            },
        ]
    """

    def command(self) -> str:
        return make_cat_files_command(
            "/etc/yum.conf",
            "/etc/yum.repos.d/*.repo",
        )

    def requires_command(self) -> str:
        return "yum"

    default = list

    def process(self, output):
        return parse_yum_repositories(output)
