app_name = "frappe_chat"
app_title = "Frappe Chat"
app_publisher = "TuriumAI"
app_description = "Multi-user chat system"
app_icon = "octicon octicon-comment-discussion"
app_color = "#3498db"
app_email = "chat@turium.ai"
app_license = "MIT"
required_apps = ["frappe"]

fixtures = []

website_route_rules = [
    {"from_route": "/api/method/frappe_chat.<path:app_path>", "to_route": "frappe_chat.<app_path>"}
]

import os
allow_cors = [
    "http://localhost:*",
    "http://127.0.0.1:*"
]

production_origin = os.getenv("PRODUCTION_ORIGIN")
if production_origin:
    allow_cors.append(production_origin)

doc_events = {}

scheduler_events = {}

override_whitelisted_methods = {}

override_doctype_dashboards = {}

before_request = ["frappe_chat.middleware.handle_expect_header"]
