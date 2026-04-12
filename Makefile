# ═══════════════════════════════════════════════════════════════
# Docker Lab — Пульт управления
# ═══════════════════════════════════════════════════════════════
#
# Философия: "Не учим запоминать команды — учим понимать происходящее"
#
# Цвета:
#   YELLOW — инструкции и подсказки
#   GREEN  — выполняемые команды
#   без изменений — вывод команд
#
# ═══════════════════════════════════════════════════════════════

.PHONY: build status run run-more clean compose-up compose-down logs monitor help
.DEFAULT_GOAL := help

IMAGE_NAME  := docker-lab/orders-api
BACKEND_DIR := steps/step_1_build/description/backend
BASE_PORT   := 8081

COMPOSE_DIR    := steps/step_2_control/description
CONTAINER_2    := backend-orders-api
BACKEND_PORT_2 := 8081

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
## Этап 1: Сборка
## ═══════════════════════════════════════════════════════════════

build: ## Собрать Docker-образ бэкенда
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Где мы находимся:$(NC)"
	@echo ""
	@echo "$(YELLOW)   [Dockerfile] ---> $(GREEN)[ docker build ]$(YELLOW) ---> [Image] ---> [Container]$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -t $(IMAGE_NAME)$(NC)"
	@echo "$(YELLOW)      Тег (имя) образа. Формат: [namespace/]name[:tag]$(NC)"
	@echo "$(YELLOW)      docker-lab/  — условный namespace (не реестр!)$(NC)"
	@echo "$(YELLOW)      orders-api   — имя сервиса$(NC)"
	@echo "$(YELLOW)      без :tag     — автоматически добавится :latest$(NC)"
	@echo ""
	@echo "$(YELLOW)   $(BACKEND_DIR)$(NC)"
	@echo "$(YELLOW)      Контекст сборки: папка, которую Docker видит при сборке$(NC)"
	@echo "$(YELLOW)      Dockerfile должен лежать в этой папке$(NC)"
	@echo "$(YELLOW)      COPY копирует файлы именно из этой папки$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker build -t $(IMAGE_NAME) $(BACKEND_DIR))
	@docker build -t $(IMAGE_NAME) $(BACKEND_DIR)
	@echo ""
	@echo "$(YELLOW)Образ собран! Смотрим результат:$(NC)"
	@echo ""
	$(call run_cmd,docker images $(IMAGE_NAME))
	@docker images $(IMAGE_NAME)
	@echo ""
	@echo "$(YELLOW)Следующий шаг: make run$(NC)"

status: ## Показать образы и запущенные контейнеры
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Docker-образы:$(NC)"
	@echo ""
	@echo "$(YELLOW)  Колонки:$(NC)"
	@echo "$(YELLOW)   IMAGE         — имя образа (REPOSITORY:TAG)$(NC)"
	@echo "$(YELLOW)   ID            — уникальный идентификатор образа$(NC)"
	@echo "$(YELLOW)   DISK USAGE    — место на диске (с учётом разделяемых слоёв)$(NC)"
	@echo "$(YELLOW)   CONTENT SIZE  — размер содержимого самого образа$(NC)"
	@echo "$(YELLOW)   EXTRA         — дополнительная информация$(NC)"
	@echo ""
	$(call run_cmd,docker images)
	@docker images
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Запущенные контейнеры:$(NC)"
	@echo ""
	@echo "$(YELLOW)  Колонки:$(NC)"
	@echo "$(YELLOW)   CONTAINER ID  — уникальный идентификатор контейнера$(NC)"
	@echo "$(YELLOW)   IMAGE         — из какого образа запущен$(NC)"
	@echo "$(YELLOW)   COMMAND       — команда, с которой запустился контейнер$(NC)"
	@echo "$(YELLOW)   CREATED       — когда был запущен$(NC)"
	@echo "$(YELLOW)   STATUS        — текущий статус (Up / Exited ...)$(NC)"
	@echo "$(YELLOW)   PORTS         — проброс портов: 0.0.0.0:8081->8080/tcp$(NC)"
	@echo "$(YELLOW)                   хост:контейнер$(NC)"
	@echo "$(YELLOW)   NAMES         — имя контейнера$(NC)"
	@echo ""
	$(call run_cmd,docker ps)
	@docker ps
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Совет: docker ps -a — показать все контейнеры (включая остановленные)$(NC)"

run: ## Запустить контейнер на порту 8081
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Где мы находимся:$(NC)"
	@echo ""
	@echo "$(YELLOW)   [Dockerfile] ---> [Image] ---> $(GREEN)[ docker run ]$(YELLOW) ---> [Container]$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   --rm$(NC)"
	@echo "$(YELLOW)      Удалить контейнер автоматически после остановки$(NC)"
	@echo "$(YELLOW)      без --rm он остаётся в docker ps -a$(NC)"
	@echo ""
	@echo "$(YELLOW)   -p $(BASE_PORT):8080$(NC)"
	@echo "$(YELLOW)      Проброс порта: [хост]:[контейнер]$(NC)"
	@echo "$(YELLOW)      $(BASE_PORT) — порт на вашей машине (снаружи)$(NC)"
	@echo "$(YELLOW)      8080 — порт внутри контейнера (где слушает приложение)$(NC)"
	@echo ""
	@echo "$(YELLOW)   $(IMAGE_NAME):latest$(NC)"
	@echo "$(YELLOW)      Образ для запуска (собрали в make build)$(NC)"
	@echo "$(YELLOW)      :latest — тег, добавился автоматически$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Откройте в браузере: http://localhost:$(BASE_PORT)$(NC)"
	@echo "$(YELLOW)Остановить: Ctrl+C$(NC)"
	@echo ""
	$(call run_cmd,docker run --rm -p $(BASE_PORT):8080 $(IMAGE_NAME):latest)
	@docker run --rm -p $(BASE_PORT):8080 $(IMAGE_NAME):latest

run-more: ## Запустить ещё один контейнер (авто-выбор порта)
	@PORT=$(BASE_PORT); \
	while docker ps --format '{{.Ports}}' | grep -q "0.0.0.0:$$PORT->"; do \
		PORT=$$((PORT + 1)); \
	done; \
	CONTAINER_NAME=orders-api-$$PORT; \
	echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"; \
	echo "$(YELLOW)Свободный порт: $$PORT$(NC)"; \
	echo ""; \
	echo "$(YELLOW)Новые флаги по сравнению с make run:$(NC)"; \
	echo "$(YELLOW)   -d$(NC)"; \
	echo "$(YELLOW)      Запуск в фоновом режиме (detached)$(NC)"; \
	echo "$(YELLOW)      терминал освобождается сразу$(NC)"; \
	echo "$(YELLOW)      логи: docker logs $$CONTAINER_NAME$(NC)"; \
	echo ""; \
	echo "$(YELLOW)   --name $$CONTAINER_NAME$(NC)"; \
	echo "$(YELLOW)      Имя контейнера вместо случайного (loving_euler и т.п.)$(NC)"; \
	echo "$(YELLOW)      удобно для docker logs, docker stop$(NC)"; \
	echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"; \
	echo ""; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	echo "$(BOLD)$(GREEN)  ▶  docker run --rm -d -p $$PORT:8080 --name $$CONTAINER_NAME $(IMAGE_NAME):latest$(NC)"; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	docker run --rm -d -p $$PORT:8080 --name $$CONTAINER_NAME $(IMAGE_NAME):latest; \
	echo ""; \
	echo "$(YELLOW)Контейнер запущен: http://localhost:$$PORT$(NC)"; \
	echo ""; \
	echo "$(YELLOW)Все контейнеры из образа $(IMAGE_NAME):$(NC)"; \
	echo ""; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	echo "$(BOLD)$(GREEN)  ▶  docker ps --filter ancestor=$(IMAGE_NAME)$(NC)"; \
	echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
	docker ps --filter ancestor=$(IMAGE_NAME)

clean: ## Остановить контейнеры и удалить образ
	@echo "$(YELLOW)Останавливаем контейнеры образа $(IMAGE_NAME)...$(NC)"
	@CONTAINERS=$$(docker ps -q --filter ancestor=$(IMAGE_NAME)); \
	if [ -n "$$CONTAINERS" ]; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker stop $$CONTAINERS$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		docker stop $$CONTAINERS; \
		echo "$(YELLOW)Контейнеры остановлены$(NC)"; \
	else \
		echo "$(YELLOW)   Нет запущенных контейнеров$(NC)"; \
	fi
	@echo ""
	@echo "$(YELLOW)Удаляем образ $(IMAGE_NAME)...$(NC)"
	@if docker image inspect $(IMAGE_NAME) > /dev/null 2>&1; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker rmi $(IMAGE_NAME)$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		docker rmi $(IMAGE_NAME); \
		echo "$(YELLOW)Образ удалён$(NC)"; \
	else \
		echo "$(YELLOW)   Образ не найден — уже удалён$(NC)"; \
	fi

## ═══════════════════════════════════════════════════════════════
## Этап 2: Управление
## ═══════════════════════════════════════════════════════════════

compose-up: ## Поднять стек через docker compose
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Где мы находимся:$(NC)"
	@echo ""
	@echo "$(YELLOW)   [Dockerfile] ---> [Image] ---> $(GREEN)[ docker compose up ]$(YELLOW) ---> [Container]$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Запускаем ($(COMPOSE_DIR)/docker-compose.yml):$(NC)"
	@echo ""
	@cat $(COMPOSE_DIR)/docker-compose.yml | sed 's/^/   /'
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Порты:$(NC)"
	@echo "$(YELLOW)   $(BACKEND_PORT_2):8080  →  HOST:CONTAINER$(NC)"
	@echo "$(YELLOW)   $(BACKEND_PORT_2)   — порт на вашей машине (снаружи)$(NC)"
	@echo "$(YELLOW)   8080 — порт внутри контейнера (приложение слушает 8080)$(NC)"
	@echo ""
	@echo "$(YELLOW)Переменные окружения:$(NC)"
	@echo "$(YELLOW)   env_file: .env    — переменные из файла$(NC)"
	@echo "$(YELLOW)   environment:      — переменные прямо в docker-compose.yml$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -d        Detached: терминал освобождается, контейнер живёт фоном$(NC)"
	@echo "$(YELLOW)             без -d: Ctrl+C остановит контейнер$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Откройте в браузере: http://localhost:$(BACKEND_PORT_2)$(NC)"
	@echo ""
	$(call run_cmd,docker compose up -d)
	@cd $(COMPOSE_DIR) && docker compose up -d
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
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker compose down)
	@cd $(COMPOSE_DIR) && docker compose down

logs: ## Показать логи контейнера
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Логи контейнера $(CONTAINER_2):$(NC)"
	@echo ""
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   -f           следить за новыми записями в реальном времени$(NC)"
	@echo "$(YELLOW)                Ctrl+C — выйти$(NC)"
	@echo "$(YELLOW)   --tail N     показать последние N строк$(NC)"
	@echo "$(YELLOW)   --since 5m   логи за последние 5 минут$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker logs $(CONTAINER_2))
	@docker logs $(CONTAINER_2) 2>&1 || ( \
		echo ""; \
		echo "$(RED)Контейнер $(CONTAINER_2) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make compose-up$(NC)"; \
		exit 1 \
	)

monitor: ## Обследовать контейнер (inspect, exec, top, stats)
	@docker inspect $(CONTAINER_2) > /dev/null 2>&1 || ( \
		echo "$(RED)Контейнер $(CONTAINER_2) не найден$(NC)"; \
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
	$(call run_cmd,docker inspect $(CONTAINER_2))
	@docker inspect $(CONTAINER_2)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)2. Файлы внутри контейнера$(NC)"
	@echo "$(YELLOW)   WORKDIR в Dockerfile: /app$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker exec $(CONTAINER_2) ls /app)
	@docker exec $(CONTAINER_2) ls /app
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)3. Процессы внутри контейнера$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker top $(CONTAINER_2))
	@docker top $(CONTAINER_2)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)4. Потребление ресурсов$(NC)"
	@echo ""
	@echo "$(YELLOW)   --no-stream — показать снимок и выйти$(NC)"
	@echo "$(YELLOW)   без флага   — интерактивная таблица (Ctrl+C выход)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker stats --no-stream $(CONTAINER_2))
	@docker stats --no-stream $(CONTAINER_2)

## ═══════════════════════════════════════════════════════════════
## Справка
## ═══════════════════════════════════════════════════════════════

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Docker Lab — Пульт управления$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  $(YELLOW)%-12s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Типовой порядок работы:$(NC)"
	@echo "$(YELLOW)   Этап 1: Сборка$(NC)"
	@echo "$(YELLOW)   make build          Собрать образ из Dockerfile$(NC)"
	@echo "$(YELLOW)   make status         Убедиться, что образ появился$(NC)"
	@echo "$(YELLOW)   make run            Запустить контейнер (docker run)$(NC)"
	@echo "$(YELLOW)   make run-more       Запустить ещё один (на другом порту)$(NC)"
	@echo "$(YELLOW)   make clean          Убрать всё за собой$(NC)"
	@echo ""
	@echo "$(YELLOW)   Этап 2: Управление$(NC)"
	@echo "$(YELLOW)   make compose-up     Поднять стек через docker compose$(NC)"
	@echo "$(YELLOW)   make logs           Показать логи контейнера$(NC)"
	@echo "$(YELLOW)   make monitor        Обследовать контейнер$(NC)"
	@echo "$(YELLOW)   make compose-down   Остановить и удалить контейнеры$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Легенда:$(NC)"
	@echo "$(YELLOW)   этот текст                    — инструкции и подсказки$(NC)"
	@echo "$(GREEN)   ▶  docker run ...             — выполняемая команда$(NC)"
	@echo "   вывод команды без цвета       — результат выполнения команды"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
