# PyInfra apt-fast Module

This module provides operations to use apt-fast as a drop-in replacement for apt in PyInfra, enabling parallel downloads for significant speed improvements during package installation.

## Overview

The apt-fast module is designed to:

1. Accelerate package installation with parallel downloads
2. Serve as a drop-in replacement for PyInfra's apt operations
3. Minimize changes required to existing code

## Usage

### Import the module

```python
import apt_fast
```

### Basic operations

```python
# Update repositories (with 8 parallel downloads)
apt_fast.update(
    name="Update apt repositories",
    parallel=8,
    _sudo=True,
)

# Install packages (with 16 parallel downloads)
apt_fast.packages(
    name="Install development tools",
    packages=["git", "build-essential", "python3-dev"],
    no_recommends=True,
    parallel=16,
    _sudo=True,
)

# Upgrade all packages
apt_fast.upgrade(
    name="Upgrade all packages",
    auto_remove=True,
    parallel=16,
    _sudo=True,
)
```

### Replace apt with apt-fast in existing code

Original code:
```python
from pyinfra.operations import apt

apt.packages(
    name="Install development tools",
    packages=["git", "build-essential"],
    _sudo=True,
)
```

New code:
```python
import apt_fast

apt_fast.packages(
    name="Install development tools",
    packages=["git", "build-essential"],
    parallel=16,  # New parameter
    _sudo=True,
)
```

## Performance Benefits

- Parallel downloads significantly reduce package installation time
- The `parallel` parameter controls the number of concurrent downloads
- Recommended value: 8-16 for most systems, lower for systems with limited bandwidth

## Implementation Details

- Implements the same interface as PyInfra's apt operations with an additional `parallel` parameter
- Uses apt-fast under the hood for actual package management
- Maintains idempotency and all other features of the original apt operations
- Configures apt-fast with optimal defaults for non-interactive use

## Requirements

- apt-fast must be installed on the target system
- The apt-fast PPA should be added (ppa:apt-fast/stable)
- PyInfra v3.x

## Testing

To test the apt-fast module:

```bash
uv run docker_test.py run test_apt_fast.test_apt_fast
```