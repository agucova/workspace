# Integrating apt-fast Module

This guide shows how to integrate the apt-fast module into the existing workspace codebase to improve package installation performance.

## Step 1: Import the module in packages.py

```python
from pyinfra.operations import apt, brew, files, flatpak, server, snap
import apt_fast  # Import our new module
```

## Step 2: Replace apt operations with apt-fast operations

Example replacements:

```python
# Original:
apt.update(name="Update apt repositories", cache_time=3600, _sudo=True)
apt.upgrade(name="Upgrade APT packages", auto_remove=True, _sudo=True)

# Replace with:
apt_fast.update(name="Update apt repositories", cache_time=3600, parallel=16, _sudo=True)
apt_fast.upgrade(name="Upgrade APT packages", auto_remove=True, parallel=16, _sudo=True)

# Original:
apt.packages(
    name="Install development tools (APT)",
    packages=dev_tools["apt"],
    _sudo=True,
)

# Replace with:
apt_fast.packages(
    name="Install development tools (APT)",
    packages=dev_tools["apt"],
    parallel=16,
    no_recommends=True,  # Optional: saves additional download time
    _sudo=True,
)
```

## Step 3: Batch package installations for further performance improvements

You can combine separate apt installations into larger batches to reduce overhead:

```python
# Combine multiple package categories
all_apt_packages = (
    dev_tools["apt"] + 
    build_tools["apt"] + 
    system_utilities["apt"]
)

# Install in one large batch
apt_fast.packages(
    name="Install combined package categories",
    packages=all_apt_packages,
    parallel=16,
    no_recommends=True,
    _sudo=True,
)
```

## Step 4: Ensure apt-fast is installed

In the setup_repositories function, make sure apt-fast is installed:

```python
# Add this to setup_repositories()
apt.ppa(name="Add apt-fast PPA", src="ppa:apt-fast/stable", _sudo=True)
apt.packages(
    name="Ensure apt-fast is installed",
    packages=["apt-fast"],
    _sudo=True,
)
```

## Testing

To test the integration, run specific functions in Docker:

```bash
uv run docker_test.py run packages.install_dev_tools
```

## Performance Considerations

- Start with a parallel value of 8-16, adjust based on system resources
- Use no_recommends=True where possible to reduce download size
- Combine related package installations into larger batches
- Consider the cache_time parameter to avoid redundant updates