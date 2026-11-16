#!/usr/bin/env python3
"""Install or remove the omarchy-branding-text rows in a JSONC menu file.

The menu file is JSON with comments, so it cannot go through json.load. The
plugin only ever appends a marked block of complete entries before the final
closing brace, and removes that same marked block again.
"""

import sys

BEGIN = "// omarchy-branding-text:begin"
END = "// omarchy-branding-text:end"


def remove(text: str) -> str:
    lines = []
    skipping = False
    for line in text.splitlines():
        marker = line.strip()
        if marker == BEGIN:
            skipping = True
            continue
        if marker == END:
            skipping = False
            continue
        if not skipping:
            lines.append(line)
    return "\n".join(lines) + "\n"


def add(text: str, block: str) -> str:
    if BEGIN in text:
        return text

    lines = text.splitlines() or ["{", "}"]
    close = None
    for index in range(len(lines) - 1, -1, -1):
        if lines[index].strip() == "}":
            close = index
            break
    if close is None:
        raise SystemExit("menu file has no closing brace on its own line")

    content = None
    for index in range(close - 1, -1, -1):
        stripped = lines[index].strip()
        if stripped and not stripped.startswith("//"):
            content = index
            break

    if content is not None and not lines[content].rstrip().endswith((",", "{")):
        lines[content] = lines[content].rstrip() + ","

    lines[close:close] = block.rstrip("\n").splitlines()
    return "\n".join(lines) + "\n"


def main() -> int:
    if len(sys.argv) < 3:
        print("usage: menu.py add|remove <menu-file> [<block-file>]", file=sys.stderr)
        return 2
    action, path = sys.argv[1], sys.argv[2]

    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except FileNotFoundError:
        if action != "add":
            return 0
        text = "{\n}\n"

    if action == "add":
        if len(sys.argv) < 4:
            print("add needs a block file", file=sys.stderr)
            return 2
        with open(sys.argv[3], encoding="utf-8") as handle:
            block = handle.read()
        out = add(text, block)
    elif action == "remove":
        out = remove(text)
    else:
        print(f"unknown action: {action}", file=sys.stderr)
        return 2

    if out != text:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
