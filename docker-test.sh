#!/usr/bin/env bash
set -eo pipefail

# Check if we should rebuild the image
REBUILD=false
INTERACTIVE=false
ARGS=()

# Parse arguments
for arg in "$@"; do
    if [[ "$arg" == "--build" ]]; then
        REBUILD=true
    elif [[ "$arg" == "--interactive" || "$arg" == "-i" ]]; then
        INTERACTIVE=true
    else
        ARGS+=("$arg")
    fi
done

# Build the Docker image if needed or if --build flag is present
if [[ ! "$(docker images -q workspace-test 2> /dev/null)" || "$REBUILD" == "true" ]]; then
    echo "Building Docker image..."
    docker build -t workspace-test .
fi

# No arguments provided (after removing --build and --interactive if present)
if [[ ${#ARGS[@]} -eq 0 ]]; then
    echo "Running full workspace setup in Docker container..."
    if [[ "$INTERACTIVE" == "true" ]]; then
        docker run --rm -it workspace-test bash -c "pyinfra @local -y main.py && bash"
    else
        docker run --rm workspace-test bash -c "pyinfra @local -y main.py"
    fi
    exit 0
fi

# Handle --help flag
if [[ "${ARGS[0]}" == "--help" || "${ARGS[0]}" == "-h" ]]; then
    echo "Usage: ./docker-test.sh [options] [module.function]"
    echo ""
    echo "Options:"
    echo "  --build             Force rebuild the Docker image"
    echo "  --interactive, -i   Launch interactive bash shell after running commands"
    echo "  --list              List available modules"
    echo "  --help, -h          Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./docker-test.sh                       Run full setup"
    echo "  ./docker-test.sh --list                List available modules"
    echo "  ./docker-test.sh env_setup.setup_fish  Run specific function"
    echo "  ./docker-test.sh --build env_setup.setup_fish  Rebuild and run specific function"
    echo "  ./docker-test.sh -i packages.setup_rust  Run function and open interactive shell"
    exit 0
fi

# List available modules
if [[ "${ARGS[0]}" == "--list" ]]; then
    echo "Available modules:"
    docker run --rm workspace-test bash -c "ls -1 *.py | grep -v 'main\|test\|config' | sed 's/\.py$//'"
    exit 0
fi

# Run specific module.function or just module
if [[ "${ARGS[0]}" == *"."* ]]; then
    # Run specific function in module
    MODULE=$(echo "${ARGS[0]}" | cut -d. -f1)
    FUNCTION=$(echo "${ARGS[0]}" | cut -d. -f2)
    echo "Running $MODULE.$FUNCTION in Docker..."
    if [[ "$INTERACTIVE" == "true" ]]; then
        docker run --rm -it workspace-test bash -c "pyinfra @local -vy $MODULE.$FUNCTION && bash"
    else
        docker run --rm workspace-test bash -c "pyinfra @local -vy $MODULE.$FUNCTION"
    fi
    exit 0
else
    # Try to import and run all functions in the module
    MODULE="${ARGS[0]}"
    echo "Running all functions in module ${MODULE} in Docker..."
    if [[ "$INTERACTIVE" == "true" ]]; then
        docker run --rm -it workspace-test bash -c "pyinfra @local -vy $MODULE && bash"
    else
        docker run --rm workspace-test bash -c "pyinfra @local -vy $MODULE"
    fi
    exit 0
fi