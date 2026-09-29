#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/nj2216/mpm/main"
BIN_DIR="$HOME/.local/bin"

echo -e "\033[1;36m==>\033[0m Installing \033[1mmpm\033[0m (Modern Package Manager)..."

# 1. Create target directories
mkdir -p "$BIN_DIR"

# 2. Download the binary
if command -v curl &>/dev/null; then
    curl -fsSL "$REPO/bin/mpm" -o "$BIN_DIR/mpm"
elif command -v wget &>/dev/null; then
    wget -qO "$BIN_DIR/mpm" "$REPO/bin/mpm"
else
    echo "Error: Need curl or wget to install mpm." >&2
    exit 1
fi

chmod +x "$BIN_DIR/mpm"

# 3. Configure shell startup idempotently without pollution
configure_shell() {
    local rc="$1"
    [ -f "$rc" ] || return 0

    local START_MARKER="# >>> mpm initialize >>>"
    local END_MARKER="# <<< mpm initialize <<<"

    # Only add if the marker block doesn't already exist
    if ! grep -q "$START_MARKER" "$rc" 2>/dev/null; then
        cat << 'EOF' >> "$rc"

# >>> mpm initialize >>>
export PATH="$HOME/.local/bin:$PATH"
command -v mpm >/dev/null 2>&1 && eval "$(mpm shell-hook)"
# <<< mpm initialize <<<
EOF
        echo -e "\033[32m✔\033[0m Added clean configuration block to $rc"
    fi
}

configure_shell "$HOME/.bashrc"
[ -f "$HOME/.zshrc" ] && configure_shell "$HOME/.zshrc"

echo -e "\033[32m✔ Installation complete!\033[0m"
echo ""
echo "To get started:"
echo "  1. Refresh your shell:  source ~/.bashrc  (or source ~/.zshrc)"
echo "  2. Update index:        mpm update"
echo "  3. Install a package:   mpm install <package-name>"