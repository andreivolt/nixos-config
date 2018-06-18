sudo chsh -s /bin/zsh avo

curl https://nixos.org/nix/install | sh

scp ~/.dotfiles/.npmrc macos.local:

nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
./result/bin/darwin-installer

security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k password

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew install ruby
brew install graphicsmagick

mkdir ~/proj

security unlock-keychain -p ${macosvm_password}

/etc/sudoers
%wheel    ALL=(ALL)   NOPASSWD: ALL

brew cask install osxfuse
brew install sshfs
