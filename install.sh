#!/bin/bash
passwd
sudo apt update -y
sudo apt upgrade -y
sudo apt install git zsh wget curl -y
chsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
rm -rf ~/.zshrc
rm -rf ~/.p10k.zsh
wget https://raw.githubusercontent.com/MushuDG/PiInitialisation/main/.p10k.zsh
wget https://raw.githubusercontent.com/MushuDG/PiInitialisation/main/.zshrc
zsh
