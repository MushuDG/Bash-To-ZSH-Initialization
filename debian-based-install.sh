#!/bin/bash

# Animated spinner function
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Fancy hacker interface
echo "Initializing installation..."
sleep 1
echo "Installing necessary tools and packages:"
sleep 1

# Prompt user to change password
read -p "Do you want to change the user's password? [Y/n] " input
input=${input:-Y} 
if [[ $input == "Y" || $input == "y" ]]; then
    echo "Changing password..."
    passwd
fi

# Update and upgrade packages
echo -ne "Updating packages..."
sudo apt update -y > /dev/null 2>&1 &
spinner
sudo apt upgrade -y > /dev/null 2>&1 &
spinner
echo -ne " [✓] Updating packages... Done\n"

# Install necessary packages
echo -ne "Installing packages..."
sudo apt install git zsh wget curl neofetch bat python3-dev python3-pip python3-setuptools -y > /dev/null 2>&1 &
spinner
echo -ne " [✓] Installing packages... Done\n"

# Install Oh My Zsh
echo -ne "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" </dev/null > /dev/null 2>&1 &
spinner
echo -ne " [✓] Installing Oh My Zsh... Done\n"

# Check if Oh My Zsh installation succeeded
if [ ! -d ~/.oh-my-zsh ]; then
    echo "Oh My Zsh installation failed."
    exit 1
fi

# Clone powerlevel10k, zsh-autosuggestions, zsh-you-should-use, zsh-bat and zsh-syntax-highlighting
echo -ne "Cloning plugins..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k > /dev/null 2>&1 &
spinner
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions > /dev/null 2>&1 &
spinner
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/you-should-use > /dev/null 2>&1 &
spinner
git clone https://github.com/fdellwing/zsh-bat.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-bat > /dev/null 2>&1 &
spinner
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting > /dev/null 2>&1 &
spinner
echo -ne " [✓] Cloning plugins... Done\n"

# Install thefuck plugin
echo -ne "Installing thefuck plugin..."
pip3 install thefuck --user > /dev/null 2>&1 &
spinner
echo -ne " [✓] Installing thefuck plugin... Done\n"

# Remove existing zsh configuration files
[ -e ~/.zshrc ] && rm -f ~/.zshrc
[ -e ~/.p10k.zsh ] && rm -f ~/.p10k.zsh

# Download new zsh configuration files
echo -ne "Downloading configuration files..."
wget https://raw.githubusercontent.com/MushuDG/Bash-To-ZSH-Initialization/main/.p10k.zsh -O ~/.p10k.zsh > /dev/null 2>&1 &
spinner
wget https://raw.githubusercontent.com/MushuDG/Bash-To-ZSH-Initialization/main/.zshrc -O ~/.zshrc > /dev/null 2>&1 &
spinner
echo -ne " [✓] Downloading configuration files... Done\n"

# Clean up
echo -ne "Cleaning up..."
cd ..
rm -rf ./Bash-To-ZSH-Initialization > /dev/null 2>&1 &
spinner
echo -ne " [✓] Cleaning up... Done\n"

# Set Zsh as the default shell if user agrees
echo "Set Zsh as the default shell? [Y/n]"
read set_zsh_default
if [[ $set_zsh_default == "Y" || $set_zsh_default == "y" ]]; then
    echo "Changing default shell..."
    chsh -s $(which zsh)
    echo "Zsh is now the default shell."
    # Start zsh
    zsh
fi
