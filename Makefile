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

.PHONY: build status run run-more clean compose-up compose-down logs monitor example-no-mount example-mount example-volume example-down net-no-network net-ports net-network net-down break-stage1 fix-stage1 break-stage2 fix-stage2 break-stage3 fix-stage3 break-stage4 fix-stage4 chaos-list help
.DEFAULT_GOAL := help

IMAGE_NAME  := docker-lab/orders-api
BACKEND_DIR := steps/step_1_build/description/backend
BASE_PORT   := 8081

COMPOSE_DIR    := steps/step_2_control/description
CONTAINER_2    := backend-orders-api
BACKEND_PORT_2 := 8081

EXAMPLE_MOUNT_DIR  := examples/mount
EXAMPLE_MOUNT_PORT := 3001
EXAMPLE_MOUNT_CONT := mount-example

NET_DIR        := steps/step_4_network/description
NET_FRONT_PORT := 3001
NET_BACK_CONT  := backend-orders-api
NET_FRONT_CONT := frontend-orders
NET_NAME       := orders-net

CHAOS_DIR          := chaos
CHAOS_STAGE1_IMG   := docker-lab/orders-api-broken:latest
CHAOS_STAGE1_CONT  := chaos-stage1
CHAOS_MOUNT_SRC    := steps/step_3_mount/description/mount
CHAOS_NET_BACKEND  := steps/step_4_network/description/backend
CHAOS_NET_FRONTEND := steps/step_4_network/description/frontend

GREEN   := $(shell printf '\033[0;32m')
YELLOW  := $(shell printf '\033[0;33m')
RED     := $(shell printf '\033[0;31m')
MAGENTA := $(shell printf '\033[0;35m')
BOLD    := $(shell printf '\033[1m')
NC      := $(shell printf '\033[0m')

# Блок с выполняемой командой
define run_cmd
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
	@echo "$(BOLD)$(GREEN)  ▶  $(1)$(NC)"
	@echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"
endef

# Проверка занятости порта перед запуском
# Использование: $(call check_port,3001)
define check_port
	@if docker ps --format '{{.Ports}}' | grep -q ':$(1)->'; then \
		echo "$(RED)════════════════════════════════════════════════════════$(NC)"; \
		echo "$(RED)Порт $(1) уже занят!$(NC)"; \
		echo "$(RED)════════════════════════════════════════════════════════$(NC)"; \
		echo "$(YELLOW)Контейнер, занимающий порт:$(NC)"; \
		docker ps --format "  {{.Names}}\t{{.Ports}}" | grep ':$(1)->'; \
		echo ""; \
		echo "$(YELLOW)Причина: предыдущий пример не был остановлен.$(NC)"; \
		echo "$(YELLOW)Решение — остановите запущенный пример:$(NC)"; \
		echo "$(YELLOW)   make net-down        — если запущен пример с сетями$(NC)"; \
		echo "$(YELLOW)   make example-down    — если запущен пример с маунтом$(NC)"; \
		echo "$(YELLOW)   make compose-down    — если запущен стек этапа 2$(NC)"; \
		exit 1; \
	fi
endef

# Проверка отсутствия контейнеров этапа 4 перед запуском нового шага
# Срабатывает если контейнер существует — запущен ИЛИ остановлен
define check_net_containers
	@for name in $(NET_BACK_CONT) $(NET_FRONT_CONT); do \
		if docker ps -a --format '{{.Names}}' | grep -qx "$$name"; then \
			echo "$(RED)════════════════════════════════════════════════════════$(NC)"; \
			echo "$(RED)Ошибка: контейнер \"$$name\" уже существует$(NC)"; \
			echo "$(RED)════════════════════════════════════════════════════════$(NC)"; \
			echo ""; \
			echo "$(YELLOW)Что произошло:$(NC)"; \
			echo "$(YELLOW)  Docker не может создать контейнер с именем \"$$name\",$(NC)"; \
			echo "$(YELLOW)  потому что контейнер с таким именем уже есть — даже$(NC)"; \
			echo "$(YELLOW)  если он остановлен. Имена контейнеров уникальны.$(NC)"; \
			echo ""; \
			echo "$(YELLOW)Причина: предыдущий шаг не был остановлен через make.$(NC)"; \
			echo ""; \
			echo "$(YELLOW)Решение — остановите и удалите старые контейнеры:$(NC)"; \
			echo "$(GREEN)   make net-down$(NC)"; \
			echo "$(YELLOW)затем повторите текущую команду.$(NC)"; \
			echo ""; \
			exit 1; \
		fi; \
	done
endef

# Сброс любых ранее запущенных демо-стендов и chaos-сценариев
define chaos_cleanup
	@echo "$(YELLOW)Сброс предыдущих демо-стендов...$(NC)"
	@docker rm -f $(CHAOS_STAGE1_CONT) 2>/dev/null || true
	@cd $(COMPOSE_DIR) && docker compose down 2>/dev/null || true
	@for f in docker-compose.no-mount.yml docker-compose.mount.yml docker-compose.volume.yml; do \
	  (cd $(EXAMPLE_MOUNT_DIR) && docker compose -f $$f down 2>/dev/null) || true; \
	done
	@for f in docker-compose.no-network.yml docker-compose.ports.yml docker-compose.network.yml; do \
	  (cd $(NET_DIR) && docker compose -f $$f down 2>/dev/null) || true; \
	done
	@for n in 1 2 3 4; do \
	  if [ -f $(CURDIR)/$(CHAOS_DIR)/stage$$n/docker-compose.broken.yml ]; then \
	    (cd $(CURDIR)/$(CHAOS_DIR)/stage$$n && docker compose -f docker-compose.broken.yml down 2>/dev/null) || true; \
	  fi; \
	done
	@echo ""
endef

# Универсальный чеклист диагностики — печатается одинаково во всех break-сценариях
define chaos_checklist
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BOLD)$(YELLOW)Чеклист диагностики — проходим по порядку$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)1. Статус контейнера     →  docker ps -a$(NC)"
	@echo "$(YELLOW)      Up / Exited / Restarting / Created?$(NC)"
	@echo "$(YELLOW)      Какой exit code?$(NC)"
	@echo ""
	@echo "$(YELLOW)2. Логи приложения       →  docker logs <container>$(NC)"
	@echo "$(YELLOW)      Что говорит сам процесс внутри?$(NC)"
	@echo "$(YELLOW)      Есть ли стек-трейс, ошибка подключения, 'file not found'?$(NC)"
	@echo ""
	@echo "$(YELLOW)3. Конфигурация запуска  →  docker inspect <container>$(NC)"
	@echo "$(YELLOW)      Секции: Env, Cmd, Entrypoint, Mounts, NetworkSettings$(NC)"
	@echo "$(YELLOW)      С чем именно запустился контейнер?$(NC)"
	@echo ""
	@echo "$(YELLOW)4. Вид изнутри           →  docker exec <container> sh -c '...'$(NC)"
	@echo "$(YELLOW)      ls /app, printenv, curl localhost:8080$(NC)"
	@echo "$(YELLOW)      Совпадает ли файловая система / переменные с ожиданием?$(NC)"
	@echo ""
	@echo "$(YELLOW)5. Сравнить с ожиданием$(NC)"
	@echo "$(YELLOW)      Конфиг ↔ код приложения ↔ docker-compose.yml$(NC)"
	@echo "$(YELLOW)      Где расхождение?$(NC)"
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
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
## Этап 3: Монтирование
## ═══════════════════════════════════════════════════════════════

example-no-mount: ## Пример без маунта — данные пропадают при перезапуске
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 1 из 3: контейнер БЕЗ маунта$(NC)"
	@echo ""
	@echo "$(YELLOW)Данные хранятся внутри контейнера. При перезапуске —$(NC)"
	@echo "$(YELLOW)файловая система сбрасывается до образа. Данные стираются.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(YELLOW)   version: \"3.8\"$(NC)"
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     app:$(NC)"
	@echo "$(YELLOW)       image: mount-example:latest$(NC)"
	@echo "$(YELLOW)       container_name: mount-example$(NC)"
	@echo "$(YELLOW)       build: .$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(YELLOW)       # нет секции volumes$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать несколько файлов через интерфейс$(NC)"
	@echo "$(YELLOW)   3. Выполнить: make example-down$(NC)"
	@echo "$(YELLOW)   4. Снова выполнить: make example-no-mount$(NC)"
	@echo "$(YELLOW)   5. Убедиться, что файлы исчезли$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_port,$(EXAMPLE_MOUNT_PORT))
	$(call run_cmd,docker compose -f docker-compose.no-mount.yml up -d --build)
	@cd $(EXAMPLE_MOUNT_DIR) && docker compose -f docker-compose.no-mount.yml up -d --build
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнер запущен: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать несколько файлов через интерфейс$(NC)"
	@echo "$(YELLOW)   3. Выполнить: make example-down$(NC)"
	@echo "$(YELLOW)   4. Снова выполнить: make example-no-mount$(NC)"
	@echo "$(YELLOW)   5. Убедиться, что файлы исчезли$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

example-mount: ## Пример с bind mount — ./data на хосте ↔ /app/data в контейнере
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 2 из 3: контейнер с bind mount$(NC)"
	@echo ""
	@echo "$(YELLOW)Bind mount — директория хоста монтируется прямо в контейнер.$(NC)"
	@echo "$(YELLOW)Изменения на хосте мгновенно видны в контейнере и наоборот.$(NC)"
	@echo "$(YELLOW)При перезапуске данные сохраняются — они на хосте.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(YELLOW)   version: \"3.8\"$(NC)"
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     app:$(NC)"
	@echo "$(YELLOW)       image: mount-example:latest$(NC)"
	@echo "$(YELLOW)       container_name: mount-example$(NC)"
	@echo "$(YELLOW)       build: .$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(MAGENTA)       volumes:                   # ◄ добавлено$(NC)"
	@echo "$(MAGENTA)         - ./data:/app/data       # ◄ добавлено: хост:контейнер$(NC)"
	@echo ""
	@echo "$(YELLOW)   ./data   — папка рядом с docker-compose.yml (на хосте)$(NC)"
	@echo "$(YELLOW)   /app/data — путь внутри контейнера$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать файл через браузер$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что файл появился на хосте: ls $(EXAMPLE_MOUNT_DIR)/data/$(NC)"
	@echo "$(YELLOW)   4. Создать файл на хосте: sudo touch $(EXAMPLE_MOUNT_DIR)/data/from-host.txt$(NC)"
	@echo "$(YELLOW)   5. Убедиться, что файл виден в браузере (Refresh List)$(NC)"
	@echo "$(YELLOW)   6. Перезапустить: make example-down  →  make example-mount$(NC)"
	@echo "$(YELLOW)   7. Убедиться, что файлы сохранились$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_port,$(EXAMPLE_MOUNT_PORT))
	$(call run_cmd,docker compose -f docker-compose.mount.yml up -d --build)
	@cd $(EXAMPLE_MOUNT_DIR) && docker compose -f docker-compose.mount.yml up -d --build
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнер запущен: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать файл через браузер$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что файл появился на хосте: ls $(EXAMPLE_MOUNT_DIR)/data/$(NC)"
	@echo "$(YELLOW)   4. Создать файл на хосте: sudo touch $(EXAMPLE_MOUNT_DIR)/data/from-host.txt$(NC)"
	@echo "$(YELLOW)   5. Убедиться, что файл виден в браузере (Refresh List)$(NC)"
	@echo "$(YELLOW)   6. Перезапустить: make example-down  →  make example-mount$(NC)"
	@echo "$(YELLOW)   7. Убедиться, что файлы сохранились$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

example-volume: ## Пример с volume — данные управляются Docker
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 3 из 3: контейнер с volume$(NC)"
	@echo ""
	@echo "$(YELLOW)Volume — Docker сам создаёт и управляет хранилищем.$(NC)"
	@echo "$(YELLOW)Расположение на хосте: /var/lib/docker/volumes/<name>/_data$(NC)"
	@echo "$(YELLOW)Удобно для БД — данные изолированы и управляются через Docker.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(YELLOW)   version: \"3.8\"$(NC)"
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     app:$(NC)"
	@echo "$(YELLOW)       image: mount-example:latest$(NC)"
	@echo "$(YELLOW)       container_name: mount-example$(NC)"
	@echo "$(YELLOW)       build: .$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(YELLOW)       volumes:$(NC)"
	@echo "$(MAGENTA)         - my-volume:/app/data    # ◄ изменено: имя вместо пути$(NC)"
	@echo "$(MAGENTA)                                  # ◄ (было: - ./data:/app/data)$(NC)"
	@echo "$(MAGENTA)   volumes:                       # ◄ добавлено: объявление volume$(NC)"
	@echo "$(MAGENTA)     my-volume:                   # ◄ добавлено$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать несколько файлов$(NC)"
	@echo "$(YELLOW)   3. Найти volume в системе:$(NC)"
	@echo "$(YELLOW)      docker volume ls$(NC)"
	@echo "$(YELLOW)      docker inspect $(EXAMPLE_MOUNT_CONT)$(NC)"
	@echo "$(YELLOW)      sudo ls /var/lib/docker/volumes/$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_port,$(EXAMPLE_MOUNT_PORT))
	$(call run_cmd,docker compose -f docker-compose.volume.yml up -d --build)
	@cd $(EXAMPLE_MOUNT_DIR) && docker compose -f docker-compose.volume.yml up -d --build
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Где Docker хранит volume:$(NC)"
	@echo ""
	$(call run_cmd,docker volume ls)
	@docker volume ls
	@echo ""
	$(call run_cmd,docker inspect $(EXAMPLE_MOUNT_CONT) --format '{{json .Mounts}}')
	@docker inspect $(EXAMPLE_MOUNT_CONT) --format '{{json .Mounts}}' 2>/dev/null | python3 -m json.tool 2>/dev/null || docker inspect $(EXAMPLE_MOUNT_CONT) --format '{{json .Mounts}}'
	@echo ""
	@echo "$(YELLOW)Поле \"Source\" — путь к volume на хосте$(NC)"
	@echo "$(YELLOW)Поле \"Destination\" — путь внутри контейнера$(NC)"
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнер запущен: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть в браузере: http://<IP_вашей_ВМ>:$(EXAMPLE_MOUNT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Создать несколько файлов$(NC)"
	@echo "$(YELLOW)   3. Найти volume в системе:$(NC)"
	@echo "$(YELLOW)      docker volume ls$(NC)"
	@echo "$(YELLOW)      docker inspect $(EXAMPLE_MOUNT_CONT)$(NC)"
	@echo "$(YELLOW)      sudo ls /var/lib/docker/volumes/$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

example-down: ## Остановить пример монтирования
	@echo "$(YELLOW)Останавливаем пример монтирования...$(NC)"
	@echo ""
	@MOUNT_DIR=$(CURDIR)/$(EXAMPLE_MOUNT_DIR); \
	ACTIVE=""; \
	for f in docker-compose.no-mount.yml docker-compose.mount.yml docker-compose.volume.yml; do \
		if docker compose -f $$MOUNT_DIR/$$f ps -q 2>/dev/null | grep -q .; then \
			ACTIVE=$$f; \
			break; \
		fi; \
	done; \
	if [ -n "$$ACTIVE" ]; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker compose -f $$ACTIVE down$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		cd $$MOUNT_DIR && docker compose -f $$ACTIVE down; \
	elif docker ps -q --filter name=$(EXAMPLE_MOUNT_CONT) | grep -q .; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker stop $(EXAMPLE_MOUNT_CONT)$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		docker stop $(EXAMPLE_MOUNT_CONT); \
	else \
		echo "$(YELLOW)   Контейнер $(EXAMPLE_MOUNT_CONT) не запущен$(NC)"; \
	fi

## ═══════════════════════════════════════════════════════════════
## Этап 4: Сети
## ═══════════════════════════════════════════════════════════════

net-no-network: ## Сети: фронт и бэк без общей сети — бэкенд недоступен
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 1 из 3: контейнеры без сети$(NC)"
	@echo ""
	@echo "$(YELLOW)Фронтенд пытается достучаться до бэкенда через хост$(NC)"
	@echo "$(YELLOW)(host.docker.internal → IP хоста). Но порт бэкенда$(NC)"
	@echo "$(YELLOW)не опубликован — запрос уходит в никуда.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     orders-api:$(NC)"
	@echo "$(YELLOW)       image: docker-lab/orders-api:latest$(NC)"
	@echo "$(YELLOW)       container_name: backend-orders-api$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: backend$(NC)"
	@echo "$(YELLOW)       env_file: \".env\"$(NC)"
	@echo "$(YELLOW)       # нет ports — бэкенд не доступен снаружи$(NC)"
	@echo ""
	@echo "$(YELLOW)     orders-web:$(NC)"
	@echo "$(YELLOW)       image: orders-frontend$(NC)"
	@echo "$(YELLOW)       container_name: frontend-orders$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: frontend$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(YELLOW)       environment:$(NC)"
	@echo "$(YELLOW)         BACKEND_HOST: host.docker.internal$(NC)"
	@echo "$(YELLOW)         BACKEND_PORT: \"8081\"$(NC)"
	@echo "$(YELLOW)       extra_hosts:$(NC)"
	@echo "$(YELLOW)         - \"host.docker.internal:host-gateway\"$(NC)"
	@echo "$(YELLOW)       # нет networks — контейнеры изолированы$(NC)"
	@echo ""
	@echo "$(YELLOW)   host.docker.internal — специальное DNS-имя,$(NC)"
	@echo "$(YELLOW)   резолвится в IP хоста (вашей ВМ) изнутри контейнера$(NC)"
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Попробовать выполнить любой запрос$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что приходит ошибка (бэкенд недоступен)$(NC)"
	@echo "$(YELLOW)   4. Проверить, что бэкенд тоже не открывается: http://<IP>:8081$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_net_containers)
	$(call check_port,$(NET_FRONT_PORT))
	$(call run_cmd,docker compose -f docker-compose.no-network.yml up -d --build)
	@cd $(NET_DIR) && docker compose -f docker-compose.no-network.yml up -d --build
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнеры запущены$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Попробовать выполнить любой запрос$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что приходит ошибка (бэкенд недоступен)$(NC)"
	@echo "$(YELLOW)   4. Проверить, что бэкенд тоже не открывается: http://<IP>:8081$(NC)"
	@echo "$(YELLOW)   Следующий шаг: make net-down  →  make net-ports$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

net-ports: ## Сети: общение через проброшенные порты — бэкенд виден снаружи
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 2 из 3: общение через проброшенный порт$(NC)"
	@echo ""
	@echo "$(YELLOW)Бэкенд публикует порт 8081. Фронтенд обращается к нему$(NC)"
	@echo "$(YELLOW)через хост (host.docker.internal:8081) — запрос идёт$(NC)"
	@echo "$(YELLOW)наружу из контейнера, через хост, и обратно в контейнер.$(NC)"
	@echo "$(YELLOW)Работает — но бэкенд теперь виден снаружи для всех!$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     orders-api:$(NC)"
	@echo "$(YELLOW)       image: docker-lab/orders-api:latest$(NC)"
	@echo "$(YELLOW)       container_name: backend-orders-api$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: backend$(NC)"
	@echo "$(MAGENTA)       ports:                          # ◄ добавлено$(NC)"
	@echo "$(MAGENTA)         - \"8081:8080\"                 # ◄ бэкенд виден снаружи$(NC)"
	@echo "$(YELLOW)       env_file: \".env\"$(NC)"
	@echo ""
	@echo "$(YELLOW)     orders-web:$(NC)"
	@echo "$(YELLOW)       image: orders-frontend$(NC)"
	@echo "$(YELLOW)       container_name: frontend-orders$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: frontend$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(YELLOW)       environment:$(NC)"
	@echo "$(YELLOW)         BACKEND_HOST: host.docker.internal$(NC)"
	@echo "$(YELLOW)         BACKEND_PORT: \"8081\"$(NC)"
	@echo "$(YELLOW)       extra_hosts:$(NC)"
	@echo "$(YELLOW)         - \"host.docker.internal:host-gateway\"$(NC)"
	@echo ""
	@echo "$(YELLOW)   Путь запроса: браузер → фронтенд :3001 → хост :8081 → бэкенд$(NC)"
	@echo "$(YELLOW)   Запрос дважды пересекает сетевую границу — лишний маршрут$(NC)"
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Убедиться, что запросы к бэкенду проходят$(NC)"
	@echo "$(YELLOW)   3. Открыть бэкенд напрямую: http://<IP_вашей_ВМ>:8081/orders$(NC)"
	@echo "$(YELLOW)   4. Убедиться, что бэкенд ДОСТУПЕН снаружи (это проблема)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_net_containers)
	$(call check_port,$(NET_FRONT_PORT))
	$(call run_cmd,docker compose -f docker-compose.ports.yml up -d --build)
	@cd $(NET_DIR) && docker compose -f docker-compose.ports.yml up -d --build
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнеры запущены$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Убедиться, что запросы к бэкенду проходят$(NC)"
	@echo "$(YELLOW)   3. Открыть бэкенд напрямую: http://<IP_вашей_ВМ>:8081/orders$(NC)"
	@echo "$(YELLOW)   4. Убедиться, что бэкенд ДОСТУПЕН снаружи (это проблема)$(NC)"
	@echo "$(YELLOW)   Следующий шаг: make net-down  →  make net-network$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

net-network: ## Сети: контейнеры в общей сети — бэкенд закрыт снаружи
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Шаг 3 из 3: контейнеры в общей Docker-сети$(NC)"
	@echo ""
	@echo "$(YELLOW)Оба контейнера в сети orders-net. Фронтенд достаёт бэкенд$(NC)"
	@echo "$(YELLOW)по имени сервиса orders-api:8080 — внутри сети, напрямую.$(NC)"
	@echo "$(YELLOW)Бэкенд не публикует порт — снаружи он невидим.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)docker-compose.yml:$(NC)"
	@echo ""
	@echo "$(MAGENTA)   networks:                         # ◄ добавлено$(NC)"
	@echo "$(MAGENTA)     orders-net:                     # ◄ имя сети$(NC)"
	@echo "$(MAGENTA)       driver: bridge                # ◄ тип: внутренняя сеть$(NC)"
	@echo ""
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     orders-api:$(NC)"
	@echo "$(YELLOW)       image: docker-lab/orders-api:latest$(NC)"
	@echo "$(YELLOW)       container_name: backend-orders-api$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: backend$(NC)"
	@echo "$(YELLOW)       env_file: \".env\"$(NC)"
	@echo "$(YELLOW)       # нет ports — бэкенд недоступен снаружи$(NC)"
	@echo "$(MAGENTA)       networks:                     # ◄ добавлено$(NC)"
	@echo "$(MAGENTA)         - orders-net                # ◄ подключён к сети$(NC)"
	@echo ""
	@echo "$(YELLOW)     orders-web:$(NC)"
	@echo "$(YELLOW)       image: orders-frontend$(NC)"
	@echo "$(YELLOW)       container_name: frontend-orders$(NC)"
	@echo "$(YELLOW)       build:$(NC)"
	@echo "$(YELLOW)         context: frontend$(NC)"
	@echo "$(YELLOW)       ports:$(NC)"
	@echo "$(YELLOW)         - \"3001:3000\"$(NC)"
	@echo "$(YELLOW)       environment:$(NC)"
	@echo "$(MAGENTA)         BACKEND_HOST: orders-api    # ◄ изменено: имя сервиса$(NC)"
	@echo "$(MAGENTA)         BACKEND_PORT: \"8080\"        # ◄ изменено: внутренний порт$(NC)"
	@echo "$(YELLOW)       # нет extra_hosts — хост больше не нужен$(NC)"
	@echo "$(MAGENTA)       networks:                     # ◄ добавлено$(NC)"
	@echo "$(MAGENTA)         - orders-net                # ◄ та же сеть, что у бэкенда$(NC)"
	@echo ""
	@echo "$(YELLOW)   Docker DNS: в сети orders-net имя сервиса = DNS-имя$(NC)"
	@echo "$(YELLOW)   orders-api резолвится в IP контейнера автоматически$(NC)"
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Что делать после запуска:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Убедиться, что запросы к бэкенду проходят$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что бэкенд НЕ открывается: http://<IP>:8081$(NC)"
	@echo "$(YELLOW)   4. Изучить сеть командами ниже$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	$(call check_net_containers)
	$(call check_port,$(NET_FRONT_PORT))
	$(call run_cmd,docker compose -f docker-compose.network.yml up -d --build)
	@cd $(NET_DIR) && docker compose -f docker-compose.network.yml up -d --build
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Сети Docker:$(NC)"
	@echo ""
	$(call run_cmd,docker network ls)
	@docker network ls
	@echo ""
	$(call run_cmd,docker network inspect $(NET_NAME))
	@docker network inspect $(NET_NAME) 2>/dev/null | python3 -m json.tool 2>/dev/null || docker network inspect $(NET_NAME)
	@echo ""
	@echo "$(YELLOW)Поле \"Containers\" — контейнеры в сети и их IP$(NC)"
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Контейнеры запущены$(NC)"
	@echo ""
	@echo "$(YELLOW)Что делать:$(NC)"
	@echo "$(YELLOW)   1. Открыть фронтенд: http://<IP_вашей_ВМ>:$(NET_FRONT_PORT)$(NC)"
	@echo "$(YELLOW)   2. Убедиться, что запросы к бэкенду проходят$(NC)"
	@echo "$(YELLOW)   3. Убедиться, что бэкенд НЕ открывается: http://<IP>:8081$(NC)"
	@echo "$(YELLOW)   4. Изучить: docker network inspect $(NET_NAME)$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

net-down: ## Остановить пример с сетями
	@echo "$(YELLOW)Останавливаем пример с сетями...$(NC)"
	@echo ""
	@NET_ABS=$(CURDIR)/$(NET_DIR); \
	ACTIVE=""; \
	for f in docker-compose.no-network.yml docker-compose.ports.yml docker-compose.network.yml; do \
		if docker compose -f $$NET_ABS/$$f ps -q 2>/dev/null | grep -q .; then \
			ACTIVE=$$f; \
			break; \
		fi; \
	done; \
	if [ -n "$$ACTIVE" ]; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker compose -f $$ACTIVE down$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		cd $$NET_ABS && docker compose -f $$ACTIVE down; \
	elif docker ps -q --filter name=$(NET_BACK_CONT) | grep -q . || docker ps -q --filter name=$(NET_FRONT_CONT) | grep -q .; then \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		echo "$(BOLD)$(GREEN)  ▶  docker stop $(NET_BACK_CONT) $(NET_FRONT_CONT)$(NC)"; \
		echo "$(GREEN)────────────────────────────────────────────────────────$(NC)"; \
		docker stop $(NET_BACK_CONT) $(NET_FRONT_CONT) 2>/dev/null || true; \
	else \
		echo "$(YELLOW)   Контейнеры не запущены$(NC)"; \
	fi

## ═══════════════════════════════════════════════════════════════
## Сценарии для траблшутинга
## ═══════════════════════════════════════════════════════════════

chaos-list: ## Список тренировочных сценариев
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Тренировочные сценарии — по одному на тему$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)  make break-stage1     Сценарий по теме 1 (Сборка)$(NC)"
	@echo "$(YELLOW)  make break-stage2     Сценарий по теме 2 (Управление)$(NC)"
	@echo "$(YELLOW)  make break-stage3     Сценарий по теме 3 (Монтирование)$(NC)"
	@echo "$(YELLOW)  make break-stage4     Сценарий по теме 4 (Сети)$(NC)"
	@echo ""
	@echo "$(YELLOW)  make fix-stage<N>     Разбор сценария N и очистка$(NC)"
	@echo ""
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Как работать:$(NC)"
	@echo "$(YELLOW)   1. make break-stageN — контейнер запущен, студенты диагностируют$(NC)"
	@echo "$(YELLOW)   2. Работаем по чеклисту (печатается при break)$(NC)"
	@echo "$(YELLOW)   3. make fix-stageN — разбор + очистка$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"

# Заглушки целей — наполнятся в последующих Task (чтобы help уже показывал список)
break-stage1: ## Тренировочный сценарий по теме 1 (Сборка)
	$(call chaos_cleanup)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BOLD)$(YELLOW)Тренировочный сценарий — тема 1$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Запускаю приложение. Что-то пошло не так.$(NC)"
	@echo "$(YELLOW)Ваша задача — найти причину.$(NC)"
	@echo ""
	$(call run_cmd,docker build -t $(CHAOS_STAGE1_IMG) -f $(CHAOS_DIR)/stage1/Dockerfile.broken $(BACKEND_DIR))
	@docker build -t $(CHAOS_STAGE1_IMG) -f $(CHAOS_DIR)/stage1/Dockerfile.broken $(BACKEND_DIR)
	@echo ""
	$(call run_cmd,docker run -d --name $(CHAOS_STAGE1_CONT) $(CHAOS_STAGE1_IMG))
	@docker run -d --name $(CHAOS_STAGE1_CONT) $(CHAOS_STAGE1_IMG) > /dev/null
	@sleep 2
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Состояние сейчас:$(NC)"
	@echo ""
	$(call run_cmd,docker ps -a --filter name=$(CHAOS_STAGE1_CONT))
	@docker ps -a --filter name=$(CHAOS_STAGE1_CONT)
	@echo ""
	$(call chaos_checklist)

fix-stage1: ## Разбор сценария по теме 1
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BOLD)$(YELLOW)Разбор сценария — тема 1: Сборка$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Что сломано (diff против рабочего Dockerfile):$(NC)"
	@echo ""
	@echo "$(YELLOW)   FROM python:3.11$(NC)"
	@echo "$(YELLOW)   WORKDIR /app$(NC)"
	@echo "$(YELLOW)   COPY app/requirements.txt .$(NC)"
	@echo "$(YELLOW)   RUN pip install -r requirements.txt$(NC)"
	@echo "$(YELLOW)   COPY app /app$(NC)"
	@echo "$(MAGENTA)   WORKDIR /srv                        # ◄ лишняя строка$(NC)"
	@echo "$(YELLOW)   CMD [\"gunicorn\", \"-b\", \"0.0.0.0:8080\", \"app:app\"]$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Корневая причина:$(NC)"
	@echo "$(YELLOW)   WORKDIR задаёт не только «куда копировать», но и cwd$(NC)"
	@echo "$(YELLOW)   для CMD. Вторая WORKDIR перед CMD увела рабочую$(NC)"
	@echo "$(YELLOW)   директорию в пустой /srv. Gunicorn стартует оттуда,$(NC)"
	@echo "$(YELLOW)   ищет модуль app, не находит, падает с exit code 3.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Проявления по чеклисту:$(NC)"
	@echo "$(YELLOW)   1. ps -a    → Exited (3) через секунду после старта$(NC)"
	@echo "$(YELLOW)   2. logs     → ModuleNotFoundError: No module named 'app'$(NC)"
	@echo "$(YELLOW)   3. inspect  → Config.WorkingDir = \"/srv\" (вместо /app)$(NC)"
	@echo "$(YELLOW)   4. exec     → недоступно, контейнер уже мёртв$(NC)"
	@echo "$(YELLOW)              но можно: docker run --rm -it --entrypoint sh <image>$(NC)"
	@echo "$(YELLOW)              → pwd покажет /srv, ls — пусто, ls /app — код$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Лечение: убрать строку WORKDIR /srv из Dockerfile.$(NC)"
	@echo ""
	@echo "$(YELLOW)Детали — chaos/stage1/README.md$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Убираю за собой...$(NC)"
	@docker rm -f $(CHAOS_STAGE1_CONT) 2>/dev/null || true
	@docker rmi $(CHAOS_STAGE1_IMG) 2>/dev/null || true
	@echo "$(YELLOW)Готово.$(NC)"

break-stage2: ## Тренировочный сценарий по теме 2 (Управление)
	$(call chaos_cleanup)
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BOLD)$(YELLOW)Тренировочный сценарий — тема 2$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Поднимаю стек через docker compose. Контейнер поднялся.$(NC)"
	@echo "$(YELLOW)Но что-то не так с запросами. Ваша задача — найти причину.$(NC)"
	@echo ""
	$(call run_cmd,docker compose -f $(CHAOS_DIR)/stage2/docker-compose.broken.yml up -d --build)
	@cd $(CHAOS_DIR)/stage2 && docker compose -f docker-compose.broken.yml up -d --build
	@sleep 3
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Состояние сейчас:$(NC)"
	@echo ""
	$(call run_cmd,docker ps --filter name=backend-orders-api)
	@docker ps --filter name=backend-orders-api
	@echo ""
	@echo "$(YELLOW)Контейнер Up — но попробуйте дернуть бэкенд:$(NC)"
	@echo "$(GREEN)   curl http://localhost:8081/orders$(NC)"
	@echo "$(YELLOW)и посмотрите логи:$(NC)"
	@echo "$(GREEN)   docker logs backend-orders-api$(NC)"
	@echo ""
	$(call chaos_checklist)

fix-stage2: ## Разбор сценария по теме 2
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(BOLD)$(YELLOW)Разбор сценария — тема 2: Управление$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Что сломано (фрагмент docker-compose.broken.yml):$(NC)"
	@echo ""
	@echo "$(YELLOW)   services:$(NC)"
	@echo "$(YELLOW)     orders-api:$(NC)"
	@echo "$(YELLOW)       # ...$(NC)"
	@echo "$(YELLOW)       environment:$(NC)"
	@echo "$(MAGENTA)         DB_PATH: /forbidden/orders.db    # ◄ путь в несуществующую директорию$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Корневая причина:$(NC)"
	@echo "$(YELLOW)   Приложение читает DB_PATH при импорте, но открывает$(NC)"
	@echo "$(YELLOW)   SQLite лениво — только при первом запросе к /orders.$(NC)"
	@echo "$(YELLOW)   До первого запроса контейнер выглядит живым: Up,$(NC)"
	@echo "$(YELLOW)   порт проброшен, gunicorn слушает. На первом запросе$(NC)"
	@echo "$(YELLOW)   sqlite3.connect пытается открыть файл в /forbidden/ —$(NC)"
	@echo "$(YELLOW)   директории нет → OperationalError → HTTP 500.$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Проявления по чеклисту:$(NC)"
	@echo "$(YELLOW)   1. ps -a    → Up. Всё выглядит нормально!$(NC)"
	@echo "$(YELLOW)   2. logs     → пусто до первого запроса к /orders$(NC)"
	@echo "$(YELLOW)              → после — sqlite3.OperationalError:$(NC)"
	@echo "$(YELLOW)                unable to open database file$(NC)"
	@echo "$(YELLOW)   3. inspect  → Config.Env: DB_PATH=/forbidden/orders.db$(NC)"
	@echo "$(YELLOW)   4. exec     → контейнер живой, спокойно заходим:$(NC)"
	@echo "$(YELLOW)              printenv | grep DB_PATH — видим значение$(NC)"
	@echo "$(YELLOW)              ls /forbidden — директории нет$(NC)"
	@echo ""
	@echo "$(YELLOW)────────────────────────────────────────────────────────$(NC)"
	@echo "$(YELLOW)Лечение: убрать DB_PATH из environment (используется дефолт),$(NC)"
	@echo "$(YELLOW)         либо указать путь внутри существующей директории,$(NC)"
	@echo "$(YELLOW)         например DB_PATH=/app/data/orders.db$(NC)"
	@echo ""
	@echo "$(YELLOW)Урок: «контейнер запустился» не значит «приложение работает».$(NC)"
	@echo ""
	@echo "$(YELLOW)Детали — chaos/stage2/README.md$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@echo "$(YELLOW)Убираю за собой...$(NC)"
	@cd $(CHAOS_DIR)/stage2 && docker compose -f docker-compose.broken.yml down 2>/dev/null || true
	@echo "$(YELLOW)Готово.$(NC)"

break-stage3: ## Тренировочный сценарий по теме 3 (Монтирование)
	@echo "$(RED)Цель ещё не реализована — см. Task 4$(NC)" && exit 1

fix-stage3: ## Разбор сценария по теме 3
	@echo "$(RED)Цель ещё не реализована — см. Task 4$(NC)" && exit 1

break-stage4: ## Тренировочный сценарий по теме 4 (Сети)
	@echo "$(RED)Цель ещё не реализована — см. Task 5$(NC)" && exit 1

fix-stage4: ## Разбор сценария по теме 4
	@echo "$(RED)Цель ещё не реализована — см. Task 5$(NC)" && exit 1

## ═══════════════════════════════════════════════════════════════
## Справка
## ═══════════════════════════════════════════════════════════════

help: ## Показать список команд
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)  Docker Lab — Пульт управления$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / \
		{printf "  $(YELLOW)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
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
	@echo ""
	@echo "$(YELLOW)   Этап 3: Монтирование$(NC)"
	@echo "$(YELLOW)   make example-no-mount   Пример без маунта (данные пропадают)$(NC)"
	@echo "$(YELLOW)   make example-mount      Пример с bind mount$(NC)"
	@echo "$(YELLOW)   make example-volume     Пример с volume$(NC)"
	@echo "$(YELLOW)   make example-down       Остановить пример$(NC)"
	@echo ""
	@echo "$(YELLOW)   Этап 4: Сети$(NC)"
	@echo "$(YELLOW)   make net-no-network     Фронт и бэк без сети — бэкенд недоступен$(NC)"
	@echo "$(YELLOW)   make net-ports          Общение через проброшенный порт$(NC)"
	@echo "$(YELLOW)   make net-network        Контейнеры в общей Docker-сети$(NC)"
	@echo "$(YELLOW)   make net-down           Остановить пример$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
	@echo "$(YELLOW)Легенда:$(NC)"
	@echo "$(YELLOW)   этот текст                    — инструкции и подсказки$(NC)"
	@echo "$(GREEN)   ▶  docker run ...             — выполняемая команда$(NC)"
	@echo "   вывод команды без цвета       — результат выполнения команды"
	@echo "$(YELLOW)════════════════════════════════════════════════════════$(NC)"
