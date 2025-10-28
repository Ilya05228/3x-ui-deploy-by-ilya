# 3x-ui-deploy-by-ilya

Настройка 3x-ui + vless с собственным доменом на VPS сервере

Нужно:
- Сервер
- Домен
## Переменные окружения
!! по сути менять нужно только ACME_EMAIL и DOMAIN

| Переменная                   | Описание |
|-------------------------------|----------|
| `ACME_EMAIL`                  | Email для сертификатов Let's Encrypt |
| `DOMAIN`                      | Основной домен для панели и сайта |
| `PANEL_PORT`                  | Внешний порт HTTPS для панели 3x-ui |
| `WEBSITE_PORT`                | Внешний порт HTTPS для сайта |
| `PANEL_PATH`                  | Путь к 3x-ui в URL (`/subscriptions/`) |
| `SUBSCRIPTIONS_PATH`          | Путь к подпискам в URL (`/subscriptions/`) |
| `SUBSCRIPTIONS_INTERNAL_PORT` | Внутренний порт сервиса подписок в 3x-ui |
| `PANEL_INTERNAL_PORT`         | Внутренний порт панели 3x-ui |

---

## Установка

### Подключение к серверу

Перед началом установки необходимо правильно настроить подключение к серверу по SSH ключам.

#### Генерация SSH ключей на Ubuntu 24
```bash
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub
````

#### Генерация SSH ключей на Windows 11

```cmd
ssh-keygen -t rsa -b 4096
type C:\Users\<YourUser>\.ssh\id_rsa.pub
```

---

### Установка и запуск 3x-ui

#### Проверка и установка Git

```bash
# Проверяем, установлен ли git
git --version || sudo apt update && sudo apt install -y git
```

#### Клонирование репозитория

```bash
cd /opt
git clone https://github.com/Ilya05228/3x-ui-deploy-by-ilya.git 3x-ui
cd 3x-ui
```


#### Настройка прав на скрипт установки и запуск

```bash
chmod +x ./install.sh
./install.sh
```
Заполните нужные переменные
**Теперь панель готова к использованию!**

### Изменение .env после первоначальной настройки

#### Подключитесь к серверу по SSH.

#### Перейдите в директорию с проектом:

```bash
cd /opt/3x-ui
```

#### Откройте файл `.env` для редактирования через nano:

```bash
nano .env
```
Внесите необходимые изменения и сохраните (Ctrl+O → Enter → Ctrl+X).

#### Перезапустите контейнеры Docker Compose, чтобы применить новые настройки:

```bash
docker compose down
docker compose up -d
```
**Теперь панель готова к использованию по https://DOMAIN:PANEL_PORT!**

## Список задач которые нужно реализовать
- Нам нужно оставить открытыми порты для SSH, 80(HTTP) и 443(HTTPS). Для этого нужно выполнить следующие команды:


## Что делать после установки
Не торгать порты, пути, URL-ы в настройках панели и подписок
### Настроить  vless
Target - traefik:9443

SNI - DOMAIN
### Изменить настройки XRAY
на ./configs/3x-ui_xray_best_config.json


## Полезные ссылки

- [Configure Xray with VLESS Reality](https://github.com/EmptyLibra/Configure-Xray-with-VLESS-Reality-on-VPS-server)
- [XTLS документация](https://xtls.github.io/en/)
- [3x-ui Configuration Wiki](https://github.com/MHSanaei/3x-ui/wiki/Configuration)
- [Netplan Configurator (изменение ip сервера)](https://github.com/openlicence/netplan_configurator.sh)
- [Hiddify App](https://github.com/hiddify/hiddify-app)
- [Xray-core Discussions #3518](https://github.com/XTLS/Xray-core/discussions/3518)
- [Xray VPS Setup in Docker](https://github.com/Akiyamov/xray-vps-setup/blob/main/install_in_docker.md)
- [Установка 3x-ui + Nginx](https://habr.com/ru/articles/902580/)
- [Статья по установке VPN](https://habr.com/ru/articles/799751/)
- [Статья по настройке VPN](https://habr.com/ru/articles/770400/)
- [Статья по Xray и Reality](https://habr.com/ru/articles/885276/)
- [SelfSNI Wiki](https://wiki.yukikras.net/ru/selfsni)