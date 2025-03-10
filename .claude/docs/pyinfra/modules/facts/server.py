from __future__ import annotations

import os
import re
import shutil
from datetime import datetime
from tempfile import mkdtemp
from typing import Dict, List, Optional

from dateutil.parser import parse as parse_date
from distro import distro
from typing_extensions import TypedDict

from pyinfra.api import FactBase, ShortFactBase
from pyinfra.api.util import try_int
from pyinfra.facts import crontab

ISO_DATE_FORMAT = "%Y-%m-%dT%H:%M:%S%z"


class User(FactBase):
    """
    Returns the name of the current user.
    """

    def command(self):
        return "echo $USER"


class Home(FactBase[Optional[str]]):
    """
    Returns the home directory of the given user, or the current user if no user is given.
    """

    def command(self, user=""):
        return f"echo ~{user}"


class Path(FactBase):
    """
    Returns the path environment variable of the current user.
    """

    def command(self):
        return "echo $PATH"


class TmpDir(FactBase):
    """
    Returns the temporary directory of the current server, if configured.
    """

    def command(self):
        return "echo $TMPDIR"


class Hostname(FactBase):
    """
    Returns the current hostname of the server.
    """

    def command(self):
        return "uname -n"


class Kernel(FactBase):
    """
    Returns the kernel name according to ``uname``.
    """

    def command(self):
        return "uname -s"


class KernelVersion(FactBase):
    """
    Returns the kernel version according to ``uname``.
    """

    def command(self):
        return "uname -r"


# Deprecated/renamed -> Kernel
class Os(FactBase[str]):
    """
    Returns the OS name according to ``uname``.

    .. warning::
        This fact is deprecated/renamed, please use the ``server.Kernel`` fact.
    """

    def command(self):
        return "uname -s"


# Deprecated/renamed -> KernelVersion
class OsVersion(FactBase[str]):
    """
    Returns the OS version according to ``uname``.

    .. warning::
        This fact is deprecated/renamed, please use the ``server.KernelVersion`` fact.
    """

    def command(self):
        return "uname -r"


class Arch(FactBase[str]):
    """
    Returns the system architecture according to ``uname``.
    """

    # ``uname -p`` is not portable and returns ``unknown`` on Debian.
    # ``uname -m`` works on most Linux and BSD systems.
    def command(self):
        return "uname -m"


class Command(FactBase[str]):
    """
    Returns the raw output lines of a given command.
    """

    def command(self, command):
        return command


class Which(FactBase[Optional[str]]):
    """
    Returns the path of a given command according to `command -v`, if available.
    """

    def command(self, command):
        return "command -v {0} || true".format(command)


class Date(FactBase[datetime]):
    """
    Returns the current datetime on the server.
    """

    default = datetime.now

    def command(self):
        return f"date +'{ISO_DATE_FORMAT}'"

    def process(self, output) -> datetime:
        return datetime.strptime(list(output)[0], ISO_DATE_FORMAT)


class MacosVersion(FactBase[str]):
    """
    Returns the installed MacOS version.
    """

    def requires_command(self) -> str:
        return "sw_vers"

    def command(self):
        return "sw_vers -productVersion"


class MountsDict(TypedDict):
    device: str
    type: str
    options: list[str]


class Mounts(FactBase[Dict[str, MountsDict]]):
    """
    Returns a dictionary of mounted filesystems and information.

    .. code:: python

        {
            "/": {
                "device": "/dev/mv2",
                "type": "ext4",
                "options": [
                    "rw",
                    "relatime"
                ]
            },
        }
    """

    default = dict

    def command(self):
        return "mount"

    def process(self, output) -> dict[str, MountsDict]:
        devices: dict[str, MountsDict] = {}

        for line in output:
            is_map = False
            if line.startswith("map "):
                line = line[4:]
                is_map = True

            device, _, path, other_bits = line.split(" ", 3)

            if is_map:
                device = "map {0}".format(device)

            if other_bits.startswith("type"):
                _, type_, options = other_bits.split(" ", 2)
                options = options.strip("()").split(",")
            else:
                options = other_bits.strip("()").split(",")
                type_ = options.pop(0)

            devices[path] = {
                "device": device,
                "type": type_,
                "options": [option.strip() for option in options],
            }

        return devices


class KernelModules(FactBase):
    """
    Returns a dictionary of kernel module name -> info.

    .. code:: python

        {
            "module_name": {
                "size": 0,
                "instances": 0,
                "state": "Live",
            },
        }
    """

    def command(self):
        return "! test -f /proc/modules || cat /proc/modules"

    default = dict

    def process(self, output):
        modules = {}

        for line in output:
            name, size, instances, depends, state, _ = line.split(" ", 5)
            instances = int(instances)

            module = {
                "size": size,
                "instances": instances,
                "state": state,
            }

            if depends != "-":
                module["depends"] = [value for value in depends.split(",") if value]

            modules[name] = module

        return modules


class LsbRelease(FactBase):
    """
    Returns a dictionary of release information using ``lsb_release``.

    .. code:: python

        {
            "id": "Ubuntu",
            "description": "Ubuntu 18.04.2 LTS",
            "release": "18.04",
            "codename": "bionic",
            ...
        }
    """

    def command(self):
        return "lsb_release -ca"

    def requires_command(self):
        return "lsb_release"

    def process(self, output):
        items = {}

        for line in output:
            if ":" not in line:
                continue

            key, value = line.split(":", 1)

            key = key.strip().lower()

            # Turn "distributor id" into "id"
            if " " in key:
                key = key.split(" ")[-1]

            value = value.strip()

            items[key] = value

        return items


class OsRelease(FactBase):
    """
    Returns a dictionary of release information stored in ``/etc/os-release``.

    .. code:: python

        {
          "name": "EndeavourOS",
          "pretty_name": "EndeavourOS",
          "id": "endeavouros",
          "id_like": "arch",
          "build_id": "2024.06.25",
          ...
        }
    """

    def command(self):
        return "cat /etc/os-release"

    def process(self, output):
        items = {}

        for line in output:
            if "=" in line:
                key, value = line.split("=", 1)
                items[key.strip().lower()] = value.strip().strip('"')

        return items


class Sysctl(FactBase):
    """
    Returns a dictionary of sysctl settings and values.

    .. code:: python

        {
            "fs.inotify.max_queued_events": 16384,
            "fs.inode-state": [
                44565,
                360,
            ],
        }
    """

    default = dict

    def command(self, keys=None):
        if keys is None:
            return "sysctl -a"
        return f"sysctl {' '.join(keys)}"

    def process(self, output):
        sysctls = {}

        for line in output:
            key = values = None

            if "=" in line:
                key, values = line.split("=", 1)
            elif ":" in line:
                key, values = line.split(":", 1)
            else:
                continue  # pragma: no cover

            if key and values:
                key = key.strip()
                values = values.strip()

                if re.match(r"^[a-zA-Z0-9_\.\s]+$", values):
                    values = [try_int(item.strip()) for item in values.split()]

                    if len(values) == 1:
                        values = values[0]

                sysctls[key] = values

        return sysctls


class Groups(FactBase[List[str]]):
    """
    Returns a list of groups on the system.
    """

    def command(self):
        return "cat /etc/group"

    default = list

    def process(self, output) -> list[str]:
        groups: list[str] = []

        for line in output:
            if ":" in line:
                groups.append(line.split(":")[0])

        return groups


# for compatibility
CrontabDict = crontab.CrontabDict
Crontab = crontab.Crontab


class Users(FactBase):
    """
    Returns a dictionary of users -> details.

    .. code:: python

        {
            "user_name": {
                "comment": "Full Name",
                "home": "/home/user_name",
                "shell": "/bin/bash,
                "group": "main_user_group",
                "groups": [
                    "other",
                    "groups"
                ],
                "uid": user_id,
                "gid": main_user_group_id,
                "lastlog": last_login_time,
                "password": encrypted_password,
            },
        }
    """

    def command(self):
        return """

        for i in `cat /etc/passwd | cut -d: -f1`; do
            ENTRY=`grep ^$i: /etc/passwd`;
            LASTLOG=`(((lastlog -u $i || lastlogin $i) 2> /dev/null) | grep ^$i | tr -s ' ')`;
            PASSWORD=`grep ^$i: /etc/shadow | cut -d: -f2`;
            echo "$ENTRY|`id -gn $i`|`id -Gn $i`|$LASTLOG|$PASSWORD";
        done
    """.strip()

    default = dict

    def process(self, output):
        users = {}
        rex = r"[A-Z][a-z]{2} [A-Z][a-z]{2} {1,2}\d+ .+$"

        for line in output:
            entry, group, user_groups, lastlog, password = line.rsplit("|", 4)

            if entry:
                # Parse out the comment/home/shell
                entries = entry.split(":")

                # Parse groups
                groups = []
                for group_name in user_groups.split(" "):
                    # We only want secondary groups here
                    if group_name and group_name != group:
                        groups.append(group_name)

                raw_login_time = None
                login_time = None

                # Parse lastlog info
                # lastlog output varies, which is why I use regex to match login time
                login = re.search(rex, lastlog)
                if login:
                    raw_login_time = login.group()
                    login_time = parse_date(raw_login_time)

                users[entries[0]] = {
                    "home": entries[5] or None,
                    "comment": entries[4] or None,
                    "shell": entries[6] or None,
                    "group": group,
                    "groups": groups,
                    "uid": int(entries[2]),
                    "gid": int(entries[3]),
                    "lastlog": raw_login_time,
                    "login_time": login_time,
                    "password": password,
                }

        return users


class LinuxDistributionDict(TypedDict):
    name: Optional[str]
    major: Optional[int]
    minor: Optional[int]
    release_meta: Dict


class LinuxDistribution(FactBase[LinuxDistributionDict]):
    """
    Returns a dict of the Linux distribution version. Ubuntu, Debian, CentOS,
    Fedora & Gentoo currently. Also contains any key/value items located in
    release files.

    .. code:: python

        {
            "name": "Ubuntu",
            "major": 20,
            "minor": 04,
            "release_meta": {
                "CODENAME": "focal",
                "ID_LIKE": "debian",
                ...
            }
        }
    """

    def command(self) -> str:
        return (
            "cd /etc/ && for file in $(ls -pdL *-release | grep -v /); "
            'do echo "/etc/${file}"; cat "/etc/${file}"; echo ---; '
            "done"
        )

    name_to_pretty_name = {
        "alpine": "Alpine",
        "centos": "CentOS",
        "fedora": "Fedora",
        "gentoo": "Gentoo",
        "opensuse": "openSUSE",
        "rhel": "RedHat",
        "ubuntu": "Ubuntu",
        "debian": "Debian",
    }

    @staticmethod
    def default() -> LinuxDistributionDict:
        return {
            "name": None,
            "major": None,
            "minor": None,
            "release_meta": {},
        }

    def process(self, output) -> LinuxDistributionDict:
        parts = {}
        for part in "\n".join(output).strip().split("---"):
            if not part.strip():
                continue
            try:
                filename, content = part.strip().split("\n", 1)
                parts[filename] = content
            except ValueError:
                # skip empty files
                # for instance arch linux as an empty file at /etc/arch-release
                continue

        release_info = self.default()
        if not parts:
            return release_info

        temp_root = mkdtemp()
        try:
            temp_etc_dir = os.path.join(temp_root, "etc")
            os.mkdir(temp_etc_dir)

            for filename, content in parts.items():
                with open(
                    os.path.join(temp_etc_dir, os.path.basename(filename)), "w", encoding="utf-8"
                ) as fp:
                    fp.write(content)

            parsed = distro.LinuxDistribution(
                root_dir=temp_root,
                include_lsb=False,
                include_uname=False,
            )

            release_meta = {key.upper(): value for key, value in parsed.os_release_info().items()}
            # Distro 1.7+ adds this, breaking tests
            # TODO: fix this!
            release_meta.pop("RELEASE_CODENAME", None)

            release_info.update(
                {
                    "name": self.name_to_pretty_name.get(parsed.id(), parsed.name()),
                    "major": try_int(parsed.major_version()) or None,
                    "minor": try_int(parsed.minor_version()) or None,
                    "release_meta": release_meta,
                },
            )

        finally:
            shutil.rmtree(temp_root)

        return release_info


class LinuxName(ShortFactBase[str]):
    """
    Returns the name of the Linux distribution. Shortcut for
    ``host.get_fact(LinuxDistribution)['name']``.
    """

    fact = LinuxDistribution

    def process_data(self, data) -> str:
        return data["name"]


class SelinuxDict(TypedDict):
    mode: Optional[str]


class Selinux(FactBase[SelinuxDict]):
    """
    Discovers the SELinux related facts on the target host.

    .. code:: python

        {
            "mode": "enabled",
        }
    """

    def command(self):
        return "sestatus"

    def requires_command(self) -> str:
        return "sestatus"

    @staticmethod
    def default() -> SelinuxDict:
        return {
            "mode": None,
        }

    def process(self, output) -> SelinuxDict:
        selinux_info = self.default()

        match = re.match(r"^SELinux status:\s+(\S+)", "\n".join(output))

        if not match:
            return selinux_info

        selinux_info["mode"] = match.group(1)

        return selinux_info


class LinuxGui(FactBase[List[str]]):
    """
    Returns a list of available Linux GUIs.
    """

    def command(self):
        return "ls /usr/bin/*session || true"

    default = list

    known_gui_binaries = {
        "/usr/bin/gnome-session": "GNOME",
        "/usr/bin/mate-session": "MATE",
        "/usr/bin/lxsession": "LXDE",
        "/usr/bin/plasma_session": "KDE Plasma",
        "/usr/bin/xfce4-session": "XFCE 4",
    }

    def process(self, output) -> list[str]:
        gui_names = []

        for line in output:
            gui_name = self.known_gui_binaries.get(line)
            if gui_name:
                gui_names.append(gui_name)

        return gui_names


class HasGui(ShortFactBase[bool]):
    """
    Returns a boolean indicating the remote side has GUI capabilities. Linux only.
    """

    fact = LinuxGui

    def process_data(self, data) -> bool:
        return len(data) > 0


class Locales(FactBase[List[str]]):
    """
    Returns installed locales on the target host.

    .. code:: python

        ["C.UTF-8", "en_US.UTF-8"]
    """

    def command(self) -> str:
        return "locale -a"

    def requires_command(self) -> str:
        return "locale"

    default = list

    def process(self, output) -> list[str]:
        # replace utf8 with UTF-8 to match names in /etc/locale.gen
        # return a list of enabled locales
        return [line.replace("utf8", "UTF-8") for line in output]


class SecurityLimits(FactBase):
    """
    Returns a list of security limits on the target host.

    .. code:: python

        [
            {
                "domain": "*",
                "limit_type": "soft",
                "item": "nofile",
                "value": "1048576"
            },
            {
                "domain": "*",
                "limit_type": "hard",
                "item": "nofile",
                "value": "1048576"
            },
            {
                "domain": "root",
                "limit_type": "soft",
                "item": "nofile",
                "value": "1048576"
            },
            {
                "domain": "root",
                "limit_type": "hard",
                "item": "nofile",
                "value": "1048576"
            },
            {
                "domain": "*",
                "limit_type": "soft",
                "item": "memlock",
                "value": "unlimited"
            },
            {
                "domain": "*",
                "limit_type": "hard",
                "item": "memlock",
                "value": "unlimited"
            },
            {
                "domain": "root",
                "limit_type": "soft",
                "item": "memlock",
                "value": "unlimited"
            },
            {
                "domain": "root",
                "limit_type": "hard",
                "item": "memlock",
                "value": "unlimited"
            }
        ]
    """

    def command(self):
        return "cat /etc/security/limits.conf"

    default = list

    def process(self, output):
        limits = []

        for line in output:
            if line.startswith("#") or not len(line.strip()):
                continue

            domain, limit_type, item, value = line.split()

            limits.append(
                {
                    "domain": domain,
                    "limit_type": limit_type,
                    "item": item,
                    "value": value,
                },
            )

        return limits
