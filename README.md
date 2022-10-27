# linux-config-files

# Initial setup

git config --global user.name "William Kjær" <br />
git config --global user.email "william.kjaer@me.com" <br />
git config --global core.editor vim <br />

ssh-keygen -t ed25519 -C "william.kjaer@me.com" <br />
eval "$(ssh-agent -s)" <br />
ssh-add .ssh/id_ed25519 <br />
cat .ssh/id_ed25519.pub <br />
<Enter ssh key-phrase into Github.com> <br />
