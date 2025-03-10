from __future__ import annotations

import re
from typing import Iterable


def parse_packages(regex: str, output: Iterable[str]) -> dict[str, set[str]]:
    packages: dict[str, set[str]] = {}

    for line in output:
        matches = re.match(regex, line)

        if matches:
            name = matches.group(1)
            packages.setdefault(name, set())
            packages[name].add(matches.group(2))

    return packages


def _parse_yum_or_zypper_repositories(output):
    repos = []

    current_repo: dict[str, str] = {}
    for line in output:
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        if line.startswith("["):
            if current_repo:
                repos.append(current_repo)
                current_repo = {}

            current_repo["name"] = line[1:-1]

        if current_repo and "=" in line:
            key, value = re.split(r"\s*=\s*", line, maxsplit=1)
            current_repo[key] = value

    if current_repo:
        repos.append(current_repo)

    return repos


parse_yum_repositories = _parse_yum_or_zypper_repositories

parse_zypper_repositories = _parse_yum_or_zypper_repositories
