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

Install Skills:

```bash
npx skills add yannickpichardo/dotfiles
bunx skills add yannickpichardo/dotfiles
pnpm dlx skills add yannickpichardo/dotfiles
```

Specific skill:

```bash
npx skills add yannickpichardo/dotfiles --skill grill-me -g -a claude-code
npx skills add yannickpichardo/dotfiles --skill grill-me -g -a codex
```
