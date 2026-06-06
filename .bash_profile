[ -f $HOME/.bashrc ] && . $HOME/.bashrc
export BROWSER=chromium

if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    startx
fi
