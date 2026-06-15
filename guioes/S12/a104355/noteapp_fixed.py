#!/usr/bin/env python3
"""A corrected note-taking application without injection flaws."""

import re
import sqlite3
from pathlib import Path

DB_FILE = "notes.db"
SAFE_FILENAME_RE = re.compile(r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,63}$")


def init_db():
    """Create the notes table if it does not exist."""
    conn = sqlite3.connect(DB_FILE)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS notes "
        "(id INTEGER PRIMARY KEY, title TEXT, body TEXT)"
    )
    conn.execute(
        "INSERT OR IGNORE INTO notes (id, title, body) VALUES "
        "(1, 'Welcome', 'This is your first note.'), "
        "(2, 'Reminder', 'Submit the SSI lab report on time.'), "
        "(3, 'Secret', 'The admin password is hunter2.')"
    )
    conn.commit()
    conn.close()


def search_notes(query):
    """Search notes by title safely using a parameterised query."""
    conn = sqlite3.connect(DB_FILE)
    sql = "SELECT id, title, body FROM notes WHERE title LIKE ?"
    parameter = f"%{query}%"
    print(f"[DEBUG] Executing SQL: {sql} | params=({parameter!r},)")
    try:
        cursor = conn.execute(sql, (parameter,))
        results = cursor.fetchall()
        if results:
            for row in results:
                print(f"  [{row[0]}] {row[1]}: {row[2]}")
        else:
            print("  No notes found.")
    except sqlite3.Error as e:
        print(f"  SQL error: {e}")
    conn.close()


def is_safe_filename(filename):
    """Allow only simple local filenames, no shell metacharacters or paths."""
    if not SAFE_FILENAME_RE.fullmatch(filename):
        return False
    candidate = Path(filename)
    return candidate.name == filename


def export_note(note_id):
    """Export a note to a file without invoking a shell."""
    conn = sqlite3.connect(DB_FILE)
    cursor = conn.execute(
        "SELECT title, body FROM notes WHERE id = ?", (note_id,)
    )
    row = cursor.fetchone()
    conn.close()

    if row is None:
        print("  Note not found.")
        return

    filename = input("  Enter filename to export to: ").strip()
    if not is_safe_filename(filename):
        print("  Invalid filename. Use only letters, digits, ., _ and -.")
        return

    output_path = Path(filename)
    payload = f"Title: {row[0]}\nBody: {row[1]}\n"
    output_path.write_text(payload, encoding="utf-8")
    print(f"  Note exported to {output_path}")


def main():
    init_db()
    while True:
        print("\n=== Note App ===")
        print("1. Search notes")
        print("2. Export note")
        print("3. Quit")
        choice = input("Choice: ").strip()

        if choice == "1":
            query = input("  Search query: ")
            search_notes(query)
        elif choice == "2":
            try:
                note_id = int(input("  Note ID: "))
            except ValueError:
                print("  Invalid ID.")
                continue
            export_note(note_id)
        elif choice == "3":
            break
        else:
            print("  Invalid choice.")


if __name__ == "__main__":
    main()
