#!/usr/bin/env bash
set -eo pipefail

# Build the Docker image if needed or if --build flag is present
if [[ ! "$(docker images -q workspace-test 2> /dev/null)" || "$1" == "--build" ]]; then
    echo "Building Docker image..."
    docker build -t workspace-test .
    
    if [[ "$1" == "--build" ]]; then
        shift
    fi
fi

# Default behavior: run the entire main.py
if [[ $# -eq 0 ]]; then
    echo "Running full workspace setup in Docker container..."
    docker run --rm workspace-test bash -c "pyinfra @local -y main.py"
    exit 0
fi

# Handle --help flag
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Usage: ./docker-test.sh [options] [module.function]"
    echo ""
    echo "Options:"
    echo "  --build             Force rebuild the Docker image"
    echo "  --list              List available modules"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./docker-test.sh                       Run full setup"
    echo "  ./docker-test.sh --list                List available modules"
    echo "  ./docker-test.sh env_setup.setup_fish  Run specific function"
    echo "  ./docker-test.sh env_setup             Run all functions in module (not implemented yet)"
    exit 0
fi

# List available modules
if [[ "$1" == "--list" ]]; then
    echo "Available modules:"
    docker run --rm workspace-test bash -c "ls -1 *.py | grep -v 'main\|test\|config' | sed 's/\.py$//'"
    exit 0
fi

# Run specific module.function
if [[ "$1" == *"."* ]]; then
    MODULE=$(echo "$1" | cut -d. -f1)
    FUNCTION=$(echo "$1" | cut -d. -f2)
    echo "Running $MODULE.$FUNCTION in Docker..."
    docker run --rm workspace-test bash -c "pyinfra @local -vy $MODULE.$FUNCTION"
    exit 0
fi

# Run all functions in a module (not implemented yet)
echo "Running all functions in module $1 is not implemented yet."
echo "Please specify a specific function using the format: $1.function_name"
exit 1