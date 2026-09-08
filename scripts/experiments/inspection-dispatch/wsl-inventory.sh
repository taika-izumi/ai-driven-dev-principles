uname -s
for taskcmd in claude bwrap socat node pwsh; do
  taskpath=$(command -v "$taskcmd" 2>/dev/null)
  if [ -n "$taskpath" ]; then printf '%s=%s\n' "$taskcmd" "$taskpath"; else printf '%s=missing\n' "$taskcmd"; fi
done
if [ -x "$HOME/.local/bin/claude" ]; then "$HOME/.local/bin/claude" --version; else printf 'home_claude=missing\n'; fi