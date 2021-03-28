#!/usr/bin/env bash

results=$(mktemp --tmpdir pkgs.XXX)
yadkey="${RANDOM}"

parse_yaml() {
  local yaml_file=/home/creio/ctlos-helper/pkgs.yaml
  local elem=$1
  # https://github.com/mikefarah/yq/releases/v4.6.0
  # yay yq2-bin
  yq e "$elem" "$yaml_file"
}

export -f parse_yaml

tabs=(
"Kernel|.kernel[].pkgs"
"App|.app[].groups[].pkgs"
)

tab=0
for i in "${!tabs[@]}"; do
  m=${tabs[$i]}
  name=${m%|*}
  cmd=${m#*|}
  (( tab=$tab+1 ))

  pkgs_list=$(parse_yaml $cmd)
  for i in $(echo ${pkgs_list[@]}); do
    echo FALSE; echo "$i";
  done | yad --plug=${yadkey} --tabnum=$tab \
    --list --checklist --column="Select" --column="Pkgs list:" --print-column="2" --separator="" &>> $results &
done

tabs_name() {
  for i in "${!tabs[@]}"; do
    m=${tabs[$i]}
    name="--tab=${m%|*}"
    echo "$name"
  done
}

yad --center --width=550 --height=500 --notebook \
  --key=${yadkey} $(echo $(tabs_name)) --title="Pkgs list" \
  --text="<span font='12'>Выберите пакеты для установки</span>\n" \
  --window-icon="gtk-execute" --image="dialog-question" --button="Close":1 --button="Ok":2

install_pkgs() {
  res=$(cat $results)
  pacman -Syy --noconfirm --needed $res 2>&1 | \
  while read -r line; do echo "# ${line}"; done | yad --title="Progress" --width=650 --height=450 \
    --window-icon="gtk-execute" --progress --pulsate --auto-kill --auto-close --center \
    --enable-log "Progress..." --log-expanded --log-height=300 --log-on-top --percentage=1
}

[[ $(cat $results) ]] && install_pkgs

rm -f $results
