# MPM (Modern Package Manager)

MPM is a lightweight, rootless user-space package manager for Debian and Ubuntu systems. It allows you to download and extract standard `.deb` packages into isolated, project-local environments—much like Python's `venv` or Conda, but for system binaries and libraries.

Downloads are fetched in parallel with an active terminal progress display inspired by Astral's `uv`. No `sudo` access is needed, and no changes are made to your system root, `~/.local`, or shell startup scripts (`~/.bashrc`).

<!-- SCREENSHOT / DEMO GIF PLACEHOLDER -->
<!-- Replace the URL below with a recording of mpm in action (e.g., using VHS or asciinema) -->
<p align="center">
  <img src="imgs/he" alt="MPM Terminal Demo" width="750" />
</p>

---

## Key Highlights

- **Complete Isolation**: Packages install into a local `./.mpm` directory (or a named global profile). It leaves your underlying system, terminal environment variables, and `~/.bashrc` untouched.
- **Parallel Fetching**: Replaces sequential downloads with a multi-threaded parallel downloader that tracks transfer speeds, package totals, and progress bars.
- **No Administrative Rights Required**: Useful on managed servers, university computing clusters, restricted containers, and CI pipelines where you do not have root access.
- **Safe Runpath Handling**: Applies `$ORIGIN`-relative runpaths using `patchelf` so binaries find their shared libraries without contaminating host tools.
- **Straightforward Activation**: Run commands on-the-fly using `mpm run <cmd>`, or source the environment's `bin/activate` script to drop into a dedicated shell session.

---

## Installation

You can install `mpm` by cloning the repository or running the bootstrap script:

```bash
curl -fsSL https://raw.githubusercontent.com/<YOUR-GITHUB-USERNAME>/mpm/main/install.sh | bash
```

Make sure `~/.local/bin` is present in your `$PATH`.

Alternatively, copy `bin/mpm` directly into any directory on your `$PATH` and ensure it is marked executable:

```bash
git clone https://github.com/<YOUR-GITHUB-USERNAME>/mpm.git
cd mpm
chmod +x bin/mpm
cp bin/mpm ~/.local/bin/
```

---

## Usage

### 1. Synchronize Package Lists

Before installing packages, fetch and update the remote indices:

```bash
mpm update
```

<!-- SCREENSHOT PLACEHOLDER: MPM UPDATE -->
<!-- <p align="center"><img src="docs/screenshots/update.png" alt="mpm update output" width="650" /></p> -->

### 2. Working in a Project Directory (Default)

Running `install` inside any directory automatically creates a `./.mpm` environment right where you are:

```bash
# Search for packages across Ubuntu pockets
mpm search ffmpeg

# Install ffmpeg and all required dependencies locally
mpm install ffmpeg
```

<!-- SCREENSHOT PLACEHOLDER: MPM INSTALL (UV PROGRESS) -->
<!-- <p align="center"><img src="docs/screenshots/install.png" alt="mpm parallel download" width="650" /></p> -->

Once installed, use the binary directly with `mpm run`:

```bash
mpm run ffmpeg -version
```

Or activate the environment in your current shell:

```bash
source .mpm/activate

# Now ffmpeg is directly in your PATH
ffmpeg -version

# Return to your standard shell
deactivate
```

### 3. Named Global Environments

You can also create named profiles stored in `~/.local/share/mpm/environments/` by passing the `-n` or `--env` flag:

```bash
# Install packages into a shared environment called "tools"
mpm -n tools install ripgrep jq

# Run an executable directly from the named profile
mpm -n tools run ripgrep --version

# Or activate it
source ~/.local/share/mpm/environments/tools/activate
jq --version
deactivate
```

---

## CLI Reference

```text
Usage: mpm [-v|--verbose] [-n <env-name>] <command> [arguments]

Commands:
  update                  Download and update repository indices
  search <query>          Search package catalogs for matching terms
  install <package>       Resolve, fetch, and extract packages into the environment
  run <cmd> [args...]     Execute a command with the environment paths loaded
  init                    Generate an empty environment scaffold in ./.mpm
  clean                   Clear downloaded .deb archives from the cache directory
```

---

## Technical Details

Traditional package managers expect write access to root directories such as `/usr`, `/lib`, and `/etc`. MPM approaches user installations through non-root mechanisms:

1. **Resolution**: Directs `/usr/bin/apt-get` to evaluate dependencies against a local, isolated status file and custom package indices, keeping your system's package database clean.
2. **Parallel Retrieval**: Download tasks are queued across a multi-threaded pool with dynamic ANSI cursor rendering to display live throughput and completion statistics.
3. **Prefix Extraction**: Packages are unpacked strictly within the environment folder.
4. **Relocation & RPATH**: If `patchelf` is present on the host, MPM embeds `$ORIGIN`-relative runpaths into compiled ELF binaries and libraries. This ensures dependencies resolve from the local folder first without requiring a globally exported `LD_LIBRARY_PATH`.
5. **Session Scoping**: The generated `activate` script preserves original environment variables (`PATH`, `PS1`, `LD_LIBRARY_PATH`) so exiting with `deactivate` restores your shell to its original state.

---

## Requirements

- **Operating System**: Modern Debian or Ubuntu installations (tested on 20.04 LTS, 22.04 LTS, 24.04 LTS, and 26.04).
- **Core Dependencies**: Standard utilities available on most base images: `bash`, `python3` (3.7+), `dpkg`, `apt`, `wget` (or `curl`).
- **Optional**: `patchelf` (recommended for dynamic runpath rewriting).

---

## Acknowledgements

MPM draws ideas and design patterns from tools across the open source community:

- **Astral uv**: The progress indicators and visual layout for parallel transfers were modeled after the responsive user experience found in `uv`.
- **Debian APT & dpkg**: The dependency solver, archive structure, and metadata standards established by Debian.
- **Python venv**: The design for prefix scoping, path overrides, and activation/deactivation routines.
- **Nix and Homebrew**: Inspiration for non-root prefix isolation and relocatable builds.
- **NixOS patchelf**: The utility enabling binary relocation on Linux systems.

---

## Contributing

Contributions and bug reports are welcome:

1. Fork the repository.
2. Create a dedicated topic branch (`git checkout -b feature/my-feature`).
3. Commit your changes (`git commit -m 'Add support for custom mirrors'`).
4. Push to the branch (`git push origin feature/my-feature`).
5. Open a Pull Request.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
