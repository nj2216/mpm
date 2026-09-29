# ⚡ MPM (Modern Package Manager)

A rootless, parallel, user-space package manager for Debian/Ubuntu environments inspired by `uv`.

- 🚀 **Zero sudo required**: Install standard apt packages into `~/.local`.
- ⚡ **Blazing Fast**: Multi-threaded parallel downloads with an interactive terminal UI.
- 📦 **Isolated Profiles**: Create throwaway virtual environments like Conda (`mpm env create myenv`).
- 🔧 **ELF Auto-Patching**: Automatically runs `patchelf` to fix dynamic runpaths and shared libraries.
- 🧹 **Clean Removal**: SQLite tracking engine cleanly tracks and deletes uninstalled files.

## 📦 Installation

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR-GITHUB-USERNAME>/mpm/main/install.sh | bash
```

## 🚀 Quickstart

```bash
# Update repository indices
mpm update

# Search for packages
mpm search ripgrep

# Install a package (runs parallel download + patchelf)
mpm install ripgrep

# List your installed user packages
mpm list

# Remove a package cleanly
mpm remove ripgrep
```

## 🧪 Isolated Environments

```bash
# Create an environment
mpm env create dev-env

# Install into that environment only
mpm -n dev-env install python3-pip

# Run a command inside the environment
mpm run dev-env python3 --version

# Or activate it in your shell
source ~/.local/share/mpm/environments/dev-env/activate
```

---

## 💡 How It Works Under the Hood

Unlike traditional package managers that demand root access to mutate `/usr`, `mpm` creates a completely unprivileged user-space overlay:
1. **Resolution**: Directs `apt-get` to read from an unprivileged status file and custom package lists using non-root configurations.
2. **Parallel Downloader**: Uses a multi-threaded Python engine with non-blocking I/O to fetch `.deb` archives simultaneously.
3. **Database Tracking**: Analyzes the contents of each `.deb` using a local SQLite engine (`~/.local_apt/mpm_db.sqlite`) before unpacking, keeping an audit trail of file ownership to ensure clean uninstalls.
4. **Binary Patching**: Fixes hardcoded Linux library paths (`RPATH` and `RUNPATH`) on extracted ELF binaries so they can find their dynamic libraries inside `~/.local/lib` without system-wide library pollution.

---

## 🤝 Acknowledgements & Prior Art

`mpm` was inspired by and built on top of brilliant tools across the Linux, Python, and systems engineering ecosystems:

- **[Astral / uv](https://github.com/astral-sh/uv)** — The design benchmark for fast package managers. The UI spinner, active download bars, and responsive terminal feedback in `mpm` are directly modeled after `uv`'s terminal aesthetics.
- **[Debian APT & dpkg](https://wiki.debian.org/Teams/Apt)** — For establishing one of the most reliable dependency management databases and packaging standards in computing history.
- **[Nix](https://nixos.org/) & [Homebrew](https://brew.sh/)** — For pioneering the philosophy of user-owned package installations without needing `sudo` or modifying the host root partition.
- **[patchelf (NixOS)](https://github.com/NixOS/patchelf)** — An indispensable utility that makes self-contained ELF executable relocation and dynamic linker rewriting possible on modern Linux systems.
- **[Conda](https://docs.conda.io/)** — For the intuition behind prefix-based isolated environments (`mpm env create`).

---

## 🛠️ Requirements & Compatibility

- **OS**: Ubuntu (20.04 LTS, 22.04 LTS, 24.04 LTS) and modern Debian-based distributions.
- **Dependencies**: 
  - Standard utilities: `bash`, `python3` (3.7+), `dpkg`, `apt`, `wget` (or `curl`).
  - *Optional (recommended)*: `patchelf` (can be installed rootlessly via `mpm install patchelf`).
- **Permissions**: **Zero root / sudo required**. Works seamlessly on shared HPC clusters, university lab machines, and restricted CI runners.

---

## 🤝 Contributing

Contributions, issues, and feature requests are welcome!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

```text
MIT License

Copyright (c) 2025 Jeevan N

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```