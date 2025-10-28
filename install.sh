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
function check_and_change_panel_port {
    read -p "Хотите изменить порт панели? (y/n): " change_port
    if [[ $change_port =~ ^[YyДд]$ ]]; then
        docker compose down
        apt install -y sqlite3
        read -p "Введите новый порт: " new_port
        sed -i "s/PANEL_PORT=[0-9]*/PANEL_PORT=$new_port/" ./.env
        sqlite3 ./db/x-ui.db "INSERT OR REPLACE INTO settings (key, value) VALUES ('webPort', '$new_port')"
        docker compose up -d
    fi
}
check_and_change_panel_port
echo "3x-ui успешно запущен!"