import frappe
from frappe import _
from frappe_chat.rate_limiter import rate_limit
from frappe_chat.utils import authenticated_only
import json


@frappe.whitelist()
@rate_limit(limit=100, window=60)
@authenticated_only
def get_chats():
    user = frappe.session.user
    chats = frappe.db.sql("""
        SELECT DISTINCT c.name, c.chat_name, c.chat_type, c.last_message, c.last_message_at
        FROM `tabChat` c
        INNER JOIN `tabChat Participant` cp ON cp.parent = c.name
        WHERE cp.user = %s
        ORDER BY c.last_message_at DESC
    """, (user,), as_dict=True)
    return chats


@frappe.whitelist()
@rate_limit(limit=50, window=60)
@authenticated_only
def create_chat(chat_name, participants, chat_type="Direct"):
    if isinstance(participants, str):
        participants = json.loads(participants)
    
    if frappe.session.user not in participants:
        participants.append(frappe.session.user)

    if chat_type == "Direct" and len(participants) != 2:
        frappe.throw(_("Direct chats must have exactly 2 participants"))

    existing = find_existing_direct_chat(participants) if chat_type == "Direct" else None
    if existing:
        return existing

    chat = frappe.get_doc({
        "doctype": "Chat",
        "chat_name": chat_name,
        "chat_type": chat_type,
        "participants": [{"user": u} for u in participants]
    })
    chat.insert(ignore_permissions=True)
    frappe.db.commit()
    return chat.name


def find_existing_direct_chat(participants):
    chats = frappe.db.sql("""
        SELECT c.name FROM `tabChat` c
        WHERE c.chat_type = 'Direct'
        AND (SELECT COUNT(*) FROM `tabChat Participant` cp WHERE cp.parent = c.name) = 2
        AND EXISTS (SELECT 1 FROM `tabChat Participant` cp WHERE cp.parent = c.name AND cp.user = %s)
        AND EXISTS (SELECT 1 FROM `tabChat Participant` cp WHERE cp.parent = c.name AND cp.user = %s)
    """, (participants[0], participants[1]), as_dict=True)
    if chats:
        frappe.msgprint(_("Chat already exists"))
        return chats[0].name
    return None


@frappe.whitelist()
@rate_limit(limit=200, window=60)
@authenticated_only
def get_messages(chat, after=None, limit=50):
    validate_chat_access(chat)

    filters = {"chat": chat}
    if after:
        filters["creation"] = (">", after)

    messages = frappe.get_all(
        "Chat Message",
        filters=filters,
        fields=["name", "sender", "content", "message_type", "creation", "is_read"],
        order_by="creation asc",
        limit_page_length=int(limit)
    )
    return messages


@frappe.whitelist()
@rate_limit(limit=100, window=60)
@authenticated_only
def send_message(chat, content, message_type="text"):
    validate_chat_access(chat)

    message = frappe.get_doc({
        "doctype": "Chat Message",
        "chat": chat,
        "sender": frappe.session.user,
        "content": content,
        "message_type": message_type
    })
    message.insert(ignore_permissions=True)
    
    chat_doc = frappe.get_doc("Chat", chat)
    chat_doc.last_message = content[:100] if len(content) > 100 else content
    chat_doc.last_message_at = message.creation
    chat_doc.save(ignore_permissions=True)
    
    frappe.db.commit()

    return {
        "name": message.name,
        "sender": message.sender,
        "content": message.content,
        "creation": str(message.creation)
    }


@frappe.whitelist()
@rate_limit(limit=100, window=60)
@authenticated_only
def mark_as_read(chat):
    validate_chat_access(chat)
    frappe.db.sql("""
        UPDATE `tabChat Message`
        SET is_read = 1
        WHERE chat = %s AND sender != %s AND is_read = 0
    """, (chat, frappe.session.user))
    frappe.db.commit()


@frappe.whitelist()
@authenticated_only
def get_chat_participants(chat):
    validate_chat_access(chat)
    return frappe.get_all(
        "Chat Participant",
        filters={"parent": chat},
        fields=["user", "joined_at", "last_read_at"]
    )


def validate_chat_access(chat):
    exists = frappe.db.exists("Chat Participant", {
        "parent": chat,
        "user": frappe.session.user
    })
    if not exists:
        frappe.throw(_("Access denied"), frappe.PermissionError)


@frappe.whitelist(allow_guest=True)
@rate_limit(limit=10, window=60)
def login(usr, pwd):
    print(f"Login attempt for: {usr}")
    login_manager = frappe.auth.LoginManager()
    login_manager.authenticate(user=usr, pwd=pwd)
    login_manager.post_login()
    print(f"Login successful for: {usr}")

    user = frappe.get_doc("User", frappe.session.user)
    
    # Generate new keys (manual to avoid AttributeError)
    from frappe import generate_hash
    
    if not user.api_key:
        user.api_key = generate_hash(length=15)
        
    api_secret = generate_hash(length=15)
    user.api_secret = api_secret
    
    user.save(ignore_permissions=True)
    
    frappe.db.commit()

    return {
        "message": "Logged In",
        "api_key": user.api_key,
        "api_secret": api_secret,
        "full_name": user.full_name,
        "email": user.email
    }


@frappe.whitelist(allow_guest=True)
@rate_limit(limit=5, window=60)
def signup(email, password, full_name):
    print(f"Signup attempt for: {email}")
    if frappe.db.exists("User", email):
        frappe.throw(_("User already exists"))

    user = frappe.get_doc({
        "doctype": "User",
        "email": email,
        "first_name": full_name,
        "enabled": 1,
        "new_password": password,
        "user_type": "System User",
        "roles": [{"role": "System Manager"}] # simplification for now, ideally restrict
    })
    user.flags.no_welcome_mail = True
    user.insert(ignore_permissions=True)
    print(f"User created: {email}")

    # Manual key generation (using frappe utils)
    from frappe import generate_hash
    
    if not user.api_key:
        user.api_key = generate_hash(length=15)
        
    api_secret = generate_hash(length=15)
    user.api_secret = api_secret
    
    user.save(ignore_permissions=True)
    
    frappe.db.commit()

    return {
        "message": "User Created",
        "api_key": user.api_key,
        "api_secret": api_secret,
        "full_name": user.full_name,
        "email": user.email
    }


@frappe.whitelist()
@rate_limit(limit=50, window=60)
@authenticated_only
def get_users():
    users = frappe.get_all("User", 
        fields=["name", "full_name", "email"],
        filters={"name": ["!=", frappe.session.user], "enabled": 1}
    )
    return users
