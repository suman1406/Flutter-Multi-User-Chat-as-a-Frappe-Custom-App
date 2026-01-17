# Frappe Chat

Multi-user chat application with Frappe backend and Flutter client.

## Demo Video

<video src="https://github.com/suman1406/Flutter-Multi-User-Chat-as-a-Frappe-Custom-App/raw/master/videos/Frappe_Chat.mp4" controls width="100%"></video>

## Features

- Token-based authentication via Frappe
- Real-time messaging (adaptive polling)
- Rate limiting on all endpoints
- One-on-one and group chats
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