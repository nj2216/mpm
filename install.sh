#!/bin/bash
set -e

REPO="https://raw.githubusercontent.com/<YOUR-GITHUB-USERNAME>/mpm/main"
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

# 3. Ensure ~/.local/bin is in PATH for bash & zsh
add_path() {
    local rc="$1"
    local line='export PATH="$HOME/.local/bin:$PATH"'
    if [ -f "$rc" ] && ! grep -q "$HOME/.local/bin" "$rc"; then
        echo -e "\n# Added by mpm installer\n$line" >> "$rc"
        echo -e "\033[32m✔\033[0m Added ~/.local/bin to $rc"
    fi
}

add_path "$HOME/.bashrc"
add_path "$HOME/.zshrc"

echo -e "\033[32m✔ Installation complete!\033[0m"
echo ""
echo "To get started:"
echo "  1. Refresh your shell:  source ~/.bashrc  (or source ~/.zshrc)"
echo "  2. Update index:        mpm update"
echo "  3. Install a package:   mpm install <package-name>"