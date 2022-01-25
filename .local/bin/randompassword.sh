#!/bin/bash

amount=$(rofi -dmenu) && tr -dc 'A-Za-z0-9!@#$%&*(){}[],.;:?~' < /dev/urandom | dd bs=1 count=${amount} 2>/dev/null| xclip -selection clipboard || /usr/bin/rofi -e "No number provided."

sleep 60
printf '' | xclip -selection clipboard


