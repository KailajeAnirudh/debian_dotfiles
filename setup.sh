sudo apt  update && sudo apt -y upgrade
sudo apt install -y nala
cd ~/
mkdir -p ~/.config

sudo nala install -y  feh kitty i3 picom unzip wget blueman curl
sudo nala install -y neofetch autorandr light fonts-font-awesome -y
sudo nala install -y vlc simplescreenrecorder alacritty

sudo nala install software-properties-common
sudo add-apt-repository ppa:appimagelauncher-team/stable
sudo nala update
sudo nala install appimagelauncher 

sudo apt-get install wget gpg
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg

sudo apt install -y apt-transport-https
sudo apt update
sudo apt install -y code # or code-insiders

sudo nala install -y flathub filelight

sudo flatpak install -y flathub com.discordapp.Discord
sudo flatpak install -y flathub com.slack.Slack
sudo flatpak install -y flathub com.tencent.WeChat
sudo flatpak install -y flathub com.brave.Browser

git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq && sudo ./auto-cpufreq-installer


fc-cache -vf




