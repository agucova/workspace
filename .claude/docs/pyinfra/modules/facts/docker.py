"""
Facts about Docker containers, volumes and networks. These facts give you information from the view
of the current inventory host. See the :doc:`../connectors/docker` to use Docker containers as
inventory directly.
"""

from __future__ import annotations

import json

from pyinfra.api import FactBase


class DockerFactBase(FactBase):
    abstract = True

    docker_type: str

    def requires_command(self, *args, **kwargs) -> str:
        return "docker"

    def process(self, output):
        output = "".join(output)
        return json.loads(output)


class DockerSystemInfo(DockerFactBase):
    """
    Returns ``docker system info`` output in JSON format.
    """

    def command(self) -> str:
        return 'docker system info --format="{{json .}}"'


# All Docker objects
#


class DockerContainers(DockerFactBase):
    """
    Returns ``docker inspect`` output for all Docker containers.
    """

    def command(self) -> str:
        return "docker container inspect `docker ps -qa`"


class DockerImages(DockerFactBase):
    """
    Returns ``docker inspect`` output for all Docker images.
    """

    def command(self) -> str:
        return "docker image inspect `docker images -q`"


class DockerNetworks(DockerFactBase):
    """
    Returns ``docker inspect`` output for all Docker networks.
    """

    def command(self) -> str:
        return "docker network inspect `docker network ls -q`"


# Single Docker objects
#


class DockerSingleMixin(DockerFactBase):
    def command(self, object_id):
        return "docker {0} inspect {1} 2>&- || true".format(
            self.docker_type,
            object_id,
        )


class DockerContainer(DockerSingleMixin):
    """
    Returns ``docker inspect`` output for a single Docker container.
    """

    docker_type = "container"


class DockerImage(DockerSingleMixin):
    """
    Returns ``docker inspect`` output for a single Docker image.
    """

    docker_type = "image"


class DockerNetwork(DockerSingleMixin):
    """
    Returns ``docker inspect`` output for a single Docker network.
    """

    docker_type = "network"


class DockerVolumes(DockerFactBase):
    """
    Returns ``docker inspect`` output for all Docker volumes.
    """

    def command(self) -> str:
        return "docker volume inspect `docker volume ls -q`"


class DockerVolume(DockerSingleMixin):
    """
    Returns ``docker inspect`` output for a single Docker container.
    """

    docker_type = "volume"
