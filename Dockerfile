FROM ubuntu:noble

# Set environment variable for testing
ENV DOCKER_TESTING=1
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    sudo \
    python3 \
    python3-pip \
    python3-venv \
    git \
    curl \
    wget \
    ca-certificates \
    software-properties-common \
    dirmngr \
    gpg-agent \
    bash \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create test user with same name as host
RUN useradd -m agucova && \
    echo "agucova ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/agucova && \
    chmod 0440 /etc/sudoers.d/agucova

# Set up working directory
WORKDIR /home/agucova/workspace
COPY . /home/agucova/workspace/

# Fix permissions
RUN chown -R agucova:agucova /home/agucova/workspace

# Switch to the test user
USER agucova
WORKDIR /home/agucova/workspace

# Install uv 
RUN curl -LsSf https://astral.sh/uv/install.sh | bash

# Add uv to PATH for subsequent commands
ENV PATH="/home/agucova/.local/bin:${PATH}"

# Create a Python virtual environment and install dependencies
RUN python3 -m venv /home/agucova/venv && \
    /home/agucova/.local/bin/uv pip install --python /home/agucova/venv/bin/python3 pyinfra pydantic-settings

# Set up environment
ENV PYTHONPATH="/home/agucova/workspace:${PYTHONPATH}"
ENV PATH="/home/agucova/venv/bin:${PATH}"

# Default command just opens a shell with bash
SHELL ["/bin/bash", "-c"]
CMD ["/bin/bash"]