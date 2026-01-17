import time
import functools
import frappe
import os

RATE_LIMIT_PREFIX = "rate_limit:"


def rate_limit(limit=100, window=60):
    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Allow environment variable override: RATE_LIMIT_GET_CHATS=500
            env_key = f"RATE_LIMIT_{func.__name__.upper()}"
            actual_limit = int(os.environ.get(env_key, limit))
            
            user = frappe.session.user
            ip = frappe.local.request_ip
            key = f"{RATE_LIMIT_PREFIX}{func.__name__}:{user}:{ip}"

            current_count = get_request_count(key)
            if current_count >= actual_limit:
                remaining = get_ttl(key)
                frappe.local.response["http_status_code"] = 429
                frappe.local.response["headers"] = frappe.local.response.get("headers", {})
                frappe.local.response["headers"].update({
                    "X-RateLimit-Limit": str(actual_limit),
                    "X-RateLimit-Remaining": "0",
                    "X-RateLimit-Reset": str(remaining),
                    "Retry-After": str(remaining)
                })
                frappe.throw(
                    f"Rate limit exceeded. Try again in {remaining} seconds.",
                    title="Too Many Requests"
                )

            increment_request_count(key, window)

            frappe.local.response["headers"] = frappe.local.response.get("headers", {})
            frappe.local.response["headers"].update({
                "X-RateLimit-Limit": str(actual_limit),
                "X-RateLimit-Remaining": str(actual_limit - current_count - 1)
            })

            return func(*args, **kwargs)
        return wrapper
    return decorator


def get_request_count(key):
    try:
        count = frappe.cache().get_value(key)
        return int(count) if count else 0
    except Exception:
        return 0


def increment_request_count(key, window):
    try:
        current = get_request_count(key)
        if current == 0:
            frappe.cache().set_value(key, 1, expires_in_sec=window)
        else:
            frappe.cache().set_value(key, current + 1, expires_in_sec=window)
    except Exception:
        pass


def get_ttl(key):
    try:
        return frappe.cache().get_ttl(key) or 60
    except Exception:
        return 60
