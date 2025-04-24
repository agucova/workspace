import platform
from typing import Iterable

from pyinfra.api.facts import FactBase


class FlatpakRemotes(FactBase):
    """
    Returns a list of configured Flatpak remotes.
    Linux-only.
    """

    def command(self) -> str:
        return "flatpak remotes --show-details 2>/dev/null || true"

    def requires_command(self) -> str:
        return "flatpak"

    def process(self, output: Iterable[str]) -> list[str]:
        return [line.split()[0] for line in output if line.strip()]


class UserGroups(FactBase):
    """
    Returns a list of groups the current user belongs to.
    Cross-platform.
    """

    def command(self) -> str:
        return "groups"

    def process(self, output: Iterable[str]) -> list[str]:
        first_line = next(iter(output), "")
        return first_line.split()


class KernelParameters(FactBase):
    """
    Returns a list of current kernel parameters.
    Linux-only.
    """

    def command(self) -> str:
        return "cat /proc/cmdline 2>/dev/null || true"

    def process(self, output: Iterable[str]) -> list[str]:
        first_line = next(iter(output), "")
        return first_line.split() if first_line else []


class DebsigPolicies(FactBase):
    """
    Returns a list of configured debsig policies.
    Linux-only.
    """

    def command(self) -> str:
        # The original command doesn't work correctly if the directory doesn't exist
        # We need to ensure the command returns an empty string in case of errors
        return "ls -1 /etc/debsig/policies/ 2>/dev/null || true"

    def process(self, output: Iterable[str]) -> list[str]:
        return [line.strip() for line in output if line.strip()]

    @staticmethod
    def default() -> list[str]:
        # Return empty list as default if fact collection fails
        return []


class DockerConfiguration(FactBase):
    """
    Returns information about Docker configuration.
    Different paths/behavior for Linux/macOS.
    """

    def command(self) -> str:
        if platform.system() == "Darwin":
            return 'cat ~/Library/Group\\ Containers/group.com.docker/settings.json 2>/dev/null || echo "{}"'
        return 'cat /etc/docker/daemon.json 2>/dev/null || echo "{}"'

    def process(self, output: Iterable[str]) -> dict:
        import json

        return json.loads("".join(output))


class DefaultShell(FactBase):
    """
    Returns the default shell for a user.
    """

    def command(self, user: str) -> str:
        return f"getent passwd {user} | cut -d: -f7"

    def process(self, output: Iterable[str]) -> str:
        return next(iter(output), "").strip()


class UvInstallation(FactBase):
    """
    Returns information about uv installation and tools.
    """

    def command(self) -> str:
        return "uv --version && uv tool list 2>/dev/null || true"

    def process(self, output: Iterable[str]) -> dict:
        tools = {}
        installed = False
        current_tool = None

        for line in output:
            if line.startswith("uv"):
                installed = True
                version = line.split()[1]
            elif " v" in line:  # tool header with version
                current_tool, version = line.split(" v")
                tools[current_tool] = {"version": version, "binaries": []}
            elif line.startswith("- "):  # binary entry
                if current_tool:
                    tools[current_tool]["binaries"].append(line[2:])

        return {"installed": installed, "tools": tools}


class JuliaPackages(FactBase):
    """
    Returns a list of installed Julia packages.
    """

    def command(self) -> str:
        return "julia -e 'using Pkg; println(join(keys(Pkg.project().dependencies), \",\"))' 2>/dev/null || true"

    def requires_command(self) -> str:
        return "julia"

    def process(self, output: Iterable[str]) -> list[str]:
        packages = []
        for line in output:
            if line.strip():  # Skip empty lines
                packages.extend(pkg.strip() for pkg in line.split(",") if pkg.strip())
        return packages


class BunGlobalPackages(FactBase):
    """
    Returns a list of globally installed Bun packages.
    """

    def command(self) -> str:
        return "bun pm ls --global 2>/dev/null || true"

    def requires_command(self) -> str:
        return "bun"

    def process(self, output: Iterable[str]) -> dict:
        packages = {}
        for line in output:
            # Skip the header line or lines that don't contain package info
            if "@" not in line:
                continue

            # Handle lines like "├── @anthropic-ai/claude-code@0.2.53"
            # or "└── electron@34.0.0"
            if "├── " in line:
                pkg_info = line.split("├── ")[1]
            elif "└── " in line:
                pkg_info = line.split("└── ")[1]
            else:
                # For lines without tree symbols
                pkg_info = line

            # Now parse package@version format
            if "@" in pkg_info:
                # Handle NPM scoped packages correctly (@org/pkg@version)
                if pkg_info.startswith("@"):
                    # For scoped packages, find the last @
                    last_at_index = pkg_info.rindex("@")
                    name = pkg_info[:last_at_index]
                    version = pkg_info[last_at_index + 1 :]
                else:
                    # Regular packages (pkg@version)
                    parts = pkg_info.split("@", 1)
                    name = parts[0]
                    version = parts[1] if len(parts) > 1 else ""

                packages[name] = version

        return packages

    @staticmethod
    def default() -> dict:
        # Return empty dict as default if fact collection fails
        return {}
