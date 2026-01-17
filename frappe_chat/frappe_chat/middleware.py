import frappe

def handle_expect_header():
    try:
        if frappe.request and hasattr(frappe.request, 'environ'):
            if 'HTTP_EXPECT' in frappe.request.environ:
                frappe.logger().debug(f"Removing Expect header: {frappe.request.environ['HTTP_EXPECT']}")
                frappe.request.environ.pop('HTTP_EXPECT', None)
    except Exception as e:
        frappe.logger().error(f"Error in handle_expect_header: {str(e)}")
