# ═══════════════════════════════════════════════════════════════
# Этап 2: Управление — Самостоятельная работа
# ═══════════════════════════════════════════════════════════════
#
# Задача: создать docker-compose.yml для фронтенда и запустить
# контейнер. Провести мониторинг и обследование.
#
# Запускать из директории: steps/step_2_control/execution/
#
# Цвета:
#   YELLOW — инструкции и подсказки
#   GREEN  — выполняемые команды
#   RED    — ошибки
#   без изменений — вывод команд
#
# ═══════════════════════════════════════════════════════════════

.PHONY: compose-up compose-down logs monitor help
.DEFAULT_GOAL := help

CONTAINER_NAME := c-orders-frontend
COMPOSE_FILE   := docker-compose.yml
FRONTEND_PORT  := 3001

GREEN  := $(shell printf '\033[0;32m')
YELLOW := $(shell printf '\033[0;33m')
RED    := $(shell printf '\033[0;31m')
BOLD   := $(shell printf '\033[1m')
NC     := $(shell printf '\033[0m')

# Блок с выполняемой командой
define run_cmd
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
	@echo "$(BOLD)$(GREEN)  ▶  $(1)$(NC)"
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
endef

## ═══════════════════════════════════════════════════════════════
## Команды
## ═══════════════════════════════════════════════════════════════

compose-up: ## Запустить контейнер через docker compose
	@if [ ! -f "$(COMPOSE_FILE)" ]; then \
		echo "$(RED)Файл $(COMPOSE_FILE) не найден$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Создайте файл docker-compose.yml в этой директории.$(NC)"; \
		echo "$(YELLOW)Минимальная структура:$(NC)"; \
		echo ""; \
		echo "$(YELLOW)   services:$(NC)"; \
		echo "$(YELLOW)     orders-web:$(NC)"; \
		echo "$(YELLOW)       image: docker-lab/orders-frontend$(NC)"; \
		echo "$(YELLOW)       container_name: $(CONTAINER_NAME)$(NC)"; \
		echo "$(YELLOW)       build:$(NC)"; \
		echo "$(YELLOW)         context: ./frontend$(NC)"; \
		echo "$(YELLOW)       ports:$(NC)"; \
		echo "$(YELLOW)         - \"3001:3000\"$(NC)"; \
		echo "$(YELLOW)       env_file: \".env\"$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Где мы находимся:$(NC)"
	@echo ""
	@echo "$(YELLOW)   [Dockerfile] ---> [Image] ---> $(GREEN)[ docker compose up ]$(YELLOW) ---> [Container]$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Запускаем ($(COMPOSE_FILE)):$(NC)"
	@echo ""
	@cat $(COMPOSE_FILE) | sed 's/^/   /'
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Порты:$(NC)"
	@echo "$(YELLOW)   $(FRONTEND_PORT):3000  →  HOST:CONTAINER$(NC)"
	@echo "$(YELLOW)   $(FRONTEND_PORT) — порт на вашей машине (снаружи)$(NC)"
	@echo "$(YELLOW)   3000 — порт внутри контейнера (server.js слушает 3000)$(NC)"
	@echo ""
	@echo "$(YELLOW)Переменные окружения:$(NC)"
	@echo "$(YELLOW)   env_file: .env    — переменные из файла (BACKEND_HOST, ...)$(NC)"
	@echo "$(YELLOW)   environment:      — переменные прямо в docker-compose.yml$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -d        Detached: терминал освобождается, контейнер живёт фоном$(NC)"
	@echo "$(YELLOW)             без -d: Ctrl+C остановит контейнер$(NC)"
	@echo "$(YELLOW)   --build   Пересобрать образ перед запуском$(NC)"
	@echo "$(YELLOW)             нужно если изменился Dockerfile или код$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Откройте в браузере: http://localhost:$(FRONTEND_PORT)$(NC)"
	@echo ""
	$(call run_cmd,docker compose up -d --build)
	@docker compose up -d --build || ( \
		echo ""; \
		echo "$(RED)Запуск завершился с ошибкой$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Частые причины:$(NC)"; \
		echo "$(YELLOW)   Образ не собран       →  убедитесь, что выполнили make build на этапе 1$(NC)"; \
		echo "$(YELLOW)   Порт $(FRONTEND_PORT) занят       →  docker ps | grep $(FRONTEND_PORT)$(NC)"; \
		echo "$(YELLOW)   Ошибка в compose.yml  →  посмотрите на строку с ошибкой выше$(NC)"; \
		exit 1 \
	)
	@echo ""
	@echo "$(YELLOW)Запущенные контейнеры:$(NC)"
	@echo ""
	$(call run_cmd,docker ps)
	@docker ps

compose-down: ## Остановить и удалить контейнеры
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   без флагов  — остановить и удалить контейнеры$(NC)"
	@echo "$(YELLOW)   -v          — также удалить volumes$(NC)"
	@echo "$(YELLOW)   --rmi all   — также удалить образы$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker compose down)
	@docker compose down

logs: ## Показать логи контейнера
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Логи контейнера $(CONTAINER_NAME):$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -f           следить за новыми записями в реальном времени$(NC)"
	@echo "$(YELLOW)                Ctrl+C — выйти$(NC)"
	@echo "$(YELLOW)   --tail N     показать последние N строк$(NC)"
	@echo "$(YELLOW)   --since 5m   логи за последние 5 минут$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker logs $(CONTAINER_NAME))
	@docker logs $(CONTAINER_NAME) 2>&1 || ( \
		echo ""; \
		echo "$(RED)Контейнер $(CONTAINER_NAME) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)

monitor: ## Обследовать контейнер (inspect, exec, top, stats)
	@docker inspect $(CONTAINER_NAME) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(CONTAINER_NAME) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)1. Конфигурация контейнера$(NC)"
	@echo ""
	@echo "$(YELLOW)   Ищите в выводе:$(NC)"
	@echo "$(YELLOW)   \"Env\"    — переменные окружения контейнера$(NC)"
	@echo "$(YELLOW)   \"Cmd\"    — стартовая команда контейнера$(NC)"
	@echo "$(YELLOW)   \"Image\"  — образ, с которым запущен контейнер$(NC)"
	@echo "$(YELLOW)   \"Ports\"  — проброс портов$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker inspect $(CONTAINER_NAME))
	@docker inspect $(CONTAINER_NAME)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)2. Файлы внутри контейнера$(NC)"
	@echo "$(YELLOW)   WORKDIR в Dockerfile: /app$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker exec $(CONTAINER_NAME) ls /app)
	@docker exec $(CONTAINER_NAME) ls /app
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)3. Процессы внутри контейнера$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker top $(CONTAINER_NAME))
	@docker top $(CONTAINER_NAME)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)4. Потребление ресурсов$(NC)"
	@echo ""
	@echo "$(YELLOW)   --no-stream — показать снимок и выйти$(NC)"
	@echo "$(YELLOW)   без флага   — интерактивная таблица (Ctrl+C выход)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker stats --no-stream $(CONTAINER_NAME))
	@docker stats --no-stream $(CONTAINER_NAME)

## ═══════════════════════════════════════════════════════════════
## Справка
## ═══════════════════════════════════════════════════════════════

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Этап 2: Управление — Самостоятельная работа$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  $(YELLOW)%-14s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Порядок работы:$(NC)"
	@echo "$(YELLOW)   1. Создайте docker-compose.yml  (см. README.md)$(NC)"
	@echo "$(YELLOW)   2. make compose-up$(NC)"
	@echo "$(YELLOW)   3. make logs$(NC)"
	@echo "$(YELLOW)   4. make monitor$(NC)"
	@echo "$(YELLOW)   5. make compose-down$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Легенда:$(NC)"
	@echo "$(YELLOW)   этот текст                    — инструкции и подсказки$(NC)"
	@echo "$(GREEN)   ▶  docker compose up ...      — выполняемая команда$(NC)"
	@echo "   вывод команды без цвета       — результат выполнения команды"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
