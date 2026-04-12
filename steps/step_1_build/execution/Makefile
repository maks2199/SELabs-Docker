# ═══════════════════════════════════════════════════════════════
# Этап 1: Сборка — Самостоятельная работа
# ═══════════════════════════════════════════════════════════════
#
# Задача: написать Dockerfile для Node.js приложения в frontend/
# и собрать образ.
#
# Запускать из директории: steps/step_1_build/execution/
#
# Цвета:
#   YELLOW — инструкции и подсказки
#   GREEN  — выполняемые команды
#   RED    — ошибки
#   без изменений — вывод команд
#
# ═══════════════════════════════════════════════════════════════

.PHONY: build run clean help
.DEFAULT_GOAL := help

IMAGE_NAME   := docker-lab/orders-frontend
FRONTEND_DIR := frontend
PORT         := 3000

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

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Этап 1: Сборка — Самостоятельная работа$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / \
		{printf "  $(YELLOW)%-10s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Порядок работы:$(NC)"
	@echo "$(YELLOW)   1. Создайте $(FRONTEND_DIR)/Dockerfile  (см. README.md)$(NC)"
	@echo "$(YELLOW)   2. make build$(NC)"
	@echo "$(YELLOW)   3. make run$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

build: ## Собрать образ фронтенда
	@if [ ! -f "$(FRONTEND_DIR)/Dockerfile" ]; then \
		echo "$(RED)Dockerfile не найден: $(FRONTEND_DIR)/Dockerfile$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Создайте файл $(FRONTEND_DIR)/Dockerfile со следующей структурой:$(NC)"; \
		echo ""; \
		echo "$(YELLOW)   FROM node:18-slim         <- базовый образ с Node.js$(NC)"; \
		echo "$(YELLOW)   WORKDIR /app              <- рабочая директория внутри контейнера$(NC)"; \
		echo "$(YELLOW)   COPY package*.json .      <- копируем зависимости (до npm install!)$(NC)"; \
		echo "$(YELLOW)   RUN npm install           <- устанавливаем зависимости$(NC)"; \
		echo "$(YELLOW)   COPY . .                  <- копируем остальной код$(NC)"; \
		echo "$(YELLOW)   CMD [\"node\", \"server.js\"] <- команда запуска$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Зачем COPY package*.json отдельно от COPY . .?$(NC)"; \
		echo "$(YELLOW)   Docker кеширует слои. Если код изменился, но package.json нет —$(NC)"; \
		echo "$(YELLOW)   npm install не запустится заново. Сборка будет быстрее.$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Собираем образ: $(IMAGE_NAME)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call run_cmd,docker build -t $(IMAGE_NAME) $(FRONTEND_DIR))
	@docker build -t $(IMAGE_NAME) $(FRONTEND_DIR) || ( \
		echo ""; \
		echo "$(RED)Сборка завершилась с ошибкой$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Частые причины:$(NC)"; \
		echo "$(YELLOW)   COPY package*.json .  ->  package.json существует в $(FRONTEND_DIR)/?$(NC)"; \
		echo "$(YELLOW)   COPY . .              ->  запускайте make build из директории execution/$(NC)"; \
		echo "$(YELLOW)   RUN npm install       ->  проверьте синтаксис: нет лишних пробелов$(NC)"; \
		echo "$(YELLOW)   FROM node:18-slim     ->  опечатка в имени базового образа?$(NC)"; \
		echo "$(YELLOW)   CMD [\"node\",\"server.js\"]  ->  каждый аргумент в отдельных кавычках$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Посмотрите на строку с ошибкой выше (---> Running in ...)$(NC)"; \
		exit 1 \
	)
	@echo ""
	@echo "$(YELLOW)Образ собран!$(NC)"
	@echo ""
	$(call run_cmd,docker images $(IMAGE_NAME))
	@docker images $(IMAGE_NAME)
	@echo ""
	@echo "$(YELLOW)Следующий шаг: make run$(NC)"

run: ## Запустить контейнер на порту 3000
	@if ! docker image inspect $(IMAGE_NAME) > /dev/null 2>&1; then \
		echo "$(RED)Образ $(IMAGE_NAME) не найден$(NC)"; \
		echo "$(YELLOW)Сначала выполните: make build$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Флаги:$(NC)"
	@echo "$(YELLOW)   --rm          Удалить контейнер после остановки$(NC)"
	@echo "$(YELLOW)   -p $(PORT):$(PORT)      Проброс порта: [хост]:[контейнер]$(NC)"
	@echo "$(YELLOW)                 $(PORT) — порт на вашей машине$(NC)"
	@echo "$(YELLOW)                 $(PORT) — порт внутри контейнера (server.js слушает 3000)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Откройте в браузере: http://localhost:$(PORT)$(NC)"
	@echo "$(YELLOW)Остановить: Ctrl+C$(NC)"
	@echo ""
	$(call run_cmd,docker run --rm -p $(PORT):$(PORT) $(IMAGE_NAME):latest)
	@docker run --rm -p $(PORT):$(PORT) $(IMAGE_NAME):latest || ( \
		echo ""; \
		echo "$(RED)Контейнер завершился с ошибкой$(NC)"; \
		echo ""; \
		echo "$(YELLOW)Частые причины:$(NC)"; \
		echo "$(YELLOW)   Порт $(PORT) занят    ->  docker ps | grep $(PORT)$(NC)"; \
		echo "$(YELLOW)   Приложение упало  ->  посмотрите логи выше$(NC)"; \
		echo "$(YELLOW)   Неверная CMD      ->  ожидаемая команда: node server.js$(NC)"; \
		exit 1 \
	)

clean: ## Удалить образ фронтенда
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
