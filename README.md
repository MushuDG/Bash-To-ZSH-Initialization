# Bash-To-ZSH-Initialization Script

## 📝 Description

The "Bash-To-ZSH-Initialization" script aims to streamline the transition from the Bash shell environment to Zsh. It automates the process of installing and configuring Zsh along with commonly used plugins and configurations, providing an enhanced and personalized user experience for Zsh users.

## 🚀 Features 
✔️ **Detect Package Manager**: Detect the package manager being used and execute appropriate actions.

✔️ **Update and Install Packages**: Update and install necessary packages using the appropriate package manager.

✔️ **Install Oh My Zsh**: Install the Oh My Zsh framework for Zsh customization.

✔️ **Clone Zsh Plugins**: Clone Zsh plugins from GitHub repositories to enhance Zsh functionality.

✔️ **Remove Existing Zsh Configurations**: Remove existing Zsh configuration files if present.

✔️ **Download and Move Configuration Files**: Download new Zsh configuration files and move them to appropriate locations.

✔️ **Clean Up**: Clean up temporary files and directories after completion.

✔️ **Set Zsh as Default Shell**: Prompt the user to set Zsh as the default shell and execute the change.

## ⚙️ Plugins installed

These plugins enhance the functionality of Zsh by providing various features such as command auto-suggestion, advanced syntax highlighting, improved file system navigation, and more.

* git
* zsh-autosuggestions
* zsh-syntax-highlighting
* you-should-use
* zsh-bat
* thefuck
* z
* fzf
* extract
* command-not-found


## 🛠️ Compatible Hardware

Tested successfully on the following systems:

✔️ [RaspberryPiOS 2022-04-04 - Debian 11 - Linux Kernel 5.15](https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf-lite.img.xz)

✔️ MacOS

✔️ WSL: Arch Linux


## 🛠️ Setup
Clone the project using the following git command:
```bash
cd /tmp
git clone https://github.com/MushuDG/Bash-To-ZSH-Initialization.git
```
Assign the appropriate permissions with the chmod command:
```bash
chmod -R 740 ./Bash-To-ZSH-Initialization/
```
## 🚀 Installation
Run install script:
```
cd ./Bash-To-ZSH-Initialization
./install.sh
```

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

## ⚠️ Notes

- Make sure to review the script before execution.
- The script assumes an internet connection for package installation.
- Optionally set Zsh as the default shell for the current user.

## 📄 License

This script is released under the [MIT license](https://raw.githubusercontent.com/MushuDG/Bash-To-ZSH-Initialization/main/LICENSE).
