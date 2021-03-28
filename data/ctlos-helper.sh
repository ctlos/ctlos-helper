#!/bin/bash
# https://github.com/cjungmann/yaddemo

if [[ $(command -v yad) ]]; then
  echo "OK: yad"
else
  echo "ERROR, recommend install: pacman -S yad haveged" && exit
fi

if [[ $EUID -ne 0 ]]; then
  echo "run root" && exit
fi

user=$1

pacman_key() {
  systemctl -q is-active haveged || haveged -w 1024
  pacman-key --init
  pacman-key --populate 2>&1
  pacman-key --refresh-keys --keyserver hkp://keys.gnupg.net 2>&1
  systemctl -q is-active haveged || pkill haveged
}

pacman_mir() {
  reflector --verbose -p https,http -l 30 --sort rate --save /etc/pacman.d/mirrorlist 2>&1
  pacman -Syy --noconfirm 2>&1
}

add_blackarch() {
  curl -s -Lo /tmp/strap.sh https://blackarch.org/strap.sh
  sh /tmp/strap.sh 2>&1
}

system_up() {
  pacman -Syyuu --noconfirm 2>&1
}

export -f pacman_key
export -f pacman_mir
export -f add_blackarch
export -f system_up

yad_pacman() {
  menu=(
  "Обновить ключи Pacman|bash -c pacman_key"
  "Обновление зеркал pacman|bash -c pacman_mir"
  "Add BlackArch repo|bash -c add_blackarch"
  "Обновление системы|bash -c system_up"
  )

  yad_opts=(
  --title="Pacman actions" --text="<span font='12'>Выберите действие</span>\n"
  --center --width=350 --borders=15 --form --columns=2
  --window-icon="gtk-execute" --image="dialog-question" --image-on-top
  --buttons-layout=center
  )

  for m in "${menu[@]}"; do
    yad_opts+=( --field="${m%|*}:CHK" )
  done
  # yad_opts+=( --field="":lbl )

  IFS='|' read -ra ans < <( yad "${yad_opts[@]}" & )
  echo $IFS
  for i in "${!ans[@]}"; do
    if [[ ${ans[$i]} == TRUE ]]; then
      m=${menu[$i]}
      name=${m%|*}
      cmd=${m#*|}
      echo "Selected: $name ($cmd)"
      $cmd
    fi
  done | while read -r line; do echo "# ${line}"; done | yad --title="Progress" --width=650 --height=450 \
      --window-icon="gtk-execute" --progress --pulsate --auto-kill --auto-close --center \
      --enable-log "Progress..." --log-expanded --log-height=300 --log-on-top --percentage=1
}

export -f yad_pacman

yad \
--title="Ctlos Helper" \
--center --width=450 --borders=15 \
--text-info --text-align=center \
--text="<span font='12'>Ctlos Linux Helper</span>\n" \
--window-icon="gtk-execute" \
--buttons-layout=center --button="Close":1 \
--form --columns=1 \
--field="Pacman menu":fbtn "bash -c yad_pacman" \
--field="Установить доп. пакеты":fbtn "bash -c /etc/ctlos-helper/pkgs.sh" \
--field="Ctlos Linux Wiki":fbtn "sudo -u $user xdg-open https://ctlos.github.io"
