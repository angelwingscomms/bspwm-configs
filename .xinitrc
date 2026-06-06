[ -f ~/.Xresources ] && xrdb -merge ~/.Xresources

export BROWSER=chromium
export TERMINAL=urxvt
export PATH=/home/ed/.local/bin:/home/ed/.opencode/bin:$PATH

exec dbus-run-session bspwm