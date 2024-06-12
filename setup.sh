sudo apt update 
sudo apt install -y nala
sudo nala update && sudo nala upgrade

username=$(id -u -n 1000)
builddir=$(pwd)

cd $builddir

mkdir -p /home/$username/.config
mkdir -p /home/$username/.tmux

cp -R .config/* /home/$username/.config/
cp -R .tmux/* /home/$username/.tmux/
sudo mv  Mangalore.jpg /usr/share/backgrounds/

sudo nala install -y  feh kitty i3 picom unzip wget blueman curl
sudo nala install -y neofetch autorandr light fonts-font-awesome -y
sudo nala install -y vlc simplescreenrecorder alacritty

sudo nala install software-properties-common
sudo mv config /home$username/.config/i3/

sudo apt-get install  gpg
sudo nala install -y flatpak filelight gnome-software-plugin-flatpak
sudo nala install -y plasma-discover-backend-flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sudo flatpak install -y flathub com.discordapp.Discord
sudo flatpak install -y flathub com.slack.Slack
sudo flatpak install -y flathub com.tencent.WeChat
sudo flatpak install -y flathub com.brave.Browser
sudo flatpak install -y flathub com.logseq.Logseq
sudo flatpak install -y flathub com.visualstudio.code
git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq && sudo ./auto-cpufreq-installer


fc-cache -vf




