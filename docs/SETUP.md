# Setup Guide

## Prerequisites

- Docker 20.10+ with Docker Compose
- Flutter 3.0+

## Automated Setup

The `docker-entrypoint.sh` script handles:
- Symlinking frappe_chat app
- Creating the site with admin password
- Installing the app
- Starting the server

```powershell
docker-compose up -d
```

Wait ~2 minutes for first-time setup. Server available at http://localhost:8000

## Manual Setup (Alternative)

### 1. Start Containers

```powershell
docker-compose up -d
docker exec -it frappe-web bash
```

### 2. Create Site

```bash
cd /home/frappe/frappe-bench

bench new-site chat.localhost \
  --admin-password admin \
  --db-root-password frappe_root \
  --no-mariadb-socket

bench --site chat.localhost install-app frappe_chat
bench --site chat.localhost migrate
```

### 3. Seed Test Users

```bash
cd apps/frappe_chat
python3 setup_users.py
```

Creates:
- `user1@turium.ai` / `Turium!2026`
- `user2@turium.ai` / `Turium!2026`

### 4. Start Server

```bash
bench serve --port 8000
```

## Flutter Client

### 1. Install Dependencies

```powershell
cd flutter_chat
flutter pub get
```

### 2. Configure Base URL

Edit `lib/config/app_config.dart`:

```dart
static const String baseUrl = 'http://127.0.0.1:8000';
```

### 3. Run

```powershell
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

## Quick Commands

| Action | Command |
|--------|---------|
| Start | `docker-compose up -d` |
| Stop | `docker-compose down` |
| Logs | `docker logs -f frappe-web` |
| Shell | `docker exec -it frappe-web bash` |
