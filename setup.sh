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
cp -R fonts/opentype/* /usr/share/fonts/opentype/
cp -R fonts/truetype/* /usr/share/fonts/truetype/

sudo mv  Mangalore.jpg /usr/share/backgrounds/

sudo nala install -y  feh i3 i3blocks picom unzip wget blueman curl fzf 
sudo nala install -y neofetch autorandr light fonts-font-awesome 
sudo nala install -y vlc simplescreenrecorder alacritty
sudo nala install curl htop 

sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

sudo nala install brave-browser
mv key-bindings.bash /usr/share/doc/fzf/examples/

sudo wget https://github.com/Martichou/rquickshare/releases/download/v0.7.1/r-quick-share_0.7.1_amd64.deb
sudo nala install -y ./r-quick-share_0.7.1_amd64.deb

sudo nala install software-properties-common
sudo mv config /home/$username/.config/i3/

sudo apt-get install  gpg
sudo nala install -y flatpak filelight gnome-software-plugin-flatpak
sudo nala install -y plasma-discover-backend-flatpak

flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

sudo flatpak install -y flathub com.discordapp.Discord
sudo flatpak install -y flathub com.slack.Slack
sudo flatpak install -y flathub com.tencent.WeChat
sudo flatpak install -y flathub com.logseq.Logseq

git clone https://github.com/AdnanHodzic/auto-cpufreq.git
cd auto-cpufreq && sudo ./auto-cpufreq-installer


fc-cache -vf
