# Infra

## Environment setup

1. Copy the example env file:
   ```bash
   cp .env.example .env
   ```
2. After changing `.env`, restart the stack:
   ```bash
   docker compose down
   docker compose up -d --build
   ```
