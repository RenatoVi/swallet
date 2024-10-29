#!/usr/bin/env bash

WHITE='\033[1;37m'
NC='\033[0m'

load_env() {
  [ -f .env ] && export $(grep -v '^#' .env | xargs)
}
load_env

# Verify operating system is supported...
case "$(uname -s)" in
    Linux*) MACHINE=linux ;;
    Darwin*) MACHINE=mac ;;
    *) echo "Unsupported operating system [$(uname -s)]. Laravel Sail supports macOS, Linux, and Windows (WSL2)." >&2; exit 1 ;;
esac

# Define environment variables...
export APP_SERVICE="${SERVICE_NAME}.app"
export SEDCMD="sed -i${MACHINE:0:1} .bak" # Use a single line to set SEDCMD based on OS

# Ensure that Docker is running...
if ! docker info > /dev/null 2>&1; then
    echo -e "${WHITE}Docker is not running.${NC}" >&2
    exit 1
fi

# Handle artisan commands
if [ "$1" == "go" ]; then
    shift 1
        docker exec -it "$APP_SERVICE" sh
elif [ "$1" == "pint" ]; then
    shift 1
        docker exec -it "$APP_SERVICE" \
        ./vendor/bin/pint
elif [ "$1" == "pest" ]; then
    shift 1
        docker exec -it "$APP_SERVICE" \
        ./vendor/bin/pest
else
    docker exec -it "$APP_SERVICE" "$@"
fi
