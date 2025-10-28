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
function check_and_change_ports_and_paths {
    # Читаем значения из .env файла
    if [ -f ./.env ]; then
        source ./.env
        changes_made=false
        # Меняем порт панели если задан PANEL_INTERNAL_PORT
        if [ ! -z "$PANEL_INTERNAL_PORT" ]; then
            echo "Автоматическое изменение порта панели на $PANEL_INTERNAL_PORT"
            docker compose down
            apt install -y sqlite3
            # Обновляем PANEL_PORT в .env файле
            sed -i "s/PANEL_PORT=[0-9]*/PANEL_PORT=$PANEL_INTERNAL_PORT/" ./.env
            # Обновляем порт в базе данных
            sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webPort', '$PANEL_INTERNAL_PORT')"
            changes_made=true
            echo "Порт панели успешно изменен на $PANEL_INTERNAL_PORT"
        else
            echo "PANEL_INTERNAL_PORT не задан, порт панели не изменен"
        fi
        # Меняем путь подписок если задан SUBSCRIPTIONS_PATH
        if [ ! -z "$SUBSCRIPTIONS_PATH" ]; then
            echo "Автоматическое изменение пути подписок на $SUBSCRIPTIONS_PATH"
            # Обновляем subPath в базе данных
            sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '$SUBSCRIPTIONS_PATH')"
            changes_made=true
            echo "Путь подписок успешно изменен на $SUBSCRIPTIONS_PATH"
        else
            echo "SUBSCRIPTIONS_PATH не задан, путь подписок не изменен"
        fi
        # Перезапускаем контейнеры только если были изменения
        if [ "$changes_made" = true ]; then
            docker compose up -d
            echo "Все изменения применены, контейнеры перезапущены"
        else
            echo "Изменений не требуется"
        fi
        
    else
        echo "Ошибка: .env файл не найден"
    fi
}

check_and_change_ports_and_paths
echo "3x-ui успешно запущен!"