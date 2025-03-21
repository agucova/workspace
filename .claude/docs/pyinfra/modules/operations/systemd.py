"""
Manage systemd services.
"""

from __future__ import annotations

import shlex

from pyinfra import host
from pyinfra.api import StringCommand, operation
from pyinfra.facts.systemd import SystemdEnabled, SystemdStatus, _make_systemctl_cmd

from .util.service import handle_service_control


@operation(is_idempotent=False)
def daemon_reload(
    user_mode=False, machine: str | None = None, user_name: str | None = None
):
    """
    Reload the systemd daemon to read unit file changes.

    + user_mode: whether to use per-user systemd (systemctl --user) or not
    + machine: the machine name to connect to
    + user_name: connect to a specific user's systemd session
    """

    systemctl_cmd = _make_systemctl_cmd(
        user_mode=user_mode,
        machine=machine,
        user_name=user_name,
    )

    yield StringCommand(systemctl_cmd, "daemon-reload")


_daemon_reload = daemon_reload._inner  # noqa: E305


@operation()
def service(
    service: str,
    running=True,
    restarted=False,
    reloaded=False,
    command: str | None = None,
    enabled: bool | None = None,
    daemon_reload=False,
    user_mode=False,
    machine: str | None = None,
    user_name: str | None = None,
):
    """
    Manage the state of systemd managed units.

    + service: name of the systemd unit to manage
    + running: whether the unit should be running
    + restarted: whether the unit should be restarted
    + reloaded: whether the unit should be reloaded
    + command: custom command to pass like: ``/etc/rc.d/<name> <command>``
    + enabled: whether this unit should be enabled/disabled on boot
    + daemon_reload: reload the systemd daemon to read updated unit files
    + user_mode: whether to use per-user systemd (systemctl --user) or not
    + machine: the machine name to connect to
    + user_name: connect to a specific user's systemd session

    **Examples:**

    .. code:: python

        systemd.service(
            name="Restart and enable the dnsmasq service",
            service="dnsmasq.service",
            running=True,
            restarted=True,
            enabled=True,
        )

        systemd.service(
            name="Enable logrotate timer",
            service="logrotate.timer",
            running=True,
            enabled=True,
        )

    """

    systemctl_cmd = _make_systemctl_cmd(
        user_mode=user_mode,
        machine=machine,
        user_name=user_name,
    )

    if not service.endswith(
        (
            ".service",
            ".socket",
            ".device",
            ".mount",
            ".automount",
            ".swap",
            ".target",
            ".path",
            ".timer",
            ".slice",
            ".scope",
        )
    ):
        service = "{0}.service".format(service)

    if daemon_reload:
        yield from _daemon_reload(
            user_mode=user_mode,
            machine=machine,
            user_name=user_name,
        )

    yield from handle_service_control(
        host,
        service,
        host.get_fact(
            SystemdStatus,
            user_mode=user_mode,
            machine=machine,
            user_name=user_name,
            services=[service],
        ),
        " ".join([systemctl_cmd.get_raw_value(), "{1}", "{0}"]),
        running,
        restarted,
        reloaded,
        command,
    )

    if isinstance(enabled, bool):
        systemd_enabled = host.get_fact(
            SystemdEnabled,
            user_mode=user_mode,
            machine=machine,
            user_name=user_name,
            services=[service],
        )
        is_enabled = systemd_enabled.get(service, False)

        # Isn't enabled and want enabled?
        if not is_enabled and enabled is True:
            yield "{0} enable {1}".format(systemctl_cmd, shlex.quote(service))

        # Is enabled and want disabled?
        elif is_enabled and enabled is False:
            yield "{0} disable {1}".format(systemctl_cmd, shlex.quote(service))
