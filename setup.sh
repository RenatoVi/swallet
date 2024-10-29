#!/bin/bash

check_git_installed() {
  if ! command -v git &> /dev/null; then
    echo "Git não está instalado. Por favor, instale o Git e tente novamente."
    exit 1
  fi
}

check_docker_installed() {
  if ! command -v docker &> /dev/null; then
    echo "Docker não está instalado. Por favor, instale o Docker e tente novamente."
    exit 1
  fi
}

load_env() {
  if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
  elif [ -f .env.build ]; then
    export $(grep -v '^#' .env.build | xargs)
  fi
}

merge_env_files() {
  if [ -f .env.example ]; then
    TEMP_ENV=$(mktemp)

    cat .env.example > $TEMP_ENV

    if [ -f .env.build ]; then
      while IFS= read -r line; do
        if [[ $line == *=* ]]; then
          var_name=$(echo "$line" | cut -d '=' -f 1)
          if ! grep -q "^$var_name=" $TEMP_ENV; then
            echo "$line" >> $TEMP_ENV
          fi
        fi
      done < .env.build
    fi

    mv $TEMP_ENV .env
  else
    echo ".env.example não encontrado, não foi possível mesclar."
  fi
}

check_git_installed
load_env

SERVICE_NAME="${SERVICE_NAME:-new-service}"
REPO_URL="${REPO_URL:-https://github.com/laravel/laravel.git}"
TEMP_DIR="laravel_temp"

if [ ! -d "app" ]; then
    echo -e "Clonando repositório..."
    git clone $REPO_URL $TEMP_DIR

    if [ $? -ne 0 ]; then
      echo "Erro ao clonar o repositório."
      exit 1
    fi

    rm -rf $TEMP_DIR/.github $TEMP_DIR/.git
    mv $TEMP_DIR/* $TEMP_DIR/.* . 2>/dev/null

    rm -rf $TEMP_DIR

    merge_env_files

    echo -e "Construindo containers..."

    docker-compose up -d --build

    chmod -R 777 storage

    echo -e "Instalando pacotes de desenvolvimento..."

    docker exec -t $SERVICE_NAME.app composer config --no-interaction allow-plugins.composer/installers true

    docker exec -t $SERVICE_NAME.app composer remove phpunit/phpunit --dev --no-interaction
    docker exec -t $SERVICE_NAME.app composer require pestphp/pest --dev --no-interaction --with-all-dependencies
    docker exec -t $SERVICE_NAME.app sh -c "no | /var/www/html/project/vendor/bin/pest --init"

    docker exec -t $SERVICE_NAME.app composer require laravel/pint --dev --no-interaction

    mv ./database.sqlite ./database/database.sqlite
    chmod 777 ./database/database.sqlite

    docker exec -t $SERVICE_NAME.app php artisan key:generate
    docker exec -t $SERVICE_NAME.app php artisan optimize
    docker exec -t $SERVICE_NAME.app php artisan migrate

    rm -rf .git
    rm .env.build

else

  echo -e "iniciando containers..."
  docker-compose up -d --build
  docker exec -t $SERVICE_NAME.app php artisan optimize
  docker exec -t $SERVICE_NAME.app php artisan migrate

fi

echo -e "Intalação concluída."
