#!/bin/bash
################################################################################
# General information
################################################################################
# Author:               MushuDG
# Project:              Bash-To-ZSH-Initialization
# File:                 install.sh
# Creation date:        18.03.2024
# Description:          Script managing the initialization process for
#                       transitioning from Bash to Zsh shell environment.
################################################################################

set -euo pipefail
IFS=$'\n\t'

################################################################################
# Function
################################################################################
################################################################################
# Name:         spinner
# Goal:         Display a spinner animation while a process is running
# Parameters:   - None
# Returns:      - None
################################################################################
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr=('⣷' '⣯' '⣟' '⡿' '⢿' '⣻' '⣽' '⣾')
    local i=0 n=${#spinstr[@]}
    tput civis
    trap 'tput cnorm' EXIT INT TERM
    while kill -0 "$pid" 2>/dev/null; do
        printf " [%s]  " "${spinstr[i]}"
        i=$(( (i + 1) % n ))
        sleep "$delay"
        printf "\b\b\b\b\b\b"
    done
    tput cnorm
    printf "    \b\b\b\b"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         verify_root_permissions
# Goal:         Verifying if the user have the right permissions
# Parameters:   - None
# Returns:      - None
################################################################################
verify_root_permissions(){
    if ! command -v sudo &>/dev/null; then
        echo "This script requires sudo or root privileges."
        exit 1
    fi
    if [[ $EUID -ne 0 ]]; then
        echo "Some tasks need root privileges. Asking for sudo password..."
        sudo -v
    fi
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         ask_for_pywal
# Goal:         Prompt the user if they are using pywal
# Parameters:   - None
# Returns:      - None
################################################################################
ask_for_pywal() {
    echo "Are you using Pywal? [Y/n] (default: N)"
    read -r use_pywal
    if [[ $use_pywal == "Y" || $use_pywal == "y" ]]; then
        sed -i'.bak' -e '6s/^.//' -e '9s/^.//' -e '12s/^.//' ./config/.zshrc
        echo "Pywal configurations applied."
    else
        echo "Pywal configurations not applied."
    fi
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         update_and_install_packages
# Goal:         Update and install packages using the appropriate package manager
# Parameters:   - update_command: Command to update packages
#               - install_command: Command to install packages
#               - packages: Array of packages to install
# Returns:      - None
################################################################################
update_and_install_packages() {
    local update_command="$1"
    local install_command="$2"
    shift 2
    local packages=("$@")
    echo -ne "Updating packages..."
    $update_command >/dev/null 2>&1 &
    spinner; echo -ne " [✓]\n"

    echo -ne "Installing packages..."
    $install_command "${packages[@]}" >/dev/null 2>&1 &
    spinner; echo -ne " [✓]\n"

    # Record installed names
    for p in "${packages[@]}"; do
        INSTALLED_PACKAGES[$p]="$PACKAGE_MANAGER"
    done
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         detect_package_manager
# Goal:         Detect the package manager and execute appropriate actions
# Parameters:   - None
# Returns:      - None
################################################################################
detect_package_manager() {
    PACKAGE_MANAGER=""
    declare -gA INSTALLED_PACKAGES

    # Common packages across systems
    BASE_PKGS=(btop curl fzf git neofetch neovim wget zsh)

    if command -v pacman &>/dev/null; then
        PACKAGE_MANAGER="pacman"
        update_and_install_packages "sudo pacman -Syu --noconfirm" \
                                    "sudo pacman -S --noconfirm" \
                                    bat thefuck "${BASE_PKGS[@]}"

    elif command -v brew &>/dev/null; then
        PACKAGE_MANAGER="brew"
        update_and_install_packages "brew update" \
                                    "brew install" \
                                    bat thefuck "${BASE_PKGS[@]}"

    elif command -v apt &>/dev/null; then
        PACKAGE_MANAGER="apt"

        # Detect Ubuntu vs Debian
        local distro
        distro="$(. /etc/os-release && echo "$ID")"

        if [[ $distro == "ubuntu" ]]; then
            # Ubuntu: bat -> batcat
            APT_PKGS=(batcat python3-thefuck "${BASE_PKGS[@]}")
            update_and_install_packages "sudo apt update" \
                                        "sudo apt install -y" "${APT_PKGS[@]}"
            INSTALLED_PACKAGES[bat]="batcat"
            INSTALLED_PACKAGES[thefuck]="python3-thefuck"
            # Symlink to uniform command names
            if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
                sudo ln -sf "$(command -v batcat)" /usr/local/bin/bat
            fi
            if command -v python3-thefuck &>/dev/null && ! command -v thefuck &>/dev/null; then
                sudo ln -sf "$(command -v python3-thefuck)" /usr/local/bin/thefuck
            fi
        else
            # Debian: bat is bat
            update_and_install_packages "sudo apt update" \
                                        "sudo apt install -y" \
                                        bat thefuck "${BASE_PKGS[@]}"
        fi

    elif command -v pkg &>/dev/null; then
        PACKAGE_MANAGER="pkg"
        update_and_install_packages "pkg upgrade -y" \
                                    "pkg install -y" \
                                    bat thefuck "${BASE_PKGS[@]}"

    else
        echo "Unsupported package manager."
        exit 1
    fi
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         install_oh_my_zsh
# Goal:         Install Oh My Zsh framework
# Parameters:   - None
# Returns:      - None
################################################################################
install_oh_my_zsh() {
    echo -ne "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" </dev/null >/dev/null 2>&1 &
    spinner; echo -ne " [✓]\n"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         clone_plugins
# Goal:         Clone Zsh plugins from GitHub repositories
# Parameters:   - None
# Returns:      - None
################################################################################
clone_plugins() {
    local plugins=(
        "https://github.com/zsh-users/zsh-autosuggestions.git"
        "https://github.com/MichaelAquilina/zsh-you-should-use.git"
        "https://github.com/fdellwing/zsh-bat.git"
        "https://github.com/zsh-users/zsh-syntax-highlighting.git"
        "https://github.com/agkozak/zsh-z.git"
    )
    echo -ne "Cloning plugins..."
    for plugin in "${plugins[@]}"; do
        git clone --depth=1 "$plugin" \
            "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/$(basename "$plugin" .git)" >/dev/null 2>&1 &
        spinner
    done
    echo -ne " [✓]\n"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         remove_zsh_config
# Goal:         Remove existing Zsh configuration files
# Parameters:   - None
# Returns:      - None
################################################################################
remove_zsh_config() {
    [ -e "$HOME/.zshrc" ] && rm -f "$HOME/.zshrc"
    [ -e "$HOME/.p10k.zsh" ] && rm -f "$HOME/.p10k.zsh"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         moving_config_files
# Goal:         Download new Zsh configuration files and move them to appropriate locations
# Parameters:   - None
# Returns:      - None
################################################################################
moving_config_files() {
    cp -r "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh"}/plugins/extract" \
          "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/extract" >/dev/null 2>&1 &
    spinner
    cp -r "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh"}/plugins/command-not-found" \
          "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/plugins/command-not-found" >/dev/null 2>&1 &
    spinner
    echo -ne "Downloading configuration files..."
    cp ./config/.p10k.zsh "$HOME/.p10k.zsh" >/dev/null 2>&1 &
    spinner
    cp ./config/.zshrc "$HOME/.zshrc" >/dev/null 2>&1 &
    spinner
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "${ZSH_CUSTOM:-"$HOME/.oh-my-zsh/custom"}/themes/powerlevel10k" >/dev/null 2>&1 &
    spinner
    echo -ne " [✓]\n"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         clean_up
# Goal:         Clean up temporary files and directories
# Parameters:   - None
# Returns:      - None
################################################################################
clean_up() {
    echo -ne "Cleaning up..."
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    rm -rf "$script_dir" >/dev/null 2>&1 &
    spinner; echo -ne " [✓]\n"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         set_zsh_default
# Goal:         Set Zsh as the default shell
# Parameters:   - None
# Returns:      - None
################################################################################
set_zsh_default() {
    echo "Set Zsh as the default shell? [Y/n] (default: Y)"
    read -r set_zsh_default
    set_zsh_default="${set_zsh_default:-Y}"
    if [[ $set_zsh_default == "N" || $set_zsh_default == "n" ]]; then
        echo "Zsh is not set as the default shell."
    else
        echo "Changing default shell..."
        local zsh_path
        zsh_path="$(command -v zsh)"
        chsh -s "$zsh_path"
        echo "Zsh is now the default shell."
        clear
        exec "$zsh_path"
    fi
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         show_summary
# Goal:         Display installed packages summary
# Parameters:   - None
# Returns:      - None
################################################################################
show_summary() {
    echo
    echo "================ Installation summary ================"
    echo "Package manager used: $PACKAGE_MANAGER"
    for pkg in "${!INSTALLED_PACKAGES[@]}"; do
        echo " - $pkg  →  installed as '${INSTALLED_PACKAGES[$pkg]}'"
    done
    echo "======================================================"
}

################################################################################
# Function
################################################################################
################################################################################
# Name:         main
# Goal:         Main function orchestrating the transition from Bash to Zsh
# Parameters:   - None
# Returns:      - None
################################################################################
main() {
    verify_root_permissions
    ask_for_pywal
    detect_package_manager
    install_oh_my_zsh
    clone_plugins
    remove_zsh_config
    moving_config_files
    clean_up
    set_zsh_default
    show_summary
}

# Run the main function
main
