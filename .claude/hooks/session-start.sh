#!/bin/bash
# Prepares the watch skill (.claude/skills/watch, from bradautomates/claude-video)
# in Claude Code cloud sessions. Python 3.10+ and ffmpeg/ffprobe ship with the
# image; yt-dlp (latest) and Deno (YouTube JS runtime) are installed here.
set -euo pipefail

if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"
export PATH="$LOCAL_BIN:$PATH"

# yt-dlp: watch supports only the latest release, so upgrade on every start.
if command -v uv >/dev/null 2>&1; then
  uv tool install --upgrade --quiet "yt-dlp[default,curl-cffi]"
else
  python3 -m pip install --user --upgrade --quiet --break-system-packages "yt-dlp[default,curl-cffi]"
fi

# Deno: needed by yt-dlp for YouTube.
if ! command -v deno >/dev/null 2>&1; then
  npm install -g --silent deno
fi

if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"$LOCAL_BIN:\$PATH\"" >> "$CLAUDE_ENV_FILE"
fi

# ~/.config/watch does not survive between sessions. With GEMINI_API_KEY set in
# the environment, select the Gemini engine so watch skips its first-run setup.
if [ -n "${GEMINI_API_KEY:-}" ]; then
  python3 "$CLAUDE_PROJECT_DIR/.claude/skills/watch/scripts/setup.py" --engine gemini >/dev/null \
    || echo "watch: Gemini engine setup failed" >&2
fi

echo "watch deps: yt-dlp $(yt-dlp --version), $(deno --version | head -1), $(ffmpeg -version | head -1 | cut -d' ' -f1-3)" >&2
