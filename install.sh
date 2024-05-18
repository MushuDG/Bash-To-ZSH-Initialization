#!/bin/bash
################################################################################
# General informations
################################################################################
# Author:               MushuDG
# Project:              Bash-To-ZSH-Initialization
# File:                 install.sh
# Creation date:        18.03.2024
# Description:          Script managing the initialization process for
#                       transitioning from Bash to Zsh shell environment.
################################################################################

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
    # Get the process ID of the background process
    local pid=$!

    # Delay for spinner animation
    local delay=0.1

    # Spinner characters
    local spinstr='|/-\'

    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"           # Print spinner
        local spinstr=$temp${spinstr%"$temp"} # Update spinner
        sleep $delay                          # Wait for animation delay
        printf "\b\b\b\b\b\b"                 # Move cursor back to overwrite spinner
    done
    printf "    \b\b\b\b" # Clear spinner after completion
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
    # Check if the user is root
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run with root privileges. Please run with sudo."
        echo "Example: sudo ./install.sh"
        exit 1
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
    echo "Are you using Pywal? [Y/n] (default: N)" # asks the user if they are using pywal
    read use_pywal
    if [[ $use_pywal == "Y" || $use_pywal == "y" ]]; then
        sed -i'.bak' -e '9s/^.//' -e '12s/^.//' -e '15s/^.//' ./config/.zshrc
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
    local update_command="$1"  # Command to update packages
    local install_command="$2" # Command to install packages
    local packages=("${@:3}")  # Array of packages to install

    echo -ne "Updating packages..." # Display update process
    $update_command >/dev/null 2>&1 & # Execute update command in background
    spinner                                     # Call spinner function to display animation
    echo -ne " [✓] Updating packages... Done\n" # Update status after completion

    echo -ne "Installing packages..." # Display installation process
    $install_command "${packages[@]}" >/dev/null 2>&1 & # Execute install command in background
    spinner                                       # Call spinner function to display animation
    echo -ne " [✓] Installing packages... Done\n" # Update status after completion
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
    if command -v pacman &>/dev/null; then
        update_and_install_packages "sudo pacman -Syu --noconfirm" "sudo pacman -S --noconfirm" git zsh wget curl neofetch bat thefuck fzf
    elif command -v brew &>/dev/null; then
        update_and_install_packages "brew update" "brew install" git zsh wget curl neofetch bat thefuck fzf
    elif command -v apt &>/dev/null; then
        update_and_install_packages "sudo apt update -y" "sudo apt install -y" git zsh wget curl neofetch bat python3-dev python3-pip python3-setuptools thefuck fzf
    else
        echo "Unsupported package manager. The only supported package manager are Homebrew; APT; Pacman"
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
    echo -ne "Installing Oh My Zsh..." # Display installation process
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" </dev/null >/dev/null 2>&1 &# Execute installation in background
    spinner                                        # Call spinner function to display animation
    echo -ne " [✓] Installing Oh My Zsh... Done\n" # Update status after completion
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

    echo -ne "Cloning plugins..."     # Display cloning process
    for plugin in "${plugins[@]}"; do # Loop through plugins array
        git clone --depth=1 "$plugin" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$(basename $plugin .git)" >/dev/null 2>&1 &# Clone plugin repository in background
        spinner # Call spinner function to display animation
    done
    echo -ne " [✓] Cloning plugins... Done\n" # Update status after completion
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
    [ -e ~/.zshrc ] && rm -f ~/.zshrc       # Remove .zshrc if exists
    [ -e ~/.p10k.zsh ] && rm -f ~/.p10k.zsh # Remove .p10k.zsh if exists
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
    cp ${ZSH_CUSTOM:-~/.oh-my-zsh/}/plugins/extract ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/extract >/dev/null 2>&1 &# Copy extract plugin
    spinner # Call spinner function to display animation
    cp ${ZSH_CUSTOM:-~/.oh-my-zsh/}/plugins/command-not-found ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/command-not-found >/dev/null 2>&1 &# Copy command-not-found plugin
    spinner                                       # Call spinner function to display animation
    echo -ne "Downloading configuration files..." # Display downloading process
    cp ./config/.p10k.zsh ~/.p10k.zsh >/dev/null 2>&1 &# Copy .p10k.zsh configuration
    spinner # Call spinner function to display animation
    cp ./config/.zshrc ~/.zshrc >/dev/null 2>&1 &# Copy .zshrc configuration
    spinner                                                   # Call spinner function to display animation
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k >/dev/null 2>&1 &
    spinner
    echo -ne " [✓] Downloading configuration files... Done\n" # Update status after completion
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
    echo -ne "Cleaning up..." # Display cleanup process
    cd ..                     # Navigate to parent directory
    rm -rf ./Bash-To-ZSH-Initialization >/dev/null 2>&1 &# Remove directory and its content
    spinner                               # Call spinner function to display animation
    echo -ne " [✓] Cleaning up... Done\n" # Update status after completion
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
    echo "Set Zsh as the default shell? [Y/n] (default: Y)"           # Prompt user to set Zsh as default shell
    read -r set_zsh_default                                           # Read user input
    set_zsh_default="${set_zsh_default:-Y}"                           # Set default value to Y if user input is empty
    if [[ $set_zsh_default == "N" || $set_zsh_default == "n" ]]; then # Check if user confirms
        echo "Zsh is not set as the default shell."
    else
        echo "Changing default shell..."     # Display process
        chsh -s "$(command -v zsh)"          # Change default shell to Zsh
        echo "Zsh is now the default shell." # Inform user about successful change
        zsh # Start Zsh shell
    fi
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
    detect_package_manager # Execute package manager detection
    install_oh_my_zsh      # Execute Oh My Zsh installation
    clone_plugins          # Execute Zsh plugin cloning
    remove_zsh_config      # Execute existing Zsh configuration removal
    moving_config_files    # Execute new Zsh configuration file moving
    clean_up               # Execute cleanup process
    set_zsh_default        # Prompt and set Zsh as default shell
}

# Run the main function
main
