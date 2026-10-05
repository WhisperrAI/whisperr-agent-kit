#!/usr/bin/env bash
# Build the OpenAI plugin upload ZIP (ChatGPT + Codex plugin directory).
#
# The package uses the portable Agent Plugins layout that OpenAI documents:
# plugin.json (with extensions.com.openai), mcp.json, skills/, assets/.
# Claude- and Cursor-only files stay out of the ZIP.
# Output: dist/whisperr-openai-plugin.zip
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/dist"
stage="$out/stage"
zipfile="$out/whisperr-openai-plugin.zip"

rm -rf "$stage" "$zipfile"
mkdir -p "$stage"

cp "$root/plugin.json" "$root/mcp.json" "$root/README.md" "$root/LICENSE" "$stage/"
cp -R "$root/skills" "$root/assets" "$stage/"
find "$stage" \( -name '.DS_Store' -o -name '__MACOSX' \) -prune -exec rm -rf {} +

# Fail early if a referenced asset or skill is missing from the package.
python3 - "$stage" <<'PY'
import json, sys, pathlib
stage = pathlib.Path(sys.argv[1])
oai = json.loads((stage / "plugin.json").read_text())["extensions"]["com.openai"]
paths = [oai["interface"][k] for k in ("logo", "composerIcon")] + [oai.get("onboardingSkill", "./plugin.json")]
missing = [p for p in paths if not (stage / p.removeprefix("./")).is_file()]
if missing:
    sys.exit(f"missing in package: {missing}")
if not list(stage.glob("skills/*/SKILL.md")):
    sys.exit("no skills in package")
PY

(cd "$stage" && zip -q -X -r "$zipfile" .)
rm -rf "$stage"
echo "built $zipfile"
unzip -l "$zipfile"
