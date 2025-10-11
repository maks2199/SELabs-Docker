# Docker Lab

Лабораторная работа "Docker для системных аналитиков".

## Frontend

```Dockerfile
FROM node:18-slim

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

EXPOSE 3000
CMD ["node", "server.js"]
```

## Подключение к ВМ

### 1. Настроить VPN

1. Установка

OpenVPN Connect (рекомендуется): с сайта [openvpn.net](https://openvpn.net/client/) → Downloads → Windows → OpenVPN Connect.

2. Запуск

Откройте OpenVPN Connect → File → Import → From local file → выберите .ovpn.

3. Подключитесь

- Нажмите Connect → введите логин/пароль (если требуется).
- Разрешите доступ в брандмауэре Windows для OpenVPN (галочки и для Private, и для Public сетей).
