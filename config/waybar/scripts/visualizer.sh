#!/usr/bin/env bash
# Cava visualizer for waybar - outputs JSON with unicode bars

# Cava config for raw output
cava_config=$(mktemp)
cat > "$cava_config" <<EOF
[general]
bars = 12
framerate = 30
sensitivity = 100
autosens = 1

[input]
method = pipewire
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = 59
frame_delimiter = 10
EOF

# Unicode bar characters (from empty to full)
bar_chars=("▁" "▂" "▃" "▄" "▅" "▆" "▇" "█")

# Event Horizon gradient: pink -> violet -> cyan -> bright aqua across 12 bars.
# Low freqs pink, high freqs aqua.
colors=(
    "#ee64ac" "#d26bb4" "#b672bd" "#9a79c5"
    "#a78bfa" "#7e92e3" "#559ac7" "#26bbd9"
    "#3fc4de" "#59e3e3" "#59e3e3" "#59e3e3"
)

cava -p "$cava_config" 2>/dev/null | while IFS=';' read -r -a values; do
    output=""
    i=0
    for val in "${values[@]}"; do
        val=${val%%.*}
        [ -z "$val" ] && val=0
        [ "$val" -gt 7 ] && val=7
        output+="<span foreground='${colors[$i]}'>${bar_chars[$val]}</span>"
        i=$((i + 1))
    done
    [ -n "$output" ] && echo "{\"text\": \"$output\", \"class\": \"cava\"}"
done

rm -f "$cava_config"
