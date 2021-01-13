#!/bin/bash


set -e

spatialPrint() {
    echo ""
    echo ""
    echo "$1"
	echo "================================"
}

# To note: the execute() function doesn't handle pipes well
execute () {
	echo "$ $*"
	OUTPUT=$($@ 2>&1)
	if [ $? -ne 0 ]; then
        echo "$OUTPUT"
        echo ""
        echo "Failed to Execute $*" >&2
        exit 1
    fi
}

# Speed up the process
# Env Var NUMJOBS overrides automatic detection
if [[ -n $NUMJOBS ]]; then
    MJOBS=$NUMJOBS
elif [[ -f /proc/cpuinfo ]]; then
    MJOBS=$(grep -c processor /proc/cpuinfo)
elif [[ "$OSTYPE" == "darwin"* ]]; then
	MJOBS=$(sysctl -n machdep.cpu.thread_count)
else
    MJOBS=4
fi

execute sudo apt-get update -y
if [[ ! -n $CIINSTALL ]]; then
    sudo apt-get dist-upgrade -y
    sudo apt-get install ubuntu-restricted-extras -y
fi

# Choice for terminal that will be adopted: Tilda+tmux
# Not guake because tilda is lighter on resources
# Not terminator because tmux sessions continue to run if you accidentally close the terminal emulator

# refer : [http://www.rushiagr.com/blog/2016/06/16/everything-you-need-to-know-about-tmux-copy-pasting-ubuntu/] for tmux buffers in ubuntu

#Checks if ZSH is partially or completely Installed to Remove the folders and reinstall it
rm -rf ~/.z*
zsh_folder=/opt/.zsh/
if [[ -d $zsh_folder ]];then
	sudo rm -r /opt/.zsh/*
fi

spatialPrint "Setting up Zsh + Zim now"
execute sudo apt-get install zsh -y
sudo mkdir -p /opt/.zsh/ && sudo chmod ugo+w /opt/.zsh/
export ZIM_HOME=/opt/.zsh/zim
curl -fsSL https://raw.githubusercontent.com/zimfw/install/master/install.zsh | zsh
# Change default shell to zsh
command -v zsh | sudo tee -a /etc/shells
sudo chsh -s "$(command -v zsh)" "${USER}"

execute sudo apt-get install aria2 -y

# Create bash aliases
cp ./config_files/bash_aliases /opt/.zsh/bash_aliases
ln -s /opt/.zsh/bash_aliases ~/.bash_aliases

{
    echo "if [ -f ~/.bash_aliases ]; then"
    echo "  source ~/.bash_aliases"
    echo "fi"

    echo "# Switching to 256-bit colour by default so that zsh-autosuggestion's suggestions are not suggested in white, but in grey instead"
    echo "export TERM=xterm-256color"

    echo "# Setting the default text editor to micro, a terminal text editor with shortcuts similar to what you'd encounter in an IDE"
    echo "export VISUAL=micro"
} >> ~/.zshrc




# echo "*************************** NOTE *******************************"
# echo "If you ever mess up your anaconda installation somehow, do"
# echo "\$ conda remove anaconda matplotlib mkl mkl-service nomkl openblas"
# echo "\$ conda clean --all"
# echo "Do this for each environment as well as your root. Then reinstall all except nomkl"

# For utilities such as lspci
execute sudo apt-get install pciutils


# Browsers
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
execute sudo apt-get update  -y
execute sudo apt-get install google-chrome-stable -y
spatialPrint "The script has finished."

if [[ ! -n $CIINSTALL ]]; then
    su - $USER
fi
