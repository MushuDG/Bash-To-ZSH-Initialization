# PiInitialization Script

## Description

The `PiInitialization` script is designed to streamline the setup process for a Raspberry Pi, including password change, system updates, installation of essential packages, and configuration of the Zsh shell with Oh My Zsh and Powerlevel10k theme.

## Features

- Change user password.
- Update and upgrade system packages.
- Install Git, Zsh, wget, curl, and neofetch.
- Set up Oh My Zsh with default configuration.
- Clone Powerlevel10k, Zsh-autosuggestions, and Zsh-syntax-highlighting.
- Remove existing Zsh configuration files.
- Download and apply new Zsh configuration files.
- Optional: Set Zsh as the default shell.

## Compatible Hardware
* Raspberry Pi 3 Model B+
* [RaspberryPiOS 2022-04-04 - Debian 11 - Linux Kernel 5.15](https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2022-04-07/2022-04-04-raspios-bullseye-armhf-lite.img.xz)
* Bash Shell

## Setup
Clone the project using the following git command:
```bash
git clone https://github.com/MushuDG/PiInitialization.git
```
Assign the appropriate permissions with the chmod command:
```bash
chmod -R 740 ./PiInitialization/

```
## Installation
Run install script:
```
cd ./PiInitialization
./install.sh
```

## Notes

- Make sure to review the script before execution.
- The script assumes an internet connection for package installation.
- Optionally set Zsh as the default shell for the current user.

## License

This script is released under the [GPL-3.0 license](https://raw.githubusercontent.com/MushuDG/PiInitialization/main/LICENSE).
