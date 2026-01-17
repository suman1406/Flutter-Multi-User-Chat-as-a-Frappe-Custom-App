import frappe
from frappe.model.document import Document


class Chat(Document):
    def validate(self):
        self.validate_participants()

    def validate_participants(self):
        if self.chat_type == "Direct" and len(self.participants) != 2:
            frappe.throw("Direct chats must have exactly 2 participants")

    def before_insert(self):
        if not self.owner:
            self.owner = frappe.session.user

