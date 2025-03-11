#!/usr/bin/env python3
"""
dotfiles_setup.py

Interactive script to set up GitHub authentication and apply dotfiles via chezmoi.
This script is meant to be run after the main PyInfra deployment completes.

Usage:
    python3 dotfiles_setup.py

The script will:
1. Check if GitHub CLI is installed
2. Prompt the user to authenticate with GitHub
3. Clone the private dotfiles repository
4. Apply the dotfiles using chezmoi
"""

import subprocess
import sys
from pathlib import Path


def run_command(command, check=True, capture_output=True):
    """Run a command and return the CompletedProcess object."""
    try:
        result = subprocess.run(
            command, check=check, shell=True, text=True, capture_output=capture_output
        )
        return result
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {command}")
        print(f"Error message: {e}")
        if e.stderr:
            print(f"Error output: {e.stderr}")
        if check:
            sys.exit(1)
        return e


def check_prerequisites():
    """Check if required tools are installed."""
    # Check for GitHub CLI
    gh_result = run_command("which gh", check=False)
    if gh_result.returncode != 0:
        print("GitHub CLI (gh) is not installed.")
        print("Please run the main PyInfra deployment first or install it manually:")
        print("    brew install gh")
        sys.exit(1)

    # Check for chezmoi
    chezmoi_result = run_command("which chezmoi", check=False)
    if chezmoi_result.returncode != 0:
        print("chezmoi is not installed.")
        print("Please run the main PyInfra deployment first or install it manually:")
        print("    brew install chezmoi")
        sys.exit(1)


def github_authenticate():
    """Set up GitHub authentication using the gh CLI."""
    # Check if already authenticated
    auth_status = run_command("gh auth status", check=False)
    if auth_status.returncode == 0:
        print("GitHub CLI is already authenticated.")
        return True

    print("\n===== GitHub Authentication =====")
    print(
        "You need to authenticate with GitHub to access your private dotfiles repository."
    )
    print("This will open a browser to complete the authentication process.")

    # Prompt the user before proceeding with authentication
    response = input("Continue with GitHub authentication? [Y/n]: ")
    if response.lower() in ["n", "no"]:
        print("GitHub authentication skipped. Exiting...")
        sys.exit(0)

    # Run gh auth login with SSH as the preferred Git protocol
    auth_result = run_command(
        "gh auth login --git-protocol ssh --web", capture_output=False
    )
    if auth_result.returncode == 0:
        print("GitHub authentication successful!")
        return True
    else:
        print("GitHub authentication failed.")
        sys.exit(1)


def setup_dotfiles(github_username=None):
    """Clone and apply dotfiles using chezmoi."""
    # Determine the user's GitHub username if not provided
    if not github_username:
        try:
            github_username = run_command("gh api user -q .login").stdout.strip()
            print(f"Detected GitHub username: {github_username}")
        except Exception:
            github_username = input("Enter your GitHub username: ")

    # Setup paths
    home_dir = Path.home()
    repos_dir = home_dir / "repos"
    dotfiles_dir = repos_dir / "dotfiles"
    chezmoi_dir = home_dir / ".local" / "share" / "chezmoi"

    # Create repos directory if it doesn't exist
    if not repos_dir.exists():
        print(f"Creating repos directory at {repos_dir}")
        repos_dir.mkdir(parents=True, exist_ok=True)

    # Check if dotfiles repo already exists
    if dotfiles_dir.exists():
        print(f"Dotfiles repository already exists at {dotfiles_dir}")
        response = input("Do you want to remove and re-clone it? [y/N]: ")
        if response.lower() in ["y", "yes"]:
            run_command(f"rm -rf {dotfiles_dir}")
        else:
            print("Using existing dotfiles repository.")

    # Clone dotfiles repository if it doesn't exist
    if not dotfiles_dir.exists():
        print(f"\n===== Cloning dotfiles repository to {dotfiles_dir} =====")
        clone_result = run_command(
            f"gh repo clone {github_username}/dotfiles {dotfiles_dir}",
            capture_output=False,
        )
        if clone_result.returncode != 0:
            print("Failed to clone dotfiles repository.")
            sys.exit(1)

    # Check if chezmoi is already initialized
    if chezmoi_dir.exists():
        print("chezmoi directory already exists.")
        response = input("Do you want to reinitialize your dotfiles? [y/N]: ")
        if response.lower() in ["y", "yes"]:
            # Remove existing chezmoi directory to allow re-initialization
            run_command(f"rm -rf {chezmoi_dir}")
        else:
            print("Skipping chezmoi initialization.")
            # Return False to indicate we didn't apply dotfiles (clean skip)
            return False

    print("\n===== Setting up dotfiles with chezmoi =====")

    # Initialize chezmoi with the local repository and apply
    init_result = run_command(
        f"chezmoi init --apply {dotfiles_dir}",
        capture_output=False,
    )

    if init_result.returncode == 0:
        print("Dotfiles successfully applied!")
        return True
    else:
        print("Failed to initialize or apply dotfiles.")
        sys.exit(1)


def main():
    """Main function to run the script."""
    print("===== Dotfiles Setup Script =====")
    print("This script will set up GitHub authentication and apply your dotfiles.")

    check_prerequisites()
    github_authenticate()

    # Call setup_dotfiles and track whether changes were applied
    dotfiles_applied = setup_dotfiles()

    print("\n===== Setup Complete! =====")
    if dotfiles_applied:
        print("Your dotfiles have been applied successfully.")
        print("You may need to restart your shell for all changes to take effect.")
    else:
        print("No changes were made to your dotfiles setup.")


if __name__ == "__main__":
    main()
