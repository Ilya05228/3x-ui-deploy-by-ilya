#!/bin/bash
set -x
set -e  
if [ "$EUID" -ne 0 ]; then
  echo "Запустите скрипт под sudo."
  exit 1
fi
apt update && apt upgrade -y

function is_docker_installed {
    command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

# Шаг 1: Установка Docker
if is_docker_installed; then
  echo "Docker уже установлен и работает, пропускаем установку."
else
  echo "Установка Docker..."

  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
  sudo apt-get update
  sudo apt-get install ca-certificates curl -y
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
fi
# Шаг 2: Установка 3xui
docker compose up -d
function update_panel_settings {
    # Загружаем переменные из .env
    if [ ! -f ./.env ]; then
        echo "Ошибка: файл .env не найден"
        exit 1
    fi
    source ./.env
    
    # Проверяем обязательные переменные
    if [ -z "$PANEL_INTERNAL_PORT" ]; then
        echo "Ошибка: переменная PANEL_INTERNAL_PORT не задана в .env"
        exit 1
    fi
    
    if [ -z "$SUBSCRIPTIONS_PATH" ]; then
        echo "Ошибка: переменная SUBSCRIPTIONS_PATH не задана в .env"
        exit 1
    fi
    
    if [ -z "$DOMAIN" ]; then
        echo "Ошибка: переменная DOMAIN не задана в .env"
        exit 1
    fi
    
    if [ -z "$PANEL_PORT" ]; then
        echo "Ошибка: переменная PANEL_PORT не задана в .env"
        exit 1
    fi
    
    # Формируем subURI
    subURI="https://${DOMAIN}:${PANEL_PORT}${SUBSCRIPTIONS_PATH}"
    
    # Обновляем настройки в базе данных
    docker compose down
    
    # Устанавливаем sqlite3 если не установлен
    if ! command -v sqlite3 &> /dev/null; then
        apt update && apt install -y sqlite3
    fi
    
    # Обновляем настройки в базе данных
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webPort', '$PANEL_INTERNAL_PORT')"
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '$SUBSCRIPTIONS_PATH')"
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subURI', '$subURI')"
    
    docker compose up -d
    
    echo "Настройки панели обновлены:"
    echo "webPort: $PANEL_INTERNAL_PORT"
    echo "subPath: $SUBSCRIPTIONS_PATH"
    echo "subURI: $subURI"
}

update_panel_settings
echo "3x-ui успешно запущен!"