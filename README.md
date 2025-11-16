# Методические указания к лабораторной работе "Docker для системных аналитиков"

## Шаги выполнения

### Шаг 0. Подготовка

Настроить подключение к ВМ, см. https://github.com/AndreyChuyan/se_labs

### Шаг 1. Сборка Docker-образа

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
