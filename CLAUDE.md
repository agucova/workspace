# CLAUDE.md - Development Guide

## Build/Run Commands
- Setup environment: `uv run pyinfra @local main.py`
- Bootstrap (Ubuntu): `bash bootstrap.bash`
- Run specific tasks: `uv run pyinfra @local -v <module>.<function>`
- Test individual function: `echo 'from <module> import <function>; <function>()' | uv run -`
- Execute arbitrary Python: `echo '<python_code>' | uv run -`

## Linting and Type Checking
- Check types with pyright: `uv run pyright`
- Check a specific file: `uv run pyright <file.py>`
- Run ruff linter: `uv run ruff check .`
- Run ruff formatter: `uv run ruff format .`
- Fix auto-fixable issues: `uv run ruff check --fix .`
- Run complete checks: `uv run ruff check . && uv run ruff format --check . && uv run pyright`

## Recommended Workflow
1. Make changes to the codebase
2. Run formatter: `uv run ruff format .`
3. Run linter and fix issues: `uv run ruff check --fix .`
4. Run type checker: `uv run pyright`
5. Test the changes: `uv run pyinfra @local -v <module>.<function>`
6. Commit changes only after all checks pass

## Code Style Guidelines
- **Typing**: Use type hints throughout; prefer `|` for union types in Python 3.10+
- **Imports**: Group standard library first, then third-party, then local modules
- **Formatting**: Follow PEP 8 with line length of 100, enforced by ruff
- **Naming**: Use snake_case for functions/variables, PascalCase for classes
- **Path handling**: Use pathlib.Path for all filesystem operations
- **Error handling**: Prefer early returns over deeply nested conditionals
- **Configuration**: Use pydantic_settings for typed configuration
- **Platform checks**: Use config.is_linux() and config.is_macos() for OS-specific code
- **Documentation**: Docstrings for modules and functions explaining purpose

## Project Context
- This is a PyInfra v3 script for setting up development machines
- Supports both macOS and Ubuntu/Pop_OS! as targets
- Rewrite of older Ansible playbook (in `ansible/`) with better performance aimed at achieving better performance than Ansible, as well as adding macOS support
- PyInfra v3 documentation is available locally in `.claude/docs/pyinfra/`
- Be aware of differences between PyInfra v3 and v2 syntax, as you're likely to hallucinate constructs only present in PyInfra v2 by default

## Development Environment
- The local development environment is a fully set up Pop_OS! machine
- PyInfra operations are idempotent and will skip actions on an already-configured environment
- When making changes, assume the local machine represents the desired state by default
- Only diverge from the local machine configuration when explicitly needed
- Testing locally should be safe as operations will detect existing configurations and skip redundant actions
