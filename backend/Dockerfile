# Build stage
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Production stage
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY app/ ./app/
ENV PATH=/root/.local/bin:$PATH
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser
EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
