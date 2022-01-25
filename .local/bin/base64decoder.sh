#!/bin/bash

encoded=$(rofi -dmenu); rofi -e "$(base64 -d <<< $encoded)"
