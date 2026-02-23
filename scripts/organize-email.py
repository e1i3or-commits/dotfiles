#!/usr/bin/env python3
"""
Gmail IMAP Folder Reorganizer — Frost Peak
Consolidates ~120 folders into 8 top-level categories.

Requires a Gmail App Password:
  1. Go to https://myaccount.google.com/apppasswords
  2. Create one for "Mail" → "Other (Thunderbird)"
  3. Copy the 16-character password

Usage:
    python3 organize-email.py                # Dry-run (preview only)
    python3 organize-email.py --execute      # Apply changes
"""

import imaplib
import getpass
import sys
import time
import re

# ──────────────────────────────────────────────
# Folder mapping: source → destination
# Grouped by destination. First source listed per destination
# is the "primary" (renamed). Others are merged into it.
# ──────────────────────────────────────────────

CATEGORY_MAP = {
    # ── Finance ──
    "Finance/Accounting":       ["Accounting"],
    "Finance/Bank":             ["Bank"],
    "Finance/Bank Notices":     ["Bank Notices"],
    "Finance/Bank Notifications": ["Bank Notifications"],
    "Finance/Bank Statements":  ["Bank Statements"],
    "Finance/Billing":          ["Billing", "Bills"],
    "Finance/Bookkeeping":      ["Bookkeeping"],
    "Finance/DDA":              ["DDA"],
    "Finance/Expense Reports":  ["Expense Reports"],
    "Finance/General":          ["Finance", "Financial"],
    "Finance/Financing":        ["Financing"],
    "Finance/Gusto":            ["Gusto"],
    "Finance/Insurance":        ["Insurance"],
    "Finance/Invoices":         ["Invoice", "Invoices"],
    "Finance/Payments":         ["Payment", "Payment Received", "Payments"],
    "Finance/Payroll":          ["Payroll"],
    "Finance/Receipts":         ["Receipts"],
    "Finance/SBA":              ["SBA"],
    "Finance/Statements":       ["Statements"],
    "Finance/Stripe":           ["Stripe"],
    "Finance/Taxes":            ["Tax", "Tax Documents", "Taxes"],
    "Finance/Wire Transfer":    ["Wire Transfer"],

    # ── Sales & Marketing ──
    "Sales & Marketing/Ads":            ["Ads"],
    "Sales & Marketing/Campaigns":      ["Campaigns"],
    "Sales & Marketing/Cold Outreach":  ["Cold Outreach"],
    "Sales & Marketing/Customer Inquiry": ["Customer Inquiry", "Customer Question"],
    "Sales & Marketing/Google Ads":     ["Google Ads"],
    "Sales & Marketing/Kajabi":         ["Kajabi"],
    "Sales & Marketing/Leads":          ["Lead"],
    "Sales & Marketing/General":        ["Marketing"],
    "Sales & Marketing/Membership":     ["Membership"],
    "Sales & Marketing/Meta Ads":       ["Meta Ads"],
    "Sales & Marketing/Promotions":     ["Promotions"],
    "Sales & Marketing/Reviews":        ["Reviews"],
    "Sales & Marketing/Sales":          ["Sales", "Sales Inquiry"],
    "Sales & Marketing/SEO":            ["SEO"],
    "Sales & Marketing/Social":         ["Social Media", "Social", "Facebook"],
    "Sales & Marketing/Territory Check": ["Territory Check"],

    # ── Operations ──
    "Operations/Account Setup":     ["Account Setup"],
    "Operations/Admin":             ["Admin"],
    "Operations/Contracts":         ["Contracts"],
    "Operations/Delivery Updates":  ["Delivery Updates"],
    "Operations/DNS":               ["DNS"],
    "Operations/Docs":              ["Docs"],
    "Operations/Domain":            ["Domain", "Domain Renewal"],
    "Operations/HVAC":              ["HVAC"],
    "Operations/Maintenance":       ["Maintenance"],
    "Operations/Orders":            ["Order Confirmation", "Order Tracking"],
    "Operations/Reports":           ["Reports"],
    "Operations/Shared Files":      ["Shared Files"],
    "Operations/Shipping":          ["Shipping", "Shipping Updates", "USPS"],
    "Operations/Squarespace":       ["Squarespace"],
    "Operations/Templates":         ["Templates"],
    "Operations/Vendor Updates":    ["Vendor Updates"],
    "Operations/Website":           ["Website Feedback", "Website Launch", "Website-Migration"],
    "Operations/Xola Support":      ["Xola Support"],

    # ── Clients ──
    "Clients/Boats":            ["Boats"],
    "Clients/Cruisin Tikis":    ["Cruisin Tikis"],
    "Clients/Destin":           ["Destin"],
    "Clients/EO":               ["EO"],
    "Clients/Franchise":        ["Franchise"],
    "Clients/TourCraft":        ["TourCraft"],
    "Clients/TourScale":        ["TourScale"],
    "Clients/USVI":             ["USVI_Location"],
    "Clients/Wilmington":       ["Wilmington"],

    # ── Legal & HR ──
    "Legal & HR/Audit":         ["Audit"],
    "Legal & HR/Compensation":  ["Compensation"],
    "Legal & HR/HR":            ["HR"],
    "Legal & HR/Legal":         ["Legal", "Legal Documents"],
    "Legal & HR/Markup":        ["Markup"],
    "Legal & HR/Security":      ["Security", "Security Alert"],
    "Legal & HR/Signatures":    ["Signatures"],
    "Legal & HR/Support":       ["Support"],

    # ── Scheduling ──
    "Scheduling/Calendar":          ["Calendar"],
    "Scheduling/Cancelled":         ["CANCELLED_MEETING"],
    "Scheduling/Conferences":       ["Conference Registration"],
    "Scheduling/Declined":          ["DECLINED", "DECLINED_CALENDAR", "DECLINED_MEETING"],
    "Scheduling/Events":            ["Events"],
    "Scheduling/Meeting Notes":     ["Meeting Notes"],
    "Scheduling/Zoom":              ["Zoom"],

    # ── Action Items ──
    "Action Items/Completed":       ["Completed"],
    "Action Items/Follow Up":       ["Follow Up", "FOLLOW_UP", "Follow Up Required"],
    "Action Items/High Priority":   ["High Priority", "Priority"],
    "Action Items/Important":       ["Important"],
    "Action Items/Needs Attention": ["Needs Attention"],
    "Action Items/Needs Response":  ["Needs Response", "NEEDS_RESPONSE"],
    "Action Items/Needs Review":    ["Needs Review", "Review Required"],
    "Action Items/Resolved":        ["Resolved"],
    "Action Items/Urgent":          ["URGENT"],

    # ── Personal ──
    "Personal/Bachelor Party":  ["Bachelor Party"],
    "Personal/Bounced":         ["Bounced"],
    "Personal/Fundraising":     ["Fundraising"],
    "Personal/Keynote":         ["keynote"],
    "Personal/Networking":      ["Networking"],
    "Personal/Newsletters":     ["Newsletter", "Newsletters"],
    "Personal/Notifications":   ["Notifications", "system-notification"],
    "Personal/Password Reset":  ["Password Reset"],
    "Personal/Shopping":        ["Shopping"],
    "Personal/SMS":             ["SMS"],
    "Personal/Subscriptions":   ["Subscription"],
    "Personal/Travel":          ["Travel"],
}

# Folders to NEVER touch
SKIP_FOLDERS = {"INBOX", "[Gmail]", "[Superhuman]", "[Gmail]/All Mail",
                "[Gmail]/Drafts", "[Gmail]/Important", "[Gmail]/Sent Mail",
                "[Gmail]/Spam", "[Gmail]/Starred", "[Gmail]/Trash",
                "[Gmail]/Bin", "[Superhuman]/Snoozed", "[Superhuman]/Read Later"}


def imap_utf7_encode(text):
    """Encode string to IMAP modified UTF-7 (& must become &-)."""
    return text.replace('&', '&-')


def imap_encode(folder_name):
    """Quote and encode folder name for IMAP."""
    encoded = imap_utf7_encode(folder_name)
    return f'"{encoded}"'


def parse_folder_list(response):
    """Parse LIST response into folder names."""
    folders = []
    for item in response:
        if isinstance(item, bytes):
            item = item.decode("utf-8", errors="replace")
        # Match: (\flags) "separator" "folder name" or (\flags) "sep" folder
        match = re.match(r'\(.*?\)\s+"(.+?)"\s+"?(.+?)"?\s*$', item)
        if match:
            name = match.group(2).strip('"')
            folders.append(name)
        else:
            # Try simpler pattern
            match = re.match(r'\(.*?\)\s+"(.+?)"\s+(.+)', item)
            if match:
                name = match.group(2).strip('"')
                folders.append(name)
    return folders


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


def merge_folder(imap, source, dest):
    """Move all messages from source to dest, then delete source."""
    try:
        # Select source
        status, data = imap.select(imap_encode(source))
        if status != "OK":
            print(f"    [!] Could not select {source}: {data}")
            return False

        msg_count = int(data[0])
        if msg_count == 0:
            imap.close()
            # Delete empty folder
            status, data = imap.delete(imap_encode(source))
            if status == "OK":
                print(f"    Deleted empty folder: {source}")
            return True

        # Copy all messages to destination
        print(f"    Copying {msg_count} messages from '{source}' → '{dest}'...")
        status, data = imap.uid("COPY", "1:*", imap_encode(dest))
        if status != "OK":
            print(f"    [!] COPY failed: {data}")
            imap.close()
            return False

        # Mark as deleted in source
        status, data = imap.uid("STORE", "1:*", "+FLAGS", "(\\Deleted)")
        if status != "OK":
            print(f"    [!] DELETE flag failed: {data}")
            imap.close()
            return False

        # Expunge
        imap.expunge()
        imap.close()

        # Delete the now-empty folder
        status, data = imap.delete(imap_encode(source))
        if status == "OK":
            print(f"    Merged and removed: {source}")
        else:
            print(f"    [!] Messages moved but could not delete folder: {data}")

        return True
    except imaplib.IMAP4.error as e:
        print(f"    [!] MERGE error for '{source}' → '{dest}': {e}")
        try:
            imap.close()
        except Exception:
            pass
        return False


def rename_folder(imap, source, dest):
    """Rename (move) a folder."""
    try:
        status, data = imap.rename(imap_encode(source), imap_encode(dest))
        if status == "OK":
            print(f"    Renamed: '{source}' → '{dest}'")
            return True
        else:
            print(f"    [!] RENAME failed for '{source}': {data}")
            return False
    except imaplib.IMAP4.error as e:
        print(f"    [!] RENAME error for '{source}' → '{dest}': {e}")
        return False


def main():
    execute = "--execute" in sys.argv

    print("=" * 62)
    print("  Gmail IMAP Folder Reorganizer — Frost Peak")
    print("  Consolidates folders into 8 top-level categories")
    print("=" * 62)
    print()

    if not execute:
        print("  MODE: DRY RUN (preview only)")
        print("  Add --execute to apply changes")
    else:
        print("  MODE: EXECUTE (changes will be applied!)")
    print()

    # ── Credentials ──
    email = input("Email: ").strip()
    password = getpass.getpass("App Password: ")
    print()

    # ── Connect ──
    print("Connecting to Gmail IMAP...")
    try:
        imap = imaplib.IMAP4_SSL("imap.gmail.com", 993)
        imap.login(email, password)
        print("Connected successfully.\n")
    except imaplib.IMAP4.error as e:
        print(f"Login failed: {e}")
        print("Make sure you're using an App Password, not your regular password.")
        print("Create one at: https://myaccount.google.com/apppasswords")
        sys.exit(1)

    # ── List current folders ──
    status, folder_data = imap.list()
    if status != "OK":
        print("Failed to list folders.")
        sys.exit(1)

    existing_folders = set(parse_folder_list(folder_data))
    print(f"Found {len(existing_folders)} folders on server.\n")

    # ── Build operations ──
    renames = []    # (source, dest)
    merges = []     # (source, dest) - move messages then delete source
    skipped = []    # source folders not found on server
    untouched = []  # server folders not in our map

    mapped_sources = set()

    for dest, sources in CATEGORY_MAP.items():
        primary = None
        for i, src in enumerate(sources):
            if src not in existing_folders:
                skipped.append(src)
                continue
            mapped_sources.add(src)
            if primary is None:
                # First existing source → rename
                renames.append((src, dest))
                primary = dest
            else:
                # Subsequent sources → merge into the renamed dest
                merges.append((src, primary))

    # Find folders we're not touching
    for f in sorted(existing_folders):
        is_skip = False
        for skip in SKIP_FOLDERS:
            if f == skip or f.startswith(skip + "/"):
                is_skip = True
                break
        if not is_skip and f not in mapped_sources:
            # Check if it's a subfolder of a mapped source
            parent = f.split("/")[0] if "/" in f else None
            if parent not in mapped_sources:
                untouched.append(f)

    # ── Print plan ──
    print("─" * 62)
    print("RENAME OPERATIONS (move folder to new location):")
    print("─" * 62)
    for src, dst in renames:
        print(f"  {src:<35} → {dst}")
    print(f"\n  Total: {len(renames)} renames\n")

    print("─" * 62)
    print("MERGE OPERATIONS (move messages, delete duplicate):")
    print("─" * 62)
    for src, dst in merges:
        count = get_message_count(imap, src) if execute else "?"
        print(f"  {src:<35} → {dst}  ({count} msgs)")
    print(f"\n  Total: {len(merges)} merges\n")

    if skipped:
        print("─" * 62)
        print(f"NOT FOUND on server ({len(skipped)}):")
        print("─" * 62)
        for s in sorted(skipped):
            print(f"  {s}")
        print()

    if untouched:
        print("─" * 62)
        print(f"UNTOUCHED folders ({len(untouched)}):")
        print("─" * 62)
        for u in sorted(untouched):
            print(f"  {u}")
        print()

    if not execute:
        print("=" * 62)
        print("  DRY RUN complete. No changes were made.")
        print("  Run with --execute to apply these changes.")
        print("=" * 62)
        imap.logout()
        return

    # ── Confirm ──
    print("=" * 62)
    print(f"  READY: {len(renames)} renames + {len(merges)} merges")
    print("  This will reorganize your Gmail folders.")
    print("  Messages are NEVER deleted — only moved between folders.")
    print("=" * 62)
    confirm = input("\n  Type 'yes' to proceed: ").strip().lower()
    if confirm != "yes":
        print("Aborted.")
        imap.logout()
        return

    print()

    # ── Phase 1: Renames ──
    print("Phase 1: Renaming folders...")
    rename_ok = 0
    rename_fail = 0
    for src, dst in renames:
        if rename_folder(imap, src, dst):
            rename_ok += 1
        else:
            rename_fail += 1
        time.sleep(0.2)  # Be gentle on Gmail

    print(f"\n  Renames: {rename_ok} OK, {rename_fail} failed\n")

    # ── Phase 2: Merges ──
    if merges:
        print("Phase 2: Merging duplicate folders...")
        merge_ok = 0
        merge_fail = 0
        for src, dst in merges:
            if merge_folder(imap, src, dst):
                merge_ok += 1
            else:
                merge_fail += 1
            time.sleep(0.3)

        print(f"\n  Merges: {merge_ok} OK, {merge_fail} failed\n")

    # ── Done ──
    print("=" * 62)
    print("  Reorganization complete!")
    print("  Restart Thunderbird to see the new folder structure.")
    print("  In Thunderbird: right-click account → Subscribe → refresh")
    print("=" * 62)

    imap.logout()


if __name__ == "__main__":
    main()
