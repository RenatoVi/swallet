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
docker_exec_args="-t $APP_SERVICE php artisan"
if [ "$1" == "m" ]; then
    shift
    docker exec -u 1000:1000 $docker_exec_args make:"$@"
else
    docker exec -u 1000:1000 $docker_exec_args "$@"
fi
