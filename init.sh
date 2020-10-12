#!/bin/bash

EMAIL=${1:?email address required}

ANSWERS_FILE=~/.easy-at-home-answers
if [ -f $ANSWERS_FILE ]; then
  ANSWERS=$(< $ANSWERS_FILE)
fi

EXIT_CODE_EXPECTED_DIVERSION=42

function ask_one_time_question() {
  local key=$1
  local question=$2
  if [[ ! "$ANSWERS" =~ "$key" ]]; then
    read -p "$question " -n 1 -r
    echo
    echo "$key:$REPLY" >> $ANSWERS_FILE
    # lowercase the reply
    REPLY=${REPLY,,}
  else
    REPLY=""
  fi
}

function prepare_lpass() {
  if ! lpass status; then
    lpass login $EMAIL
  fi
}

# start with the latest
sudo apt update
sudo apt upgrade -y
sudo apt autoremove

# just to be sure
sudo apt install -y curl wget

ask_one_time_question additional-drivers "Did you install the additional drivers for video and network card (y/n)?"
if [[ "$REPLY" == "y" ]]; then
  echo Nice!
elif [[ "$REPLY" == "n" ]]; then
  echo "OK, I'll open the settings for you and you can run this init script again when you're done"
  /usr/bin/software-properties-gtk --open-tab=4
  exit $EXIT_CODE_EXPECTED_DIVERSION
fi

# git
if [ $(dpkg-query -W -f='${Status}' git-gui 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  sudo apt install -y git-gui
fi
if [ ! -f ~/.ssh/id_rsa ]; then
  ssh-keygen -b 4096
  cat ~/.ssh/id_rsa.pub | xclip -sel clip
  read -p "We've copied your public key to the clipboard and will now open the settings of GitHub and GitLab (press any key to continue)" -n 1 -r; echo
  xdg-open https://github.com/settings/ssh/new
  xdg-open https://gitlab.com/profile/keys
fi
if [ ! -f ~/.ssh/config ]; then
  cat << EOF > ~/.ssh/config
Host github.com
  HostName github.com
  User git
  AddKeysToAgent yes
  IdentityFile $HOME/.ssh/id_rsa

Host gitlab.com
  HostName gitlab.com
  User git
  AddKeysToAgent yes
  IdentityFile $HOME/.ssh/id_rsa

# Host github.com-work
#  HostName github.com
#  User git
#  AddKeysToAgent yes
#  IdentityFile $HOME/.ssh/id_rsa_work

# Host gitlab.com-work
#  HostName gitlab.com
#  User git
#  AddKeysToAgent yes
#  IdentityFile $HOME/.ssh/id_rsa_work
EOF
fi

# shell
if [ ! -d ~/.oh-my-zsh ]; then
  sudo apt install -y zsh
  chsh -s $(which zsh)
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi


# lastpass
if [ ! -f /usr/bin/lpass ]; then
  sudo apt --no-install-recommends -yqq install \
    bash-completion \
    build-essential \
    cmake \
    libcurl4  \
    libcurl4-openssl-dev  \
    libssl-dev  \
    libxml2 \
    libxml2-dev  \
    libssl1.1 \
    pkg-config \
    ca-certificates \
    xclip
  git clone https://github.com/lastpass/lastpass-cli.git /tmp/lastpass-cli
  (cd /tmp/lastpass-cli; make)
  (cd /tmp/lastpass-cli; sudo make install)
fi

# editor - cli: spacemacs
if [ $(dpkg-query -W -f='${Status}' emacs 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  sudo apt install -y emacs
fi
if [ ! -d ~/.emacs.d ]; then
  git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
fi

# editor - gui: sublime text
if [ $(dpkg-query -W -f='${Status}' sublime-text 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
  sudo apt-get install -y apt-transport-https
  echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list
  sudo apt update
  sudo apt install -y sublime-text
  prepare_lpass
  lpass show --notes "Sublime Text user license" > ~/.config/sublime-text-3/Local/License.sublime_license
fi

# PIA
if [ ! -d /opt/piavpn/bin/ ]; then
  curl -fsSL https://installers.privateinternetaccess.com/download/pia-linux-2.5-05652.run -o /tmp/pia.run 
  chmod +x /tmp/pia.run
  /tmp/pia.run
fi

# languages
#  python
sudo apt install -y python3 idle3
#  java
# todo: sdkman
#  node
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts

# helpers
npm ci

# synergy
if [ $(dpkg-query -W -f='${Status}' synergy 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  prepare_lpass
  npx cypress run --headless --quiet --spec cypress/integration/synergy_serial.js --env "EMAIL=$(lpass show --username 'synergy'),PASSWORD=$(lpass show --password 'synergy')"
  curl --silent --output /tmp/synergy.deb $(</tmp/synergy.deb.url)
  sudo apt install -y /tmp/synergy.deb
  echo "We've just installed Synergy and now we're going to open it for you to paste the serial key (which we've put on your clipboard)"
  cat /tmp/synergy.serial | xclip -sel clip
  /usr/bin/synergy
fi

# browsers
if [ ! -f /usr/bin/google-chrome ]; then
  curl https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -o /tmp/chrome.deb
  sudo apt install /tmp/chrome.deb
fi

# cleanup
rm -f /tmp/pia.run
rm -rf /tmp/lastpass-cli
rm -f /tmp/chrome.deb
rm -f /tmp/synergy.serial
rm -f /tmp/synergy.deb
rm -f /tmp/synergy.deb.url
sudo apt autoremove
sudo apt autoclean
