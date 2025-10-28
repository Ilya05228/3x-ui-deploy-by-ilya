# 3x-ui-deploy-by-ilya

## Переменные окружения

| Переменная                   | Описание |
|-------------------------------|----------|
| `ACME_EMAIL`                  | Email для сертификатов Let's Encrypt |
| `DOMAIN`                      | Основной домен для панели и сайта |
| `PANEL_PORT`                  | Внешний порт HTTPS для панели 3x-ui |
| `WEBSITE_PORT`                | Внешний порт HTTPS для сайта |
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

#### 1. Проверка и установка Git

```bash
# Проверяем, установлен ли git
git --version || sudo apt update && sudo apt install -y git
```

#### 2. Клонирование репозитория

```bash
cd /opt
git clone git@github.com:Ilya05228/3x-ui-deploy-by-ilya.git 3x-ui
cd 3x-ui
```

#### 3. Настройка переменных окружения

```bash
nano .env
```

Внесите необходимые изменения и сохраните (Ctrl+O → Enter → Ctrl+X).


#### 4. Настройка прав на скрипт установки и запуск

```bash
chmod +x ./install.sh
./install.sh
```
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
**Теперь панель готова к использованию!**
