#!/usr/bin/env python3
"""
Delete old flat Gmail labels that have been reorganized into categories.
On Gmail, deleting a label does NOT delete messages — they remain in
All Mail and under any other labels (the new categorized ones).

Usage:
    python3 delete-old-labels.py                # Dry-run
    python3 delete-old-labels.py --execute      # Apply
"""

import imaplib
import getpass
import sys
import time


def imap_utf7_encode(text):
    return text.replace('&', '&-')

def imap_encode(folder_name):
    return '"' + imap_utf7_encode(folder_name) + '"'

def imap_utf7_decode(text):
    return text.replace('&-', '&')


# ── Old flat labels to delete ──
# These have all been reorganized under the 8 categories.
OLD_LABELS = [
    # Was Finance/*
    "Accounting", "Bank", "Bank Notices", "Bank Notifications",
    "Bank Statements", "Billing", "Bills", "Bookkeeping", "DDA",
    "Expense Reports", "Financial", "Financing", "Gusto", "Insurance",
    "Invoice", "Invoices", "Payment", "Payment Received", "Payments",
    "Payroll", "Receipts", "SBA", "Statements", "Stripe", "Tax",
    "Tax Documents", "Taxes", "Wire Transfer",
    # Was Sales & Marketing/*
    "Ads", "Campaigns", "Cold Outreach", "Customer Inquiry",
    "Customer Question", "Facebook", "Google Ads", "Kajabi", "Lead",
    "Leads", "Marketing", "Membership", "Meta Ads", "Promotions",
    "Reviews", "Sales", "Sales Inquiry", "SEO", "Social",
    "Social Media", "Territory Check",
    # Was Operations/*
    "Account Setup", "Admin", "Contracts", "Delivery Updates", "DNS",
    "Docs", "Domain", "Domain Renewal", "HVAC", "Maintenance",
    "Order Confirmation", "Order Tracking", "Orders", "Reports",
    "Shared Files", "Shipping", "Shipping Updates", "Squarespace",
    "Templates", "USPS", "Vendor Updates", "Website Feedback",
    "Website Launch", "Website-Migration", "Xola Support",
    # Was Clients/*
    "Boats", "Cruisin Tikis", "Destin", "EO", "Franchise",
    "TourCraft", "TourScale", "USVI_Location", "Wilmington",
    # Was Legal & HR/*
    "Audit", "Compensation", "HR", "Legal", "Legal Documents",
    "Markup", "Security", "Security Alert", "Signatures", "Support",
    # Was Scheduling/*
    "Calendar", "CANCELLED_MEETING", "Cancelled", "Conference Registration",
    "Conferences", "DECLINED", "DECLINED_CALENDAR", "DECLINED_MEETING",
    "Declined", "Events", "Meeting Notes", "Zoom",
    # Was Action Items/*
    "Action Required", "Completed", "Follow Up", "FOLLOW_UP",
    "Follow Up Required", "High Priority", "High", "Important",
    "Needs Attention", "Needs Response", "NEEDS_RESPONSE",
    "Needs Review", "Priority", "Resolved", "Review Required", "URGENT",
    # Was Personal/*
    "Bachelor Party", "Bounced", "Fundraising", "keynote", "Keynote",
    "Networking", "Newsletter", "Newsletters", "Notifications",
    "Password Reset", "Shopping", "Sharing", "SMS", "Social",
    "Subscription", "Subscriptions", "system-notification", "Travel",
    # Intermediate containers from botched nesting
    "Finance/General", "Finance/General/General",
    "General",
]


def main():
    dry_run = "--execute" not in sys.argv

    print("=" * 62)
    print("  Delete old flat Gmail labels")
    print("=" * 62)
    print(f"  MODE: {'DRY RUN' if dry_run else 'EXECUTE'}\n")

    email = input("Email: ").strip()
    password = getpass.getpass("App Password: ")
    print()

    print("Connecting...")
    try:
        imap = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        imap.login(email, password)
    except imaplib.IMAP4.error as e:
        print(f"Login failed: {e}")
        sys.exit(1)

    # Get current folders
    status, folder_data = imap.list()
    current = set()
    for item in folder_data:
        if isinstance(item, bytes):
            item = item.decode("utf-8", errors="replace")
        import re
        match = re.match(r'\(.*?\)\s+"(.+?)"\s+"?(.+?)"?\s*$', item)
        if match:
            current.add(imap_utf7_decode(match.group(2).strip('"')))

    print(f"Labels on server: {len(current)}\n")

    # Find which old labels still exist
    to_delete = [label for label in OLD_LABELS if label in current]
    not_found = [label for label in OLD_LABELS if label not in current]

    print(f"Old labels still present: {len(to_delete)}")
    print(f"Already gone: {len(not_found)}\n")

    if not to_delete:
        print("Nothing to delete!")
        imap.logout()
        return

    print("─" * 62)
    print("WILL DELETE:")
    print("─" * 62)
    for label in sorted(to_delete):
        print(f"  {label}")
    print()

    if dry_run:
        print("DRY RUN — no changes made. Run with --execute to delete.")
        imap.logout()
        return

    confirm = input(f"Delete {len(to_delete)} old labels? Type 'yes': ").strip()
    if confirm != "yes":
        print("Aborted.")
        imap.logout()
        return

    print()
    ok = 0
    fail = 0
    for label in sorted(to_delete):
        try:
            status, data = imap.delete(imap_encode(label))
            if status == "OK":
                print(f"  Deleted: {label}")
                ok += 1
            else:
                print(f"  [!] Failed: {label} — {data}")
                fail += 1
        except imaplib.IMAP4.error as e:
            print(f"  [!] Error: {label} — {e}")
            fail += 1
        time.sleep(0.1)

    print(f"\nDone: {ok} deleted, {fail} failed")
    print("Refresh Thunderbird: right-click account → Subscribe → Refresh")

    imap.logout()


if __name__ == "__main__":
    main()
