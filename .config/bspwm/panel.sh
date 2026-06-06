#!/bin/sh

pkill -f 'lemonbar.*panel' 2>/dev/null

clock=""

update() {
    focused_desk=$(bspc query -D -d focused --names 2>/dev/null)
    focused_node=$(bspc query -N -n focused 2>/dev/null)

    ws=""
    for d in $(bspc query -D --names 2>/dev/null); do
        if [ "$d" = "$focused_desk" ]; then
            ws="${ws}%{A:bspc desktop -f ${d}:}%{B#555} ${d} %{B-}%{A}"
        elif bspc query -D -d "$d" -n .occupied >/dev/null 2>&1; then
            ws="${ws}%{A:bspc desktop -f ${d}:}%{B#333} ${d} %{B-}%{A}"
        else
            ws="${ws}%{A:bspc desktop -f ${d}:} ${d} %{A}"
        fi
    done

    tasks=""
    for wid in $(bspc query -N -d focused -n .window 2>/dev/null); do
        name=$(xdotool getwindowname "$wid" 2>/dev/null | head -c 40)
        [ -z "$name" ] && continue
        name=$(echo "$name" | tr '\n' ' ')
        if [ "$wid" = "$focused_node" ]; then
            tasks="${tasks}%{A:bspc node -f ${wid}:}%{B#555} ${name} %{B-}%{A}"
        else
            tasks="${tasks}%{A:bspc node -f ${wid}:}  ${name}  %{A}"
        fi
    done

    bat=""
    if [ -d /sys/class/power_supply/BAT0 ]; then
        cap=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)
        sta=$(cat /sys/class/power_supply/BAT0/status 2>/dev/null)
        [ -n "$cap" ] && bat="bttry:${cap}%"
        [ "$sta" = "Charging" ] && bat="${bat} charging"
    fi

    data=""
    if [ -d /sys/class/net/wlp0s20f3/statistics ]; then
        val=$(~/.local/bin/datacount 2>/dev/null)
        [ -n "$val" ] && data="%{A:~/.local/bin/datacount reset:}data:${val}KB%{A}"
    fi

    wifi=""
    link=$(iw dev wlp0s20f3 link 2>/dev/null)
    ssid=$(echo "$link" | sed -n 's/.*SSID: //p')
    if [ -n "$ssid" ]; then
        wifi="wifi:$ssid"
    else
        wifi="wifi:none"
    fi

    ram=""
    total=$(awk '/^MemTotal:/{print $2}' /proc/meminfo 2>/dev/null)
    avail=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo 2>/dev/null)
    if [ -n "$total" ] && [ -n "$avail" ]; then
        used=$(( (total - avail) / 1024 ))
        ram="ram:${used}MB"
    fi

    cpu=""
    if [ -f /tmp/cpu-stat ]; then
        read -r prev_idle prev_total < /tmp/cpu-stat
        cur=$(awk '/^cpu /{for(i=2;i<=NF;i++) t+=$i; print $5, t}' /proc/stat)
        cur_idle=$(echo "$cur" | cut -d' ' -f1)
        cur_total=$(echo "$cur" | cut -d' ' -f2)
        idle_diff=$((cur_idle - prev_idle))
        total_diff=$((cur_total - prev_total))
        if [ "$total_diff" -gt 0 ]; then
            pct=$(( (100 * (total_diff - idle_diff)) / total_diff ))
            cpu="cpu:${pct}%"
        fi
    fi
    awk '/^cpu /{for(i=2;i<=NF;i++) t+=$i; print $5, t}' /proc/stat > /tmp/cpu-stat

    temp=""
    t=$(cat /sys/class/thermal/thermal_zone13/temp 2>/dev/null)
    [ -n "$t" ] && temp="temp:$((t / 1000))°C"

    echo "%{l}${ws}%{c}${tasks}%{r}${data} ${wifi} ${bat} ${ram} ${cpu} ${temp} ${clock}"
}

# subscribe to events and update on each one
{
    bspc subscribe desktop node_add node_remove node_focus &
    while :; do
        echo C
        sleep 2
    done
} | while read -r line; do
    case $line in
        C*) clock=$(date +%H:%M) ;;
    esac
    update
done | lemonbar -p -g 1920x24 -f "monospace-10" -B "#222222" -F "#ffffff" -n panel | while read -r cmd; do
    eval "$cmd"
done
