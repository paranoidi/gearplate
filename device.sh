#!/usr/bin/env bash
# Interactive device setup, run by `task device` (D28). Each answer is written straight
# into devices/<name>/<name>.json, so hand-added keys (fit, wall, ...) survive a re-run.
# Adding a question = one `ask_num key default label` (or ask_int, ask_yn, entry, list_prompt) line.
set -eu
# `device.sh --edit [name]` (task edit-device): existing devices only.
TASK=${TASK_EXE:-task}
edit=; if [ "${1:-}" = --edit ]; then edit=1; shift; fi
name=${1:-}
if [ -z "$name" ]; then
  if [ -n "$edit" ]; then echo "Devices: $(ls devices | tr '\n' ' ')"; fi
  printf 'Device name (e.g. switch): '; read -r name
fi
echo "$name" | grep -qE '^[A-Za-z0-9_-]+$' || { echo "name must be letters, digits, - or _" >&2; exit 1; }
f=devices/$name/$name.json
if [ -n "$edit" ] && [ ! -f "$f" ]; then echo "No $f; create it with task device" >&2; exit 1; fi
if [ -f "$f" ]; then echo "Editing $f (Enter keeps the value in brackets)"
else mkdir -p "devices/$name"; jq -n --arg n "$name" '{fileFormatVersion: "1", parameterSets: {($n): {}}}' > "$f"; fi

# stored answer for key $1, else default $2
get() { local v; v=$(jq -r --arg n "$name" --arg k "$1" '.parameterSets[$n][$k] // empty' "$f"); echo "${v:-$2}"; }
put() { jq --arg n "$name" --arg k "$1" --arg v "$2" '.parameterSets[$n][$k] = $v' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
ask() { local d v; d=$(get "$1" "$2"); printf '%s [%s]: ' "$3" "$d" >&2; read -r v; echo "${v:-$d}"; }
ask_num() {  # key default label
  local v; v=$(ask "$1" "$2" "$3")
  echo "$v" | grep -qE '^[0-9]+(\.[0-9]+)?$' || { echo "not a number: $v" >&2; exit 1; }
  put "$1" "$v"
}
ask_int() {  # key default label
  local v; v=$(ask "$1" "$2" "$3")
  echo "$v" | grep -qE '^[0-9]+$' || { echo "not a whole number: $v" >&2; exit 1; }
  put "$1" "$v"
}
ask_yn() {  # key default label
  local d v; d=$(get "$1" "$2")
  if [ "$d" = true ]; then printf '%s [Y/n] ? ' "$3"; else printf '%s [y/N] ? ' "$3"; fi
  read -r v
  case "$v" in [yY]*) put "$1" true ;; [nN]*) put "$1" false ;; '') put "$1" "$d" ;; *) echo "answer y or n" >&2; exit 1 ;; esac
}
# One list entry: key, prompt, regex, "off" value. Shows the stored value; Enter keeps it,
# - removes it. Sets `blank` when the answer was empty (no more entries).
entry() {
  local off=$4 cur c
  cur=$(get "$1" "$off" | tr -d '[] '); [ "$cur" = "$(echo "$off" | tr -d '[] ')" ] && cur=
  printf '%s [%s]: ' "$2" "$cur"; read -r c
  c=$(echo "${c:-$cur}" | tr -d '[] '); blank=; [ -z "$c" ] && blank=1; [ "$c" = - ] && c=
  if [ -n "$c" ]; then
    echo "$c" | grep -qE "$3" || { echo "bad value: $c" >&2; exit 1; }
    put "$1" "[$(echo "$c" | sed 's/,/, /g')]"
  else put "$1" "$off"; fi
}
# Numbered list key1..keyN; stops asking after the first blank unless later ones are set.
list_prompt() {  # prefix count label regex off
  local more=1 k cur
  for k in $(seq "$2"); do
    cur=$(get "$1$k" "$5")
    if [ "$cur" != "$5" ] || [ $more = 1 ]; then entry "$1$k" "$3 $k" "$4" "$5"; if [ -n "$blank" ]; then more=0; fi
    else put "$1$k" "$5"; fi
  done
}

# Pass 1: device and caps
ask_num device_w 60 'Device width mm'
ask_num device_h 100 'Device height mm (between the caps)'
ask_num device_d 25 'Device depth mm (plate to front)'
ask_yn full_holes true 'Reusable plate (full holes)'
echo 'Per cap: a top cutout (strap window open through the end, e.g. for LEDs) as w,l,x'
echo '(l = length along the device from its end), then up to 4 end-wall cutouts as w,h,x.'
echo 'x: 0 = centred, + = right seen from outside, strap on top.'
echo 'Blank line = keep shown value / no more cutouts, - = remove.'
cut='^[0-9.]+,[0-9.]+,-?[0-9.]+$'
for cap in a b; do
  C=$(echo $cap | tr ab AB)
  entry ${cap}_top "Cap $C top cutout" "$cut" '[0, 0, 0]'
  list_prompt ${cap}_cut 4 "Cap $C cutout" "$cut" '[0, 0, 0]'
done
echo 'Plate margin: extra openGrid cells (28 mm) added to the smallest plate, seen from the'
echo 'device face with cap A at the bottom (docs/coordinates.png).'
ask_int margin_a 0 'Margin cells below cap A'
ask_int margin_b 0 'Margin cells above cap B'
ask_int margin_l 0 'Margin cells left'
ask_int margin_r 0 'Margin cells right'

# Pass 2: plate, against the hole map of the plate pass 1 produced
"$TASK" device:check D="$name"
echo 'Wire slots as x1,y1,x2,y2 hole indices from the map (14 mm wide, rounded ends).'
echo '-1 or 2*cells runs the slot out through that edge. Not over s (snaps) or o (screws).'
list_prompt slot 8 'Slot' '^-?[0-9]+,-?[0-9]+,-?[0-9]+,-?[0-9]+$' '[0, 0, 0, 0]'

echo "Saved $f"
"$TASK" device:build D="$name"
