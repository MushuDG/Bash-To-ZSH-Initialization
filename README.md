# Bash-To-ZSH-Initialization

## 📝 Description

**Bash-To-ZSH-Initialization** streamlines the transition from **Bash** to **Zsh** by automating the install of **Zsh**, **Oh My Zsh**, **Powerlevel10k**, and a curated set of plugins + tools on macOS and Linux.

## 🚀 What the script does

- **Detects your platform / package manager**:
  - **macOS** → Homebrew (`brew`)
  - **Arch / Manjaro** → Pacman (`pacman`)
  - **Debian / Ubuntu** → APT (`apt-get`)
- **Updates repositories** and installs common CLI tools (quietly; logs printed only on errors).
- **Installs Oh My Zsh** in **non-interactive mode** (it does **not** auto-switch to zsh and does **not** change your default shell during install).
- **Installs Zsh plugins using the best method per platform**:
  - packaged when available (with an Oh My Zsh wrapper so `plugins=(...)` works)
  - otherwise via **git clone** (and updates on re-run)
- **Copies your template configs** from `./config` to:
  - `~/.zshrc`
  - `~/.p10k.zsh`
- **Patches `~/.zshrc` after copy** (the repo templates are not meant to be edited manually):
  - enables **Pywal** lines if you answered “Yes”
  - replaces a single `fastfetch`/`neofetch` line with an **auto-select block**
  - enforces a consistent `plugins=(...)` order
  - makes `ls` safe: uses `lsd` if installed, otherwise falls back to `ls -la`
- **Optionally sets Zsh as your default shell** (`chsh`) at the end.
- **Cleans up** the cloned directory at the end (see notes).

## ⚙️ Packages installed

Base packages (installed on all supported platforms):

- `bat` *(Debian/Ubuntu may expose it as `batcat`; the script creates a `bat` symlink when needed)*
- `btop`, `curl`, `fzf`, `git`, `lsd`, `neovim`, `wget`, `zsh`

Fetch tool:

- **macOS / Arch**: `fastfetch`
- **Debian / Ubuntu**: `neofetch` *(and the script can still use `fastfetch` if you install it yourself later)*

> **Ubuntu 24.04+ note**: the `thefuck` APT package is currently broken on some setups (Python `distutils` removal), so the script does **not** install it there by default. See “Troubleshooting”.

## 🔌 Plugins enabled in `~/.zshrc`

The script enforces a consistent plugin order (after config copy). Enabled plugins include:

- `git`
- `zsh-autosuggestions`
- `zsh-syntax-highlighting`
- `you-should-use`
- `zsh-bat`
- `zsh-z` *(provides the `z` command)*
- `fzf`
- `extract`
- `command-not-found`
- `thefuck` *(when available / stable on your platform; see Troubleshooting)*

## ✅ Tested platforms

- **macOS** (Homebrew required)
- **Arch Linux** (Pacman)
- **Debian** (APT)
- **Ubuntu** (APT)
- Works well in **VMware** and **WSL** as long as the package manager is supported.

## 🛠️ Setup

Clone the project (recommended in `/tmp` because the script can remove the folder during cleanup):

```bash
cd /tmp
git clone https://github.com/MushuDG/Bash-To-ZSH-Initialization.git
cd Bash-To-ZSH-Initialization
chmod +x install.sh
```

## 🚀 Installation

```bash
./install.sh
```

## 🧩 Troubleshooting / Notes

- **Back up your current config** if you have one: the script overwrites `~/.zshrc` and `~/.p10k.zsh`.
- **macOS**: you must install **Homebrew** first.
- **Ubuntu 24.04+**: if you see errors with `thefuck`, remove it from `plugins=(...)` in `~/.zshrc` or install it via another method (pipx, pip, etc.).
- The script needs an **internet connection** (packages + GitHub).
- Cleanup may remove the cloned folder. Keep the repo in a disposable location (like `/tmp`) when running the installer.

## Fonts

Powerlevel10k doesn't require custom fonts but can take advantage of them if they are available.
It works well with [Nerd Fonts](https://github.com/ryanoasis/nerd-fonts),
[Source Code Pro](https://github.com/adobe-fonts/source-code-pro),
[Font Awesome](https://fontawesome.com/), [Powerline](https://github.com/powerline/fonts), and even
the default system fonts. The full choice of style options is available only when using
[Nerd Fonts](https://github.com/ryanoasis/nerd-fonts).

👇 **Recommended font**: Meslo Nerd Font patched for Powerlevel10k. 👇

### <a name='recommended-meslo-nerd-font-patched-for-powerlevel10k'></a><a name='font'></a>Meslo Nerd Font patched for Powerlevel10k

Gorgeous monospace font designed by Jim Lyles for Bitstream, customized by the same for Apple,
further customized by André Berg, and finally patched by yours truly with customized scripts
originally developed by Ryan L McIntyre of Nerd Fonts. Contains all glyphs and symbols that
Powerlevel10k may need. Battle-tested in dozens of different terminals on all major operating
systems.

#### Automatic font installation

If you are using iTerm2 or Termux, `p10k configure` can install the recommended font for you.
Simply answer `Yes` when asked whether to install *Meslo Nerd Font*.

If you are using a different terminal, proceed with manual font installation. 👇

#### Manual font installation

1. Download these four ttf files:
   - [MesloLGS NF Regular.ttf](
       https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf)
   - [MesloLGS NF Bold.ttf](
       https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf)
   - [MesloLGS NF Italic.ttf](
       https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf)
   - [MesloLGS NF Bold Italic.ttf](
       https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf)

## 📄 License

This project is released under the [MIT license](https://raw.githubusercontent.com/MushuDG/Bash-To-ZSH-Initialization/main/LICENSE).
