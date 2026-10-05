#!/usr/bin/env python3
"""Validate every manifest in the Whisperr agent kit.

Checks JSON syntax, the vendored JSON schemas (Agent Plugins 1.0.0 and
MCP Registry server.json), skill and rule front matter, cross-file
consistency (name, version, MCP URL), OpenAI listing limits, and the Claude
directory file rules. Exit code 1 on any error.

Usage: python3 scripts/validate.py [--require-schema]
Needs: PyYAML; jsonschema for schema checks (required with --require-schema).
"""
from __future__ import annotations

import json
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MCP_URL = "https://mcp.whisperr.net/mcp"
NAME = "whisperr"
SKIP_DIRS = {".git", "node_modules", "dist"}
IMAGE_EXT = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg"}

errors: list[str] = []
warnings: list[str] = []


def err(msg: str) -> None:
    errors.append(msg)


def load_json(rel: str):
    path = ROOT / rel
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        err(f"{rel}: missing")
    except json.JSONDecodeError as e:
        err(f"{rel}: invalid JSON: {e}")
    return None


def files():
    for p in ROOT.rglob("*"):
        if any(part in SKIP_DIRS for part in p.relative_to(ROOT).parts):
            continue
        if p.is_file():
            yield p


def check_all_json() -> None:
    for p in files():
        if p.suffix == ".json":
            try:
                json.loads(p.read_text(encoding="utf-8"))
            except json.JSONDecodeError as e:
                err(f"{p.relative_to(ROOT)}: invalid JSON: {e}")


def check_yaml_files(yaml) -> None:
    for p in files():
        if p.suffix in {".yml", ".yaml"}:
            try:
                yaml.safe_load(p.read_text(encoding="utf-8"))
            except yaml.YAMLError as e:
                err(f"{p.relative_to(ROOT)}: invalid YAML: {e}")


def schema_check(require: bool) -> None:
    try:
        import jsonschema  # type: ignore
    except ImportError:
        (err if require else warnings.append)("jsonschema not installed: schema checks skipped")
        return
    pairs = [
        ("plugin.json", "schemas/agent-plugins-1.0.0-plugin.schema.json"),
        ("mcp.json", "schemas/agent-plugins-1.0.0-mcp.schema.json"),
        ("registry/server.json", "schemas/mcp-registry-2025-12-11-server.schema.json"),
    ]
    for doc_rel, schema_rel in pairs:
        doc, schema = load_json(doc_rel), load_json(schema_rel)
        if doc is None or schema is None:
            continue
        cls = jsonschema.validators.validator_for(schema)
        validator = cls(schema, format_checker=cls.FORMAT_CHECKER)
        for e in sorted(validator.iter_errors(doc), key=lambda e: list(e.path)):
            loc = "/".join(str(x) for x in e.path) or "(root)"
            err(f"{doc_rel}: schema: {loc}: {e.message}")


def front_matter(path: Path, yaml):
    text = path.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        err(f"{path.relative_to(ROOT)}: front matter must start on line 1")
        return None, text
    end = text.find("\n---", 4)
    if end < 0:
        err(f"{path.relative_to(ROOT)}: front matter not closed")
        return None, text
    try:
        data = yaml.safe_load(text[4:end])
    except yaml.YAMLError as e:
        err(f"{path.relative_to(ROOT)}: front matter is not valid YAML: {e}")
        return None, text
    return data or {}, text[end + 4 :]


def check_skills(yaml) -> list[str]:
    names = []
    for skill in sorted((ROOT / "skills").glob("*/SKILL.md")):
        rel = skill.relative_to(ROOT)
        fm, body = front_matter(skill, yaml)
        if fm is None:
            continue
        name, desc = fm.get("name"), fm.get("description")
        if name != skill.parent.name:
            err(f"{rel}: name '{name}' must equal folder '{skill.parent.name}'")
        if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*", name or "") or len(name) > 64:
            err(f"{rel}: name must be kebab-case, <= 64 chars")
        if not isinstance(desc, str) or not desc.strip():
            err(f"{rel}: description must be a non-empty string")
        elif len(desc) > 1024:
            err(f"{rel}: description is {len(desc)} chars (limit 1024)")
        if len(body.splitlines()) > 500:
            warnings.append(f"{rel}: body over 500 lines")
        for link in re.findall(r"\]\((references/[^)]+)\)", body):
            if not (skill.parent / link).is_file():
                err(f"{rel}: broken reference link {link}")
        names.append(name)
    if sorted(names) != ["whisperr-insights", "whisperr-install", "whisperr-keep-in-sync"]:
        err(f"skills: expected the three Whisperr skills, found {names}")
    return names


def check_rules(yaml) -> None:
    rules = sorted((ROOT / "rules").glob("*.mdc"))
    if not rules:
        err("rules/: no .mdc rule")
    for rule in rules:
        fm, _ = front_matter(rule, yaml)
        if fm is None:
            continue
        if not isinstance(fm.get("description"), str):
            err(f"{rule.relative_to(ROOT)}: description required")
        if not isinstance(fm.get("alwaysApply"), bool):
            err(f"{rule.relative_to(ROOT)}: alwaysApply must be true or false")


def png_size(path: Path):
    data = path.read_bytes()[:24]
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", data[16:24])


def check_asset(rel: str, ctx: str) -> None:
    path = ROOT / rel.removeprefix("./")
    if not path.is_file():
        err(f"{ctx}: asset {rel} missing")
        return
    if path.suffix == ".png":
        size = png_size(path)
        if not size or size[0] != size[1] or size[0] < 48:
            err(f"{ctx}: {rel} must be a square PNG >= 48x48 (got {size})")


def check_manifests() -> None:
    claude = load_json(".claude-plugin/plugin.json") or {}
    market = load_json(".claude-plugin/marketplace.json") or {}
    cursor = load_json(".cursor-plugin/plugin.json") or {}
    portable = load_json("plugin.json") or {}
    codex_market = load_json(".agents/plugins/marketplace.json") or {}
    claude_mcp = load_json(".mcp.json") or {}
    portable_mcp = load_json("mcp.json") or {}
    server = load_json("registry/server.json") or {}

    # Identity and version agree everywhere.
    for label, doc in [("claude", claude), ("cursor", cursor), ("portable", portable)]:
        if doc.get("name") != NAME:
            err(f"{label} manifest: name must be '{NAME}'")
    versions = {label: doc.get("version") for label, doc in [("claude", claude), ("cursor", cursor), ("portable", portable)]}
    if len(set(versions.values())) != 1 or None in versions.values():
        err(f"manifest versions differ or are missing: {versions}")
    elif not re.fullmatch(r"\d+\.\d+\.\d+", next(iter(versions.values()))):
        err(f"manifest version must be semver: {versions}")

    # Claude plugin + marketplace.
    for key in ("description", "author", "license", "homepage"):
        if not claude.get(key):
            err(f".claude-plugin/plugin.json: {key} required")
    for key in ("documentationUrl", "supportUrl", "privacyPolicyUrl", "termsOfServiceUrl"):
        if not str(claude.get(key, "")).startswith("https://"):
            err(f".claude-plugin/plugin.json: {key} must be an https URL")
    check_asset(claude.get("icon", ""), ".claude-plugin/plugin.json icon")
    entries = market.get("plugins", [])
    if market.get("name") != NAME or not market.get("owner", {}).get("name"):
        err(".claude-plugin/marketplace.json: name 'whisperr' and owner.name required")
    if not any(e.get("name") == NAME and e.get("source") in ("./", ".") for e in entries):
        err(".claude-plugin/marketplace.json: needs entry 'whisperr' with source './'")

    # MCP configs point at one URL.
    srv = claude_mcp.get("mcpServers", {}).get(NAME, {})
    if srv != {"type": "http", "url": MCP_URL}:
        err(f".mcp.json: whisperr must be {{type: http, url: {MCP_URL}}}, got {srv}")
    srv = portable_mcp.get("mcpServers", {}).get(NAME, {})
    if srv.get("type") != "streamable-http" or srv.get("url") != MCP_URL:
        err(f"mcp.json: whisperr must be streamable-http {MCP_URL}")
    srv = cursor.get("mcpServers", {}).get(NAME, {})
    if srv.get("url") != MCP_URL:
        err(f".cursor-plugin/plugin.json: mcpServers.whisperr.url must be {MCP_URL}")
    remotes = server.get("remotes", [])
    if remotes != [{"type": "streamable-http", "url": MCP_URL}]:
        err(f"registry/server.json: remotes must be one streamable-http {MCP_URL}")
    if server.get("name") != "net.whisperr/whisperr":
        err("registry/server.json: name must be net.whisperr/whisperr")

    # Cursor plugin.
    if not re.fullmatch(r"[a-z0-9]([a-z0-9.-]*[a-z0-9])?", cursor.get("name", "")):
        err(".cursor-plugin/plugin.json: invalid name")
    check_asset(cursor.get("logo", ""), ".cursor-plugin/plugin.json logo")
    for key in ("skills", "rules"):
        target = ROOT / str(cursor.get(key, "")).removeprefix("./")
        if not cursor.get(key) or not target.is_dir():
            err(f".cursor-plugin/plugin.json: {key} path missing")

    # Codex repo marketplace.
    for entry in codex_market.get("plugins", []):
        policy = entry.get("policy", {})
        if not entry.get("category") or not policy.get("installation") or not policy.get("authentication"):
            err(".agents/plugins/marketplace.json: each entry needs category and policy.installation/authentication")
        path = entry.get("source", {}).get("path") if isinstance(entry.get("source"), dict) else entry.get("source")
        if not str(path).startswith("./"):
            err(".agents/plugins/marketplace.json: source.path must start with ./")

    # OpenAI listing limits (developers.openai.com/plugins/deploy/submission).
    oai = portable.get("extensions", {}).get("com.openai", {})
    ui = oai.get("interface", {})
    limits = {"displayName": 30, "shortDescription": 30, "longDescription": 4000, "developerName": 80}
    for key, limit in limits.items():
        value = ui.get(key)
        if not isinstance(value, str) or not value or len(value) > limit:
            err(f"plugin.json interface.{key}: required, <= {limit} chars")
    for key in ("websiteURL", "supportURL", "privacyPolicyURL", "termsOfServiceURL"):
        if not str(ui.get(key, "")).startswith("https://"):
            err(f"plugin.json interface.{key}: https URL required for MCP review")
    prompts = ui.get("defaultPrompt", [])
    if len(prompts) > 3 or any(len(p) > 128 for p in prompts) or len(set(prompts)) != len(prompts):
        err("plugin.json interface.defaultPrompt: <= 3 unique prompts, <= 128 chars each")
    for key in ("logo", "composerIcon"):
        check_asset(ui.get(key, ""), f"plugin.json interface.{key}")
    cases = oai.get("review", {}).get("test_cases", {})
    if len(cases.get("positive", [])) != 5 or len(cases.get("negative", [])) != 3:
        err("plugin.json review.test_cases: need exactly 5 positive and 3 negative cases")
    for case in cases.get("positive", []):
        for key in ("description", "prompt", "tools_triggered", "expected_behavior"):
            if not case.get(key):
                err(f"plugin.json positive case '{case.get('description')}': {key} required")
    onboarding = oai.get("onboardingSkill")
    if onboarding and not (ROOT / onboarding.removeprefix("./")).is_file():
        err("plugin.json onboardingSkill: file missing")
    for forbidden in ("apps", "hooks"):
        if forbidden in oai:
            err(f"plugin.json: '{forbidden}' blocks OpenAI ZIP submission")


def check_directory_files() -> None:
    """Claude directory rules: no OS junk, non-image files < 256 KiB, <= 512 files."""
    count = 0
    for p in files():
        count += 1
        rel = p.relative_to(ROOT)
        if p.name in {".DS_Store", "Thumbs.db", "desktop.ini"} or "__MACOSX" in rel.parts:
            err(f"{rel}: OS system file blocks Claude directory submission")
        if p.suffix.lower() not in IMAGE_EXT and p.stat().st_size > 256 * 1024:
            err(f"{rel}: over 256 KiB")
        if p.suffix.lower() in {".zip", ".ico", ".pdf", ".mcpb", ".dxt"}:
            err(f"{rel}: binary type is held by the Claude directory; do not commit it")
    if count > 512:
        err(f"repository has {count} files (Claude directory limit 512)")
    readme = (ROOT / "README.md").read_text(encoding="utf-8") if (ROOT / "README.md").is_file() else ""
    prose = re.sub(r"```.*?```", "", readme, flags=re.S)
    if len(prose.split()) < 40:
        err("README.md: needs at least 40 words outside code blocks")
    if not (ROOT / "LICENSE").is_file():
        err("LICENSE missing")


def main() -> int:
    require = "--require-schema" in sys.argv
    try:
        import yaml  # type: ignore
    except ImportError:
        print("error: PyYAML is required (pip install pyyaml)", file=sys.stderr)
        return 1
    check_all_json()
    check_yaml_files(yaml)
    schema_check(require)
    check_manifests()
    check_skills(yaml)
    check_rules(yaml)
    check_directory_files()
    for w in warnings:
        print(f"warning: {w}")
    for e in errors:
        print(f"error: {e}")
    print(f"{'FAILED' if errors else 'OK'}: {len(errors)} errors, {len(warnings)} warnings")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
