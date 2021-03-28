#!/bin/bash

stdbuf -oL -eL \
yad --title="Conky Chooser" \
  --center --width=400 --height=250 \
  --html --uri="/home/creio/ctlos-helper/helper.html" \
  --button=Close:1 \
  --print-uri 2>&1 \
| while read -r line; do
     case ${line##*/} in
      gg)
        conky -c  "/home/s7/.config/conky/bar.conky.conf" ;;
      bb)
        conky -c  "/home/s7/.config/conky/nl.conky.conf" ;;
      ee)
        conky -c  "/home/s7/.config/conky/BL-Top.conf" ;;
      restart)
        conkyrestart ;;
      kill)
        kill-conky ;;
      *) echo "unknown command" ;;
     esac
done
