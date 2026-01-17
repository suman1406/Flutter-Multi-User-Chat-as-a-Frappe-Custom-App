import frappe
import os

os.chdir("/home/frappe/frappe-bench/sites")

frappe.init(site="chat.localhost")
frappe.connect()
frappe.set_user("Administrator")

users = [
    {"email": "user1@turium.ai", "first_name": "User1", "password": "Turium!2026"},
    {"email": "user2@turium.ai", "first_name": "User2", "password": "Turium!2026"},
]

for u in users:
    if not frappe.db.exists("User", u["email"]):
        user = frappe.get_doc({
            "doctype": "User",
            "email": u["email"],
            "first_name": u["first_name"],
            "enabled": 1,
            "new_password": u["password"],
            "roles": [{"role": "Chat User"}]
        })
        user.insert(ignore_permissions=True)
        print(f"Created user: {u['email']}")
    else:
        user = frappe.get_doc("User", u["email"])
        user.new_password = u["password"]
        if not any(r.role == "Chat User" for r in user.roles):
            user.append("roles", {"role": "Chat User"})
        user.save(ignore_permissions=True)
        print(f"Updated user: {u['email']}")

frappe.db.commit()
print("Users setup complete!")

frappe.destroy()
