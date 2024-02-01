#!/bin/bash

# URLs
ohmyzsh_install_script="https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
powerlevel10k_repo="https://github.com/romkatv/powerlevel10k.git"

# Prompt user to change password
read -p "Do you want to change the user's password? [Y/n] " input
input=${input:-Y}
if [[ $input == "Y" || $input == "y" ]]; then
    passwd
fi

# Update and upgrade packages
sudo pacman -Syu --noconfirm || { echo "Error updating packages."; exit 1; }

# Install necessary packages
sudo pacman -S --noconfirm git zsh wget curl neofetch || { echo "Error installing packages."; exit 1; }

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL $ohmyzsh_install_script)" </dev/null

# Check if Oh My Zsh installation succeeded
if [ ! -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh installation failed."
    exit 1
fi

# Clone powerlevel10k, zsh-autosuggestions, and zsh-syntax-highlighting
git clone --depth=1 $powerlevel10k_repo ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Remove existing zsh configuration files
[ -e ~/.zshrc ] && rm -f ~/.zshrc
[ -e ~/.p10k.zsh ] && rm -f ~/.p10k.zsh

# Download new zsh configuration files
wget https://raw.githubusercontent.com/MushuDG/PiInitialization/main/.p10k.zsh -O ~/.p10k.zsh
wget https://raw.githubusercontent.com/MushuDG/PiInitialization/main/.zshrc -O ~/.zshrc

# Clean up
rm -rf ./PiInitialization

# Set Zsh as the default shell if the user agrees
echo "Set Zsh as the default shell? [Y/n]"
read set_zsh_default
if [[ $set_zsh_default == "Y" || $set_zsh_default == "y" ]]; then
    clear
    chsh -s $(which zsh)
    # Start zsh
    zsh
fi
