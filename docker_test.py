#!/usr/bin/env python3
"""
docker_test.py

A Python-based Docker testing harness for the workspace setup scripts.
This script replaces the Bash-based docker-test.sh with a more robust implementation
using the Typer CLI framework.

Usage:
    python docker_test.py [OPTIONS] [MODULE_FUNCTION]
"""

import os
import subprocess
import sys
from typing import List, Optional

import typer
from rich.console import Console
from rich.panel import Panel

# Initialize Typer app and rich console
app = typer.Typer(help="Docker testing harness for workspace setup")
console = Console()


def run_command(
    command: str, check: bool = True, capture_output: bool = True
) -> subprocess.CompletedProcess | subprocess.CalledProcessError:
    """Run a shell command and return the result."""
    try:
        result = subprocess.run(
            command, shell=True, check=check, text=True, capture_output=capture_output
        )
        return result
    except subprocess.CalledProcessError as e:
        if check:
            console.print(f"[bold red]Error running command:[/] {command}")
            console.print(f"[red]{e.stderr if e.stderr else str(e)}[/]")
            sys.exit(1)
        return e


def check_docker_image_exists(image_name: str) -> bool:
    """Check if a Docker image exists locally."""
    result = run_command(f"docker images -q {image_name} 2>/dev/null", check=False)
    return bool(result.stdout.strip())


def build_docker_image(image_name: str) -> None:
    """Build the Docker image."""
    console.print("[bold blue]Building Docker image...[/]")
    run_command(f"docker build -t {image_name} .", capture_output=False)


def get_modules() -> List[str]:
    """Get a list of available Python modules in the current directory."""
    result = run_command(
        "ls -1 *.py | grep -v 'main\\|test\\|config' | sed 's/\\.py$//'"
    )
    return result.stdout.strip().split("\n")


def run_docker_container(
    image_name: str,
    command: str,
    interactive: bool = False,
    ssh_agent: bool = False,
    env_vars: Optional[dict] = None,
) -> None:
    """Run a Docker container with the specified command."""
    # Base docker run command
    docker_cmd = "docker run --rm"

    # Add interactive flag if needed
    if interactive:
        docker_cmd += " -it"

    # Add SSH agent forwarding if requested and available
    if ssh_agent and "SSH_AUTH_SOCK" in os.environ:
        ssh_sock = os.environ["SSH_AUTH_SOCK"]
        docker_cmd += (
            f" -v {ssh_sock}:/tmp/ssh_auth_sock -e SSH_AUTH_SOCK=/tmp/ssh_auth_sock"
        )

    # Add environment variables
    if env_vars:
        for key, value in env_vars.items():
            docker_cmd += f" -e {key}={value}"

    # Complete the command
    docker_cmd += f' {image_name} bash -c "{command}"'

    # Execute the command
    try:
        # Use subprocess.run directly to avoid capturing output
        subprocess.run(docker_cmd, shell=True, check=True)
    except subprocess.CalledProcessError:
        console.print("[bold red]Error running Docker container[/]")
        sys.exit(1)


@app.command()
def list_modules():
    """List available modules for testing."""
    console.print("[bold green]Available modules:[/]")

    image_name = "workspace-test"
    if not check_docker_image_exists(image_name):
        build_docker_image(image_name)

    # Get modules from the Docker image
    run_docker_container(
        image_name=image_name,
        command="ls -1 *.py | grep -v 'main\\|test\\|config' | sed 's/\\.py$//'",
        interactive=False,
    )


@app.command()
def run(
    module_function: Optional[str] = typer.Argument(
        None, help="Module.function to run (e.g., 'env_setup.setup_fish')"
    ),
    build: bool = typer.Option(
        False, "--build", "-b", help="Force rebuild the Docker image"
    ),
    interactive: bool = typer.Option(
        False,
        "--interactive",
        "-i",
        help="Launch interactive bash shell after running commands",
    ),
    include_dotfiles: bool = typer.Option(
        None,
        "--dotfiles/--no-dotfiles",
        help="Include dotfiles setup (default: yes for full setup, no for specific function)",
    ),
):
    """Run PyInfra modules in a Docker container."""
    image_name = "workspace-test"

    # Build image if needed or requested
    if build or not check_docker_image_exists(image_name):
        build_docker_image(image_name)

    # Determine if we should run dotfiles setup
    # Default: yes for full setup, no for specific function
    run_dotfiles = False
    if module_function is None:
        # Full setup - default to yes unless explicitly turned off
        run_dotfiles = False if include_dotfiles is False else True
    else:
        # Specific function - default to no unless explicitly turned on
        run_dotfiles = True if include_dotfiles is True else False

    # Check SSH agent if dotfiles will be included
    if run_dotfiles:
        ssh_agent_available = bool(os.environ.get("SSH_AUTH_SOCK"))
        if ssh_agent_available:
            console.print(
                "[bold green]SSH agent forwarding enabled.[/] Using your local SSH keys for GitHub authentication."
            )
        else:
            console.print(
                "[bold yellow]WARNING:[/] No SSH agent detected. You'll need to authenticate manually.\n"
                "Run 'ssh-add' before this script to add your SSH keys to the agent."
            )

    # Build the command to run
    if module_function:
        # Validate that we're only running specific module.function pairs
        if "." not in module_function:
            console.print(
                "[bold red]Error:[/] Please specify a module.function pair (e.g., 'env_setup.setup_fish').\n"
                "Running entire modules is not currently supported."
            )
            sys.exit(1)

        # Specific module.function
        console.print(f"[bold blue]Running {module_function} in Docker...[/]")
        command = f"pyinfra @local -vy {module_function}"
    else:
        # Full setup
        console.print(
            "[bold blue]Running full workspace setup in Docker container...[/]"
        )
        command = "pyinfra @local -y main.py"

    # Add dotfiles setup if needed
    if run_dotfiles:
        console.print("[bold blue]Including dotfiles setup...[/]")
        command += " && uv run dotfiles_setup.py"

    # Add bash shell if interactive
    if interactive:
        command += " && bash"

    # Run the container
    run_docker_container(
        image_name=image_name,
        command=command,
        interactive=interactive
        or run_dotfiles,  # Interactive mode required for dotfiles
        ssh_agent=run_dotfiles,
    )


if __name__ == "__main__":
    # Display a banner at the start
    console.print(
        Panel.fit(
            "[bold blue]Workspace Docker Testing Harness[/]",
            subtitle="[italic]Use --help for more information[/]",
        )
    )
    app()
