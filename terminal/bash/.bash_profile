# Git Bash giris kabugu (mintty / Windows Terminal) ~/.bashrc'yi kendisi okumaz,
# bu yuzden burada elle yukluyoruz.
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
