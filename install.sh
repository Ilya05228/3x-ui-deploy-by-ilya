#!/bin/bash
# set -x
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
function create_env_file {
    local env_example=".env.example"
    local env_file=".env"
    
    if [ -f "$env_file" ]; then
        read -p "Файл .env уже существует. Хотите перезаписать его? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            echo "Продолжаем с существующим .env файлом."
            return 0
        fi
    fi
    
    if [ ! -f "$env_example" ]; then
        echo "Ошибка: файл образца $env_example не найден"
        echo "Создайте файл .env.example с необходимыми переменными"
        exit 1
    fi
    
    echo "Создание .env файла из образца..."
    cp "$env_example" "$env_file"
    
    # Создаем временный файл для обработки
    local temp_file=$(mktemp)
    
    while IFS= read -r line; do
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            # Копируем комментарии и пустые строки как есть
            echo "$line" >> "$temp_file"
            continue
        fi
        
        var_name=$(echo "$line" | cut -d'=' -f1)
        current_value=$(echo "$line" | cut -d'=' -f2-)
        
        # Используем /dev/tty для прямого ввода от пользователя
        read -p "Хотите изменить значение для $var_name (текущее: $current_value)? (y/N): " change_var </dev/tty
        
        if [[ "$change_var" =~ ^[Yy]$ ]]; then
            read -p "Введите новое значение для $var_name: " new_value </dev/tty
            # Если новое значение не пустое, используем его, иначе оставляем старое
            if [ -n "$new_value" ]; then
                echo "$var_name=$new_value" >> "$temp_file"
            else
                echo "$line" >> "$temp_file"
            fi
        else
            echo "$line" >> "$temp_file"
        fi
    done < "$env_file"
    
    # Заменяем оригинальный файл временным
    mv "$temp_file" "$env_file"
    echo "Файл .env успешно создан!"
}
create_env_file
# Шаг 2: Установка 3xui
docker compose up -d
function update_panel_settings {
    if [ ! -f ./.env ]; then
        echo "Ошибка: файл .env не найден"
        exit 1
    fi
    source ./.env
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
    if [ -z "$PANEL_PATH" ]; then
        echo "Ошибка: переменная PANEL_PATH не задана в .env"
        exit 1
    fi
    subURI="https://${DOMAIN}:${PANEL_PORT}${SUBSCRIPTIONS_PATH}"
    docker compose down
    if ! command -v sqlite3 &> /dev/null; then
        apt update && apt install -y sqlite3
    fi
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webPort', '$PANEL_INTERNAL_PORT')"
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subPath', '$SUBSCRIPTIONS_PATH')"
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('subURI', '$subURI')"
    sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webBasePath', '$PANEL_PATH')"
    docker compose up -d
    panel_url="https://${DOMAIN}:${PANEL_PORT}${PANEL_PATH}"
    subscriptions_url="https://${DOMAIN}:${PANEL_PORT}${SUBSCRIPTIONS_PATH}"
    echo "Адрес панели: $panel_url"
    echo "Адрес подписок: $subscriptions_url"
}
update_panel_settings
echo "3x-ui успешно запущен!"