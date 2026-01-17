import frappe
from frappe.model.document import Document


class ChatMessage(Document):
    def before_insert(self):
        self.sender = frappe.session.user
        self.validate_chat_access()

    def validate_chat_access(self):
        chat = frappe.get_doc("Chat", self.chat)
        participants = [p.user for p in chat.participants]
        if frappe.session.user not in participants:
            frappe.throw("You are not a participant of this chat", frappe.PermissionError)

    def after_insert(self):
        self.update_chat_last_message()
        self.publish_realtime()

    def update_chat_last_message(self):
        frappe.db.set_value("Chat", self.chat, {
            "last_message": self.content[:100],
            "last_message_at": self.creation
        })

    def publish_realtime(self):
        chat = frappe.get_doc("Chat", self.chat)
        for participant in chat.participants:
            if participant.user != self.sender:
                frappe.publish_realtime(
                    event="new_message",
                    message={
                        "chat": self.chat,
                        "message": self.name,
                        "sender": self.sender,
                        "content": self.content
                    },
                    user=participant.user
                )
