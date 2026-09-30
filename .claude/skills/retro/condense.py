#!/usr/bin/env python3
"""Condense a Claude Code session log for a retro.

Usage: python3 condense.py <session.jsonl> <out.txt>

Keeps every owner message in full, including those typed while the agent
was mid-turn (queued_command attachments, easy to miss and often the
sharpest correction), the agent's text, one line per tool call, and tool
errors. Slash commands appear as /name args. Generated passwords, hex
secrets, JWTs, bearer tokens, the password in scheme://user:password@host,
and password: or password= values are redacted, since the output is
handed to a subagent.
"""
import json
import re
import sys

REDACT = [
    re.compile(r"\b[a-z0-9]{6}-[a-z0-9]{6}-[a-z0-9]{6}\b", re.IGNORECASE),
    re.compile(r"\b[0-9a-f]{64}\b"),
    re.compile(r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"),
    re.compile(r"(Bearer\s+)[A-Za-z0-9._-]{20,}"),
    re.compile(r"(://[^:/\s@]+:)[^@\s]+(?=@)"),
    re.compile(r"(password\s*[:=]\s*)\S+", re.IGNORECASE),
]


def redact(text):
    for pat in REDACT:
        text = pat.sub(lambda m: (m.group(1) if pat.groups else "") + "[REDACTED]", text)
    return text


def owner_text(text):
    """Owner text worth keeping, or None for harness-injected content."""
    t = text.strip()
    if not t or t.startswith("Base directory for this skill"):
        return None
    if t.startswith("<"):
        name = re.search(r"<command-name>(.*?)</command-name>", t, re.DOTALL)
        if name:
            args = re.search(r"<command-args>(.*?)</command-args>", t, re.DOTALL)
            return (name.group(1).strip() + " " + (args.group(1).strip() if args else "")).strip()
        if "<bash-input>" in t:
            return "(ran with !) " + re.sub(r"</?bash-input>", "", t.split("</bash-input>")[0])
        return None
    return t


def main(path, out):
    lines = []
    for raw in open(path, encoding="utf-8"):
        try:
            e = json.loads(raw)
        except ValueError:
            continue
        ts = (e.get("timestamp") or "")[:19]
        att = e.get("attachment") or {}
        if att.get("type") == "queued_command":
            prompt = att.get("prompt", "")
            if isinstance(prompt, list):
                prompt = " ".join(
                    x.get("text", "") if x.get("type") == "text" else "[image]"
                    for x in prompt if isinstance(x, dict)
                )
            t = owner_text(str(prompt))
            if t:
                lines.append(f"{ts} OWNER (queued mid-turn): {t}")
            continue
        msg = e.get("message") or {}
        role, content = msg.get("role"), msg.get("content")
        if isinstance(content, str):
            if role == "user" and (t := owner_text(content)):
                lines.append(f"{ts} OWNER: {t}")
            continue
        for c in content or []:
            kind = c.get("type")
            if kind == "image" and role == "user":
                lines.append(f"{ts} OWNER: [image]")
            elif kind == "text" and role == "user":
                if t := owner_text(c.get("text", "")):
                    lines.append(f"{ts} OWNER: {t}")
            elif kind == "text":
                t = c.get("text", "").strip().replace("\n", " ")
                if t:
                    lines.append(f"{ts} AGENT: {t[:900]}")
            elif kind == "tool_use":
                inp = json.dumps(c.get("input", {}), ensure_ascii=False)
                lines.append(f"{ts} TOOL {c.get('name')}: {inp[:240]}")
            elif kind == "tool_result" and c.get("is_error"):
                body = c.get("content")
                if isinstance(body, list):
                    body = " ".join(x.get("text", "") for x in body if isinstance(x, dict))
                lines.append(f"{ts} TOOL ERROR: {str(body)[:300]}".replace("\n", " "))
    with open(out, "w", encoding="utf-8") as f:
        f.write(redact("\n".join(lines)) + "\n")
    print(f"{len(lines)} lines -> {out}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
