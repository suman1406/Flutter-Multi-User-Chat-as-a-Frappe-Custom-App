# Demo Script

## Setup

1. Frappe backend running on `http://localhost:8000`
2. Flutter web app running in Chrome
3. Test users available:
   - `user1@turium.ai` / `Turium!2026`
   - `user2@turium.ai` / `Turium!2026`

## Demo Flow

### 1. Authentication (2 min)

**Login as User 1:**
- Open Flutter app
- Enter `user1@turium.ai` / `Turium!2026`
- Observe redirect to chat list

**Show token storage:**
- DevTools > Application > Local Storage
- Token stored securely

### 2. Create Chat (2 min)

**As User 1:**
- Click "+" button
- Enter `user2@turium.ai`
- Create chat
- Send messages: "Hello!", "Testing chat"

### 3. Multi-User Messaging (3 min)

**Open incognito window, login as User 2:**
- Chat appears in list (polling)
- Open chat, see messages
- Reply: "Hi back!"
- User 1 sees reply within 2 seconds

### 4. Real-Time Verification (2 min)

**Rapid exchange:**
- User 1: "Message 1"
- User 2: "Message 2"
- Observe 500ms-3s adaptive polling

### 5. Persistence (2 min)

**User 1: Refresh browser**
- Auto-login via stored token
- All messages preserved

**User 2: Logout and login**
- Messages still visible

### 6. Rate Limiting (1 min)

**Browser console:**
```javascript
for(let i=0; i<150; i++) {
  fetch('http://localhost:8000/api/method/frappe_chat.api.get_chats',
    {headers: {'Authorization': 'token YOUR_KEY:YOUR_SECRET'}})
    .then(r => { if(r.status === 429) console.log('Rate limited at', i); });
}
```

Observe 429 responses after ~100 requests.

## Requirements Checklist

- [x] Frappe Custom App
- [x] Frappe native authentication (token-based)
- [x] DocTypes: Chat, Chat Message, Chat Participant
- [x] REST APIs with rate limiting
- [x] Flutter native UI
- [x] Multiple users and conversations
- [x] Real-time messaging (polling)
- [x] Message persistence
