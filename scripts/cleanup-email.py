#!/usr/bin/env python3
"""
Gmail IMAP Cleanup — Fix nesting + remove old labels

Fixes:
  1. Finance/General/General/* → Finance/*  (flatten triple nesting)
  2. Finance/General/* → Finance/*  (flatten double nesting)
  3. Delete old flat labels that were renamed but not removed
  4. Handle straggler folders

Usage:
    python3 cleanup-email.py                # Dry-run (preview only)
    python3 cleanup-email.py --execute      # Apply changes
"""

import imaplib
import getpass
import sys
import re
import time


def imap_utf7_encode(text):
    """Encode & as &- for IMAP modified UTF-7."""
    return text.replace('&', '&-')


def imap_encode(folder_name):
    """Quote and encode folder name for IMAP."""
    return '"' + imap_utf7_encode(folder_name) + '"'


def imap_utf7_decode(text):
    """Decode IMAP modified UTF-7 &- back to &."""
    return text.replace('&-', '&')


def parse_folder_list(response):
    """Parse LIST response into folder names."""
    folders = []
    for item in response:
        if isinstance(item, bytes):
            item = item.decode("utf-8", errors="replace")
        match = re.match(r'\(.*?\)\s+"(.+?)"\s+"?(.+?)"?\s*$', item)
        if match:
            name = imap_utf7_decode(match.group(2).strip('"'))
            folders.append(name)
        else:
            match = re.match(r'\(.*?\)\s+"(.+?)"\s+(.+)', item)
            if match:
                name = imap_utf7_decode(match.group(2).strip('"'))
                folders.append(name)
    return sorted(folders)


def get_message_count(imap, folder):
    """Get number of messages in a folder."""
    try:
        status, data = imap.select(imap_encode(folder), readonly=True)
        if status == "OK":
            count = int(data[0])
            imap.close()
            return count
    except Exception:
        pass
    return 0


def rename_folder(imap, source, dest, dry_run=True):
    """Rename a folder. Returns True on success."""
    if dry_run:
        print(f"  [DRY] RENAME '{source}' → '{dest}'")
        return True
    try:
        status, data = imap.rename(imap_encode(source), imap_encode(dest))
        if status == "OK":
            print(f"  RENAMED: '{source}' → '{dest}'")
            return True
        else:
            print(f"  [!] RENAME failed: {data}")
            return False
    except imaplib.IMAP4.error as e:
        print(f"  [!] RENAME error: {e}")
        return False


def move_messages_and_delete(imap, source, dest, dry_run=True):
    """Move all messages from source to dest, delete source."""
    count = get_message_count(imap, source)
    if dry_run:
        print(f"  [DRY] MERGE '{source}' ({count} msgs) → '{dest}', then DELETE '{source}'")
        return True
    try:
        if count > 0:
            status, data = imap.select(imap_encode(source))
            if status != "OK":
                print(f"  [!] Could not select '{source}'")
                return False
            status, data = imap.uid("COPY", "1:*", imap_encode(dest))
            if status != "OK":
                print(f"  [!] COPY failed: {data}")
                imap.close()
                return False
            imap.uid("STORE", "1:*", "+FLAGS", "(\\Deleted)")
            imap.expunge()
            imap.close()
            print(f"  MOVED {count} msgs: '{source}' → '{dest}'")
        # Delete the folder
        status, data = imap.delete(imap_encode(source))
        if status == "OK":
            print(f"  DELETED: '{source}'")
        else:
            print(f"  [!] DELETE failed for '{source}': {data}")
        return True
    except imaplib.IMAP4.error as e:
        print(f"  [!] Error: {e}")
        try:
            imap.close()
        except Exception:
            pass
        return False


def delete_folder(imap, folder, dry_run=True):
    """Delete a folder (must be empty or Gmail will just remove the label)."""
    if dry_run:
        count = get_message_count(imap, folder)
        print(f"  [DRY] DELETE '{folder}' ({count} msgs)")
        return True
    try:
        status, data = imap.delete(imap_encode(folder))
        if status == "OK":
            print(f"  DELETED: '{folder}'")
            return True
        else:
            print(f"  [!] DELETE failed for '{folder}': {data}")
            return False
    except imaplib.IMAP4.error as e:
        print(f"  [!] DELETE error for '{folder}': {e}")
        return False


def main():
    dry_run = "--execute" not in sys.argv

    print("=" * 62)
    print("  Gmail Cleanup — Fix nesting + remove old labels")
    print("=" * 62)
    print(f"  MODE: {'DRY RUN (preview)' if dry_run else 'EXECUTE'}")
    print()

    email = input("Email: ").strip()
    password = getpass.getpass("App Password: ")
    print()

    print("Connecting...")
    try:
        imap = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        imap.login(email, password)
        print("Connected.\n")
    except imaplib.IMAP4.error as e:
        print(f"Login failed: {e}")
        sys.exit(1)

    # List all folders
    status, folder_data = imap.list()
    if status != "OK":
        print("Failed to list folders")
        sys.exit(1)

    all_folders = set(parse_folder_list(folder_data))
    print(f"Total labels on server: {len(all_folders)}\n")

    # Print current state
    print("─" * 62)
    print("CURRENT LABELS:")
    print("─" * 62)
    for f in sorted(all_folders):
        print(f"  {f}")
    print()

    # ── The 8 valid top-level categories ──
    valid_categories = {
        "Action Items", "Clients", "Finance", "Legal & HR",
        "Operations", "Personal", "Sales & Marketing", "Scheduling"
    }

    # System folders to never touch
    system_prefixes = {"[Gmail]", "[Superhuman]", "INBOX"}

    # ── Phase 1: Fix Finance triple/double nesting ──
    print("─" * 62)
    print("PHASE 1: Fix Finance nesting")
    print("─" * 62)

    finance_fixes = []
    for folder in sorted(all_folders):
        # Finance/General/General/* → Finance/*
        if folder.startswith("Finance/General/General/"):
            new_name = "Finance/" + folder[len("Finance/General/General/"):]
            finance_fixes.append(("rename", folder, new_name))
        # Finance/General/* → Finance/* (but not Finance/General/General which we handle above)
        elif folder.startswith("Finance/General/") and not folder.startswith("Finance/General/General"):
            new_name = "Finance/" + folder[len("Finance/General/"):]
            finance_fixes.append(("rename", folder, new_name))

    # Delete the empty nesting containers after moving children
    if "Finance/General/General" in all_folders:
        finance_fixes.append(("delete", "Finance/General/General", None))
    if "Finance/General" in all_folders:
        finance_fixes.append(("delete", "Finance/General", None))

    if finance_fixes:
        for action, src, dst in finance_fixes:
            if action == "rename":
                # Check if destination already exists
                if dst in all_folders:
                    # Merge instead
                    move_messages_and_delete(imap, src, dst, dry_run)
                else:
                    rename_folder(imap, src, dst, dry_run)
            elif action == "delete":
                delete_folder(imap, src, dry_run)
            if not dry_run:
                time.sleep(0.2)
    else:
        print("  No Finance nesting issues found.")
    print()

    # ── Phase 2: Identify and remove old flat labels ──
    # These are labels that should now be under a category
    print("─" * 62)
    print("PHASE 2: Remove old flat labels (already reorganized)")
    print("─" * 62)

    # Map of old flat labels → where they should be now
    old_to_new = {
        # Finance
        "Accounting": "Finance/Accounting",
        "Bank": "Finance/Bank",
        "Bank Notices": "Finance/Bank Notices",
        "Bank Notifications": "Finance/Bank Notifications",
        "Bank Statements": "Finance/Bank Statements",
        "Billing": "Finance/Billing",
        "Bills": "Finance/Billing",
        "Bookkeeping": "Finance/Bookkeeping",
        "DDA": "Finance/DDA",
        "Expense Reports": "Finance/Expense Reports",
        "Financial": "Finance/General",
        "Financing": "Finance/Financing",
        "Gusto": "Finance/Gusto",
        "Insurance": "Finance/Insurance",
        "Invoice": "Finance/Invoices",
        "Invoices": "Finance/Invoices",
        "Payment": "Finance/Payments",
        "Payment Received": "Finance/Payments",
        "Payments": "Finance/Payments",
        "Payroll": "Finance/Payroll",
        "Receipts": "Finance/Receipts",
        "SBA": "Finance/SBA",
        "Statements": "Finance/Statements",
        "Stripe": "Finance/Stripe",
        "Tax": "Finance/Taxes",
        "Tax Documents": "Finance/Taxes",
        "Taxes": "Finance/Taxes",
        "Wire Transfer": "Finance/Wire Transfer",
        # Sales & Marketing
        "Ads": "Sales & Marketing/Ads",
        "Campaigns": "Sales & Marketing/Campaigns",
        "Cold Outreach": "Sales & Marketing/Cold Outreach",
        "Customer Inquiry": "Sales & Marketing/Customer Inquiry",
        "Customer Question": "Sales & Marketing/Customer Inquiry",
        "Facebook": "Sales & Marketing/Social",
        "Google Ads": "Sales & Marketing/Google Ads",
        "Kajabi": "Sales & Marketing/Kajabi",
        "Lead": "Sales & Marketing/Leads",
        "Marketing": "Sales & Marketing/General",
        "Membership": "Sales & Marketing/Membership",
        "Meta Ads": "Sales & Marketing/Meta Ads",
        "Promotions": "Sales & Marketing/Promotions",
        "Reviews": "Sales & Marketing/Reviews",
        "Sales": "Sales & Marketing/Sales",
        "Sales Inquiry": "Sales & Marketing/Sales",
        "SEO": "Sales & Marketing/SEO",
        "Social": "Sales & Marketing/Social",
        "Social Media": "Sales & Marketing/Social",
        "Territory Check": "Sales & Marketing/Territory Check",
        # Operations
        "Account Setup": "Operations/Account Setup",
        "Admin": "Operations/Admin",
        "Contracts": "Operations/Contracts",
        "Delivery Updates": "Operations/Delivery Updates",
        "DNS": "Operations/DNS",
        "Docs": "Operations/Docs",
        "Domain": "Operations/Domain",
        "Domain Renewal": "Operations/Domain",
        "HVAC": "Operations/HVAC",
        "Maintenance": "Operations/Maintenance",
        "Order Confirmation": "Operations/Orders",
        "Order Tracking": "Operations/Orders",
        "Reports": "Operations/Reports",
        "Shared Files": "Operations/Shared Files",
        "Shipping": "Operations/Shipping",
        "Shipping Updates": "Operations/Shipping",
        "Squarespace": "Operations/Squarespace",
        "Templates": "Operations/Templates",
        "USPS": "Operations/Shipping",
        "Vendor Updates": "Operations/Vendor Updates",
        "Website Feedback": "Operations/Website",
        "Website Launch": "Operations/Website",
        "Website-Migration": "Operations/Website",
        "Xola Support": "Operations/Xola Support",
        # Clients
        "Boats": "Clients/Boats",
        "Cruisin Tikis": "Clients/Cruisin Tikis",
        "Destin": "Clients/Destin",
        "EO": "Clients/EO",
        "Franchise": "Clients/Franchise",
        "TourCraft": "Clients/TourCraft",
        "TourScale": "Clients/TourScale",
        "USVI_Location": "Clients/USVI",
        "Wilmington": "Clients/Wilmington",
        # Legal & HR
        "Audit": "Legal & HR/Audit",
        "Compensation": "Legal & HR/Compensation",
        "HR": "Legal & HR/HR",
        "Legal": "Legal & HR/Legal",
        "Legal Documents": "Legal & HR/Legal",
        "Markup": "Legal & HR/Markup",
        "Security": "Legal & HR/Security",
        "Security Alert": "Legal & HR/Security",
        "Signatures": "Legal & HR/Signatures",
        "Support": "Legal & HR/Support",
        # Scheduling
        "Calendar": "Scheduling/Calendar",
        "CANCELLED_MEETING": "Scheduling/Cancelled",
        "Conference Registration": "Scheduling/Conferences",
        "DECLINED": "Scheduling/Declined",
        "DECLINED_CALENDAR": "Scheduling/Declined",
        "DECLINED_MEETING": "Scheduling/Declined",
        "Events": "Scheduling/Events",
        "Meeting Notes": "Scheduling/Meeting Notes",
        "Zoom": "Scheduling/Zoom",
        # Action Items
        "Action Required": "Action Items/Important",
        "Completed": "Action Items/Completed",
        "Follow Up": "Action Items/Follow Up",
        "FOLLOW_UP": "Action Items/Follow Up",
        "Follow Up Required": "Action Items/Follow Up",
        "High Priority": "Action Items/High Priority",
        "Important": "Action Items/Important",
        "Needs Attention": "Action Items/Needs Attention",
        "Needs Response": "Action Items/Needs Response",
        "NEEDS_RESPONSE": "Action Items/Needs Response",
        "Needs Review": "Action Items/Needs Review",
        "Priority": "Action Items/High Priority",
        "Review Required": "Action Items/Needs Review",
        "URGENT": "Action Items/Urgent",
        # Personal
        "Bachelor Party": "Personal/Bachelor Party",
        "Bounced": "Personal/Bounced",
        "Fundraising": "Personal/Fundraising",
        "keynote": "Personal/Keynote",
        "Networking": "Personal/Networking",
        "Newsletter": "Personal/Newsletters",
        "Newsletters": "Personal/Newsletters",
        "Notifications": "Personal/Notifications",
        "Password Reset": "Personal/Password Reset",
        "Shopping": "Personal/Shopping",
        "Sharing": "Personal/Shopping",
        "SMS": "Personal/SMS",
        "Subscription": "Personal/Subscriptions",
        "system-notification": "Personal/Notifications",
        "Travel": "Personal/Travel",
    }

    old_found = []
    for old_name, new_name in sorted(old_to_new.items()):
        if old_name in all_folders:
            count = get_message_count(imap, old_name)
            old_found.append((old_name, new_name, count))

    if old_found:
        for old_name, new_name, count in old_found:
            if count > 0:
                # Has messages — merge into the correct destination
                if new_name in all_folders:
                    move_messages_and_delete(imap, old_name, new_name, dry_run)
                else:
                    # Destination doesn't exist, rename instead
                    rename_folder(imap, old_name, new_name, dry_run)
            else:
                # Empty — just delete
                delete_folder(imap, old_name, dry_run)
            if not dry_run:
                time.sleep(0.2)
    else:
        print("  No old flat labels found.")
    print()

    # ── Phase 3: Clean up any remaining uncategorized labels ──
    print("─" * 62)
    print("PHASE 3: Remaining uncategorized labels")
    print("─" * 62)

    # Re-list after changes (in dry-run, use original list)
    remaining = []
    for f in sorted(all_folders):
        # Skip system
        if any(f == s or f.startswith(s + "/") for s in system_prefixes):
            continue
        # Skip already-categorized
        if any(f == c or f.startswith(c + "/") for c in valid_categories):
            continue
        # Skip if in old_to_new (will be handled)
        if f in old_to_new:
            continue
        remaining.append(f)

    if remaining:
        for f in remaining:
            count = get_message_count(imap, f)
            print(f"  UNCATEGORIZED: '{f}' ({count} msgs)")
    else:
        print("  All labels are categorized.")
    print()

    # ── Summary ──
    print("=" * 62)
    if dry_run:
        print("  DRY RUN complete. No changes made.")
        print("  Run with --execute to apply.")
    else:
        print("  Cleanup complete!")
        print("  Refresh Thunderbird: right-click account → Subscribe")
    print("=" * 62)

    imap.logout()


if __name__ == "__main__":
    main()
