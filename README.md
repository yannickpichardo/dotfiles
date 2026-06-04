# dotfiles

```bash
git clone https://github.com/yannickpichardo/dotfiles ~/dotfiles
mkdir -p ~/.config
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/.agents ~/.agents
ln -s ~/dotfiles/.claude ~/.claude
```

Update:

```bash
cd ~/dotfiles
git pull
```

`~/.config/nvim`, `~/.agents`, and `~/.claude` are symlinks into this repo.
