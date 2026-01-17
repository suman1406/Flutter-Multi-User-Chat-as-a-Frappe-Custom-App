from functools import wraps
import frappe

def strip_expect_header(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if frappe.request and hasattr(frappe.request, 'environ'):
            frappe.request.environ.pop('HTTP_EXPECT', None)
        return fn(*args, **kwargs)
    return wrapper

def authenticated_only(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if frappe.session.user == 'Guest':
            frappe.throw(frappe._("Authentication Required"), frappe.PermissionError)
        return fn(*args, **kwargs)
    return wrapper
