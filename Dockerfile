# ---- builder ----
FROM python:3.11-slim AS builder
WORKDIR /wheels
RUN pip install --upgrade pip wheel
COPY app/requirements.txt .
RUN pip wheel --no-cache-dir -r requirements.txt

# ---- runtime ----
FROM python:3.11-slim
WORKDIR /app
# minimal tools for healthcheck
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir --no-index --find-links=/wheels -r /wheels/requirements.txt

# Add app
COPY app /app
# Non-root user
RUN useradd -m appuser && mkdir -p /data && chown -R appuser:appuser /data /app
USER appuser

ENV DB_PATH=/data/orders.db
EXPOSE 8080
VOLUME ["/data"]
HEALTHCHECK --interval=10s --timeout=3s --retries=10 CMD curl -fsS http://localhost:8080/health || exit 1
CMD ["gunicorn", "-b", "0.0.0.0:8080", "app:app"]
