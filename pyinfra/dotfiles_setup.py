#!/usr/bin/env python3
"""
dotfiles_setup.py

Interactive script to set up GitHub authentication and apply dotfiles via chezmoi.
This script is meant to be run after the main PyInfra deployment completes.

Usage:
    python3 dotfiles_setup.py

The script will:
1. Check if GitHub CLI is installed
2. Check if 1Password CLI is set up (for secrets management)
3. Prompt the user to authenticate with GitHub and 1Password
4. Clone the private dotfiles repository
5. Apply the dotfiles using chezmoi
"""

import os
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
    # Check for GitHub CLI using PATH (works in any environment including NixOS)
    gh_result = run_command("which gh", check=False)
    if gh_result.returncode != 0:
        # Only check for Homebrew path as a fallback (for non-NixOS systems)
        gh_homebrew_path = "/home/linuxbrew/.linuxbrew/bin/gh"
        if not Path(gh_homebrew_path).exists():
            print("GitHub CLI (gh) is not installed.")
            print("Please install it using one of the following methods:")
            print("    brew install gh           # For Homebrew")
            print("    nix-shell -p gitAndTools.gh  # For NixOS/Nix")
            sys.exit(1)

    # Check for chezmoi using PATH (works in any environment including NixOS)
    chezmoi_result = run_command("which chezmoi", check=False)
    if chezmoi_result.returncode != 0:
        # Only check for Homebrew path as a fallback (for non-NixOS systems)
        chezmoi_homebrew_path = "/home/linuxbrew/.linuxbrew/bin/chezmoi"
        if not Path(chezmoi_homebrew_path).exists():
            print("chezmoi is not installed.")
            print("Please install it using one of the following methods:")
            print("    brew install chezmoi     # For Homebrew")
            print("    nix-shell -p chezmoi     # For NixOS/Nix")
            sys.exit(1)
        
    # Check for 1Password CLI
    op_result = run_command("which op", check=False)
    if op_result.returncode == 0:
        # Check if the user is logged in using whoami
        status_result = run_command("op whoami", check=False)
        if status_result.returncode != 0:
            print("\n===== 1Password Authentication =====")
            print("The 1Password CLI is installed but you don't appear to be logged in.")
            print("Your dotfiles may use 1Password for secrets management.")
            
            response = input("Do you want to log in to 1Password now? [Y/n]: ")
            if response.lower() not in ["n", "no"]:
                # Give instructions and time to set up
                print("\nSigning in with the 1Password desktop app...")
                print("If this is your first time, please make sure to:")
                print("1. Open the 1Password app")
                print("2. Navigate to Settings > Developer and enable 'Integrate with 1Password CLI'")
                
                app_ready = input("\nPress Enter when the 1Password app is ready, or type 'skip' to skip: ")
                if app_ready.lower() == 'skip':
                    print("Skipping 1Password login...")
                    return
                
                # Start by trying the app integration method
                print("Attempting to authenticate with 1Password...")
                
                # We need to use --raw to get just the session token without other output
                session_result = run_command("op signin --raw", check=False)
                
                if session_result.returncode == 0:
                    # Success - set the OP_SESSION environment variable for the rest of the script
                    os.environ["OP_SESSION"] = session_result.stdout.strip()
                    print("Successfully authenticated with 1Password!")
                else:
                    print("Authentication failed or was canceled. Some dotfiles features may not work.")
                    print("You can manually sign in later with 'op signin'.")


def get_gh_command():
    """Return the appropriate gh command path."""
    gh_result = run_command("which gh", check=False)
    if gh_result.returncode == 0:
        # Use gh from PATH (works for NixOS, standard Linux, macOS)
        return "gh"
    
    # Use Homebrew path as fallback
    gh_homebrew_path = "/home/linuxbrew/.linuxbrew/bin/gh"
    if Path(gh_homebrew_path).exists():
        return gh_homebrew_path
    
    # Should never reach here due to check_prerequisites
    return "gh"


def get_chezmoi_command():
    """Return the appropriate chezmoi command path."""
    chezmoi_result = run_command("which chezmoi", check=False)
    if chezmoi_result.returncode == 0:
        # Use chezmoi from PATH (works for NixOS, standard Linux, macOS)
        return "chezmoi"
    
    # Use Homebrew path as fallback
    chezmoi_homebrew_path = "/home/linuxbrew/.linuxbrew/bin/chezmoi"
    if Path(chezmoi_homebrew_path).exists():
        return chezmoi_homebrew_path
    
    # Should never reach here due to check_prerequisites
    return "chezmoi"

def github_authenticate():
    """Set up GitHub authentication using the gh CLI."""
    gh_cmd = get_gh_command()
    
    # Check if already authenticated
    auth_status = run_command(f"{gh_cmd} auth status", check=False)
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
        f"{gh_cmd} auth login --git-protocol ssh --web", capture_output=False
    )
    if auth_result.returncode == 0:
        print("GitHub authentication successful!")
        return True
    else:
        print("GitHub authentication failed.")
        sys.exit(1)


def setup_dotfiles(github_username=None):
    """Clone and apply dotfiles using chezmoi."""
    gh_cmd = get_gh_command()
    
    # Determine the user's GitHub username if not provided
    if not github_username:
        try:
            github_username = run_command(f"{gh_cmd} api user -q .login").stdout.strip()
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
        print("Pulling latest changes...")
        pull_result = run_command(
            f"cd {dotfiles_dir} && git pull",
            capture_output=False,
        )
        if pull_result.returncode != 0:
            print("Warning: Failed to pull latest changes. Using existing repository state.")
            response = input("Would you like to remove and re-clone the repository instead? [y/N]: ")
            if response.lower() in ["y", "yes"]:
                run_command(f"rm -rf {dotfiles_dir}")
                # Will now proceed to clone in the code below
            else:
                print("Continuing with existing repository state.")
        else:
            print("Repository updated successfully.")

    # Clone dotfiles repository if it doesn't exist
    if not dotfiles_dir.exists():
        print(f"\n===== Cloning dotfiles repository to {dotfiles_dir} =====")
        clone_result = run_command(
            f"{gh_cmd} repo clone {github_username}/dotfiles {dotfiles_dir}",
            capture_output=False,
        )
        if clone_result.returncode != 0:
            print("Failed to clone dotfiles repository.")
            sys.exit(1)

    # Check if chezmoi is already initialized
    chezmoi_cmd = get_chezmoi_command()
    if chezmoi_dir.exists():
        print("chezmoi directory already exists.")
        print("Updating dotfiles...")
        # Use 'chezmoi update' to pull the latest changes and apply them
        update_result = run_command(
            f"{chezmoi_cmd} update --no-tty",
            capture_output=False,
        )
        
        if update_result.returncode == 0:
            print("Dotfiles successfully updated!")
            return True
        else:
            print("Warning: Failed to update dotfiles.")
            response = input("Would you like to reinitialize your dotfiles completely? [y/N]: ")
            if response.lower() in ["y", "yes"]:
                # Remove existing chezmoi directory to allow re-initialization
                run_command(f"rm -rf {chezmoi_dir}")
            else:
                print("Skipping further dotfiles changes.")
                # Return False to indicate we didn't fully apply dotfiles (update failed)
                return False

    # Only proceed with initialization if the directory doesn't exist or was removed above
    if not chezmoi_dir.exists():
        print("\n===== Setting up dotfiles with chezmoi =====")

        # Initialize chezmoi with the local repository and apply
        init_result = run_command(
            f"{chezmoi_cmd} init --apply --no-tty {dotfiles_dir}",
            capture_output=False,
        )
        
        if init_result.returncode == 0:
            print("Dotfiles successfully applied!")
            return True
        else:
            print("Failed to initialize or apply dotfiles.")
            sys.exit(1)
            
    # If we got here, we've already returned True or exited
    # This ensures we don't try to reference init_result when it might not exist
    return True


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
