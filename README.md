# Frappe Chat

Multi-user chat application with Frappe backend and Flutter client.

## Demo Video

[📹 Watch Demo Video](https://github.com/suman1406/Flutter-Multi-User-Chat-as-a-Frappe-Custom-App/releases/download/v1.0/Frappe_chat.mp4)

## Features

- Token-based authentication via Frappe
- Real-time messaging (adaptive polling)
- Rate limiting on all endpoints
- One-on-one chats
- Message persistence

## Quick Start

```bash
docker-compose up -d
```

Backend available at http://localhost:8000

**Test Users:**
- `user1@turium.ai` / `Turium!2026`
- `user2@turium.ai` / `Turium!2026`

## Flutter Client

```bash
cd flutter_chat
flutter pub get
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

## Project Structure

```
├── frappe_chat/      # Frappe custom app
├── flutter_chat/     # Flutter client
├── docs/             # Documentation
├── images/           # Architecture diagrams
└── videos/           # Demo video
```

## Documentation

- [Architecture](docs/ARCHITECTURE.md) - System design and diagrams
- [Setup Guide](docs/SETUP.md) - Installation instructions