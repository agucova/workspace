# Simplified Module Structure

After migrating from Snowfall Lib to flake-parts, further simplifications have been made to the module structure to reduce unnecessary nesting and boilerplate.

## Changes Made

1. **Removed Redundant Enable Options**: 
   - Most home modules now apply unconditionally when imported, eliminating the need for `enable = true` flags
   - Base system modules like `myBase` and `myDesktop` are auto-applied when imported
   - This simplifies system configuration and makes the import structure more explicit

2. **Explicit Module Imports**:
   - All modules are explicitly imported in flake.nix, making the dependency tree clear
   - System configurations don't need to enable modules that are universally required

3. **Maintained Configurable Features**:
   - Modules with meaningful configuration options (like `myMacosRemap`) retain their enable flags
   - The 1Password module uses a nested config structure (`onePassword.enableSSH` and `onePassword.enableGit`)
   - Hardware-specific configuration remains toggle-able due to its opt-in nature

## Benefits

This simplified structure offers several advantages:

1. **Improved Readability**: Fewer boilerplate enable flags means clearer configuration
2. **Reduced Redundancy**: No more importing a module *and* enabling it separately
3. **Better Defaults**: Modules provide sensible defaults without requiring explicit enablement
4. **Direct Configuration**: Features can be toggled without multiple levels of indirection

## Example: Before and After

Before:
```nix
# Import the module
imports = [ ../modules/home/core-shell ];
# Enable it separately
myCoreShell.enable = true;
```

After:
```nix
# Module is automatically applied when imported
imports = [ ../modules/home/core-shell ];
```

## Configurable Modules

Some modules still maintain configuration options:

1. **onePassword**: For SSH and Git integration control
   ```nix
   onePassword = {
     enableSSH = true;
     enableGit = true;
   };
   ```

2. **myMacosRemap**: For macOS-style keyboard remapping
   ```nix
   myMacosRemap.enable = true;
   ```

3. **myHardware**: For CPU and GPU-specific optimizations
   ```nix
   myHardware = {
     enable = true;
     cpu.amd.enable = true;
     gpu.nvidia.enable = true;
   };
   ```