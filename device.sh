#!/usr/bin/env bash
# Interactive device setup, run by `task device` (D28). Each answer is written straight
# into devices/<name>/<name>.json, so hand-added keys (fit, wall, ...) survive a re-run.
# Adding a question = one `ask_num key default label` (or ask_int, ask_yn, entry, list_prompt) line.
set -eu
# `device.sh --edit [name]` (task edit-device): existing devices only.
# `device.sh --only <section> [name]` (task edit-<section>): existing device, one section:
# size, cap-a, cap-b, margin or slots.
TASK=${TASK_EXE:-task}
edit=; only=
case "${1:-}" in
  --edit) edit=1; shift ;;
  --only) edit=1; only=$2; shift 2
    case "$only" in size|cap-a|cap-b|margin|slots) ;; *) echo "section must be size, cap-a, cap-b, margin or slots" >&2; exit 1 ;; esac ;;
esac
want() { [ -z "$only" ] || [ "$only" = "$1" ]; }
name=${1:-}
if [ -z "$name" ]; then
  if [ -n "$edit" ]; then echo "Devices: $(ls devices | tr '\n' ' ')"; fi
  printf 'Device name (e.g. switch): '; read -r name
fi
echo "$name" | grep -qE '^[A-Za-z0-9_-]+$' || { echo "name must be letters, digits, - or _" >&2; exit 1; }
f=devices/$name/$name.json
if [ -n "$edit" ] && [ ! -f "$f" ]; then echo "No $f; create it with task device" >&2; exit 1; fi
if [ -f "$f" ]; then echo "Editing $f (Enter keeps the value in brackets)"; fi
echo 'q at any question: save what you answered, skip the rest and build.'
if [ ! -f "$f" ]; then mkdir -p "devices/$name"; jq -n --arg n "$name" '{fileFormatVersion: "1", parameterSets: {($n): {}}}' > "$f"; fi

# q sets quit: every later question is skipped (answers are already saved one by one).
quit=
say() { [ -n "$quit" ] || echo "$@"; }
# stored answer for key $1, else default $2
get() { local v; v=$(jq -r --arg n "$name" --arg k "$1" '.parameterSets[$n][$k] // empty' "$f"); echo "${v:-$2}"; }
put() { jq --arg n "$name" --arg k "$1" --arg v "$2" '.parameterSets[$n][$k] = $v' "$f" > "$f.tmp" && mv "$f.tmp" "$f"; }
ask() { local d v; d=$(get "$1" "$2"); printf '%s [%s]: ' "$3" "$d" >&2; read -r v; echo "${v:-$d}"; }
ask_num() {  # key default label
  [ -z "$quit" ] || return 0
  local v; v=$(ask "$1" "$2" "$3"); [ "$v" = q ] && { quit=1; return; }
  echo "$v" | grep -qE '^[0-9]+(\.[0-9]+)?$' || { echo "not a number: $v" >&2; exit 1; }
  put "$1" "$v"
}
ask_int() {  # key default label
  [ -z "$quit" ] || return 0
  local v; v=$(ask "$1" "$2" "$3"); [ "$v" = q ] && { quit=1; return; }
  echo "$v" | grep -qE '^[0-9]+$' || { echo "not a whole number: $v" >&2; exit 1; }
  put "$1" "$v"
}
ask_yn() {  # key default label
  [ -z "$quit" ] || return 0
  local d v; d=$(get "$1" "$2")
  if [ "$d" = true ]; then printf '%s [Y/n] ? ' "$3"; else printf '%s [y/N] ? ' "$3"; fi
  read -r v
  case "$v" in q) quit=1 ;; [yY]*) put "$1" true ;; [nN]*) put "$1" false ;; '') put "$1" "$d" ;; *) echo "answer y or n" >&2; exit 1 ;; esac
}
# One list entry: key, prompt, regex, "off" value. Shows the stored value; Enter keeps it,
# - removes it. Sets `blank` when the answer was empty (no more entries).
entry() {
  blank=1; [ -z "$quit" ] || return 0
  local off=$4 cur c
  cur=$(get "$1" "$off" | tr -d '[] '); [ "$cur" = "$(echo "$off" | tr -d '[] ')" ] && cur=
  printf '%s [%s]: ' "$2" "$cur"; read -r c
  [ "$c" = q ] && { quit=1; return; }
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
    [ -z "$quit" ] || return 0
    cur=$(get "$1$k" "$5")
    if [ "$cur" != "$5" ] || [ $more = 1 ]; then entry "$1$k" "$3 $k" "$4" "$5"; if [ -n "$blank" ]; then more=0; fi
    else put "$1$k" "$5"; fi
  done
}

# Pass 1: device and caps
if want size; then
ask_num device_w 60 'Device width mm'
ask_num device_h 100 'Device height mm (between the caps)'
ask_num device_d 25 'Device depth mm (plate to front)'
ask_yn full_holes true 'Reusable plate (full holes)'
say 'Snap posts raise the plate off the wall, e.g. to run wires or underware channels behind'
say 'it (underware height is 18.6 mm). 0 = snaps directly on the plate.'
ask_num post_height 0 'Post height mm'
fi
if want cap-a || want cap-b; then
say 'Per cap: a top cutout (strap window open through the end, e.g. for LEDs) as w,l,x'
say '(l = length along the device from its end), then up to 4 end-wall cutouts as w,h,x.'
say 'x: 0 = centred, + = right seen from outside, strap on top.'
say 'Blank line = keep shown value / no more cutouts, - = remove.'
cut='^[0-9.]+,[0-9.]+,-?[0-9.]+$'
fi
for cap in a b; do
  want cap-$cap || continue
  C=$(echo $cap | tr ab AB)
  entry ${cap}_top "Cap $C top cutout" "$cut" '[0, 0, 0]'
  list_prompt ${cap}_cut 4 "Cap $C cutout" "$cut" '[0, 0, 0]'
done
if want margin && [ -z "$quit" ]; then
"$TASK" device:check D="$name" || true  # current plate; margins may be what fixes a failing assert
say 'Plate margin: extra openGrid cells (28 mm) added to the smallest plate, seen from the'
say 'device face with cap A at the bottom (docs/coordinates.png).'
ask_int margin_a 0 'openGrid cells below cap A'
ask_int margin_b 0 'openGrid cells above cap B'
ask_int margin_l 0 'openGrid cells left'
ask_int margin_r 0 'openGrid cells right'
fi

# Pass 2: plate, against the hole map of the plate pass 1 produced
if want slots && [ -z "$quit" ]; then
# A bad saved slot stops OpenSCAD before the map, so show the map without the slots then.
if ! "$TASK" device:check D="$name"; then
  echo 'Saved slots are invalid; map without them:'
  "$TASK" device:check D="$name" EXTRA="$(for k in $(seq 8); do printf -- "-D 'slot$k=[0,0,0,0]' "; done)" || true
fi
# plate size from the check, for the index range
read -r cx cy < <(sed -n 's/.*Assembly: plate \([0-9]*\) x \([0-9]*\) cells.*/\1 \2/p' "devices/$name/assembly.echo")
echo 'Wire slots as x1,y1,x2,y2 hole indices from the map (14 mm wide, rounded ends).'
echo "x: 0..$((2*cx - 1)), y: 0..$((2*cy - 1)), as on the map. An end on an edge row or column opens"
echo 'out through that edge. Not over s/S (snaps) or + (cap screws).'
# ponytail: -1 / 2*cells edge exits (D10) are left out here: the map's own indices do the same (D12)
while :; do
  list_prompt slot 8 'Slot' '^[0-9]+,[0-9]+,[0-9]+,[0-9]+$' '[0, 0, 0, 0]'
  bad=$(jq -r --arg n "$name" --argjson mx $((2*cx - 1)) --argjson my $((2*cy - 1)) \
    '.parameterSets[$n] | to_entries[] | select(.key | test("^slot[0-9]$")) | (.value | fromjson) as $s
     | select($s[0] < 0 or $s[2] < 0 or $s[1] < 0 or $s[3] < 0 or $s[0] > $mx or $s[2] > $mx or $s[1] > $my or $s[3] > $my) | .key' "$f")
  if [ -n "$bad" ]; then quit=; echo "Off the map: $(echo $bad); edit them again. Enter keeps a value, - removes it."; continue; fi
  "$TASK" device:check D="$name" && break
  quit=  # q can't skip past invalid slots
  echo 'Slots rejected (see ERROR above); edit them again. Enter keeps a value, - removes it.'
done
fi

echo "Saved $f"
"$TASK" device:build D="$name"
