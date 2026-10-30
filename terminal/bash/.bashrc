# Git Bash: oh-my-posh (Catppuccin Mocha mauve)
#
# SADECE etkilesimli kabukta calissin. Ajan/arac kabuklari (Claude Code vb.)
# etkilesimsiz acilir, prompt kodu cikti icine karismasin.
# Tema dosyasi PowerShell ve Clink ile ayni: ~/.config/ohmyposh/esershnr-mauve.omp.json
if [[ $- == *i* ]] && command -v oh-my-posh >/dev/null 2>&1; then
  eval "$(oh-my-posh init bash --config "$HOME/.config/ohmyposh/esershnr-mauve.omp.json")"
fi
