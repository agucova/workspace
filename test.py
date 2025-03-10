#!/usr/bin/env python3
"""
Test script for running individual modules through Docker.
"""

import argparse
import importlib
import inspect
import sys
from pathlib import Path
from types import ModuleType
from typing import Dict, List, Set

from pyinfra.api.deploy import deploy


def list_deployable_functions() -> Dict[str, List[str]]:
    """List all functions decorated with @deploy across all modules."""
    modules = ["env_setup", "gnome", "packages", "facts"]
    result = {}

    for module_name in modules:
        try:
            module = importlib.import_module(module_name)
            functions = []

            for name, obj in inspect.getmembers(module):
                if inspect.isfunction(obj) and hasattr(obj, "__decorated__"):
                    functions.append(name)

            if functions:
                result[module_name] = functions

        except ImportError:
            print(f"Warning: Could not import module {module_name}", file=sys.stderr)

    return result


def get_all_module_names() -> Set[str]:
    """Get all Python module names in the project directory."""
    root_dir = Path(__file__).parent
    return {
        p.stem
        for p in root_dir.glob("*.py")
        if p.is_file() and p.stem not in ("main", "test", "config")
    }


def run_function(module_name: str, function_name: str) -> None:
    """Run a specific function from a module."""
    try:
        module = importlib.import_module(module_name)
        func = getattr(module, function_name, None)

        if not func:
            print(f"Error: Function {function_name} not found in module {module_name}")
            sys.exit(1)

        if not hasattr(func, "__decorated__"):
            print(f"Error: Function {function_name} is not a deployable function")
            sys.exit(1)

        print(f"Running {module_name}.{function_name}()...")
        func()
        print(f"Completed {module_name}.{function_name}()")

    except ImportError:
        print(f"Error: Could not import module {module_name}")
        sys.exit(1)
    except Exception as e:
        print(f"Error running {module_name}.{function_name}(): {e}")
        sys.exit(1)


def run_all_functions(module_name: str) -> None:
    """Run all deployable functions from a module."""
    try:
        module = importlib.import_module(module_name)

        deployable_functions = []
        for name, obj in inspect.getmembers(module):
            if inspect.isfunction(obj) and hasattr(obj, "__decorated__"):
                deployable_functions.append(name)

        if not deployable_functions:
            print(f"No deployable functions found in module {module_name}")
            return

        for function_name in deployable_functions:
            print(f"Running {module_name}.{function_name}()...")
            func = getattr(module, function_name)
            func()
            print(f"Completed {module_name}.{function_name}()")

    except ImportError:
        print(f"Error: Could not import module {module_name}")
        sys.exit(1)
    except Exception as e:
        print(f"Error running functions from {module_name}: {e}")
        sys.exit(1)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Run individual deployment functions for testing"
    )
    parser.add_argument(
        "--list", action="store_true", help="List all available modules and functions"
    )
    parser.add_argument(
        "--module", type=str, help="Module name to run (e.g., 'env_setup')"
    )
    parser.add_argument(
        "--function", type=str, help="Function name to run (e.g., 'setup_fish')"
    )
    parser.add_argument(
        "--all", action="store_true", help="Run all functions in the specified module"
    )

    args = parser.parse_args()

    if args.list:
        deployable_functions = list_deployable_functions()
        print("Available modules and functions:")
        for module, functions in deployable_functions.items():
            print(f"  {module}:")
            for function in functions:
                print(f"    - {function}")
        return

    if args.module:
        if args.function:
            run_function(args.module, args.function)
        elif args.all:
            run_all_functions(args.module)
        else:
            print("Error: Either --function or --all must be specified with --module")
            sys.exit(1)
    else:
        print("Error: --module is required unless using --list")
        sys.exit(1)


if __name__ == "__main__":
    main()
