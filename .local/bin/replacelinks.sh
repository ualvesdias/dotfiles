#!/bin/bash

base_folder="/home/odysseus/OneDrive/Documents/MyZettelkasten"

clipping=$(/bin/ls ${base_folder}/Clippings/ | rofi -dmenu -i)

links=($(grep -oE 'http[^)(]+?\.(gif|jpg|jpeg|png|bmp)' "${base_folder}/Clippings/${clipping}"))
#links=($links)

[[ -z ${links} ]] && {
    rofi -e "There are no images in this clipping."
    exit 1
}

#python3 -c "from re import sub; clipping=open('$base_folder/Clippings/$clipping'); clipping=clipping.read(); sub(r'https?://.+?([^/]*\.(gif|jpg|jpeg|png|bmp))',r'../media/\1',clipping); result=open('$base_folder/Clippings/$clipping','w'); result.write(clipping)"
#if ! sed -r -i "s|https?://([a-zA-Z0-9_.-]+/)+([^/]*\.(gif|jpg|jpeg|png|bmp))|../media/\1|g" "${base_folder}/Clippings/${clipping}"; then
    #rofi -e "An error occured while replacing image links."
    #exit 1
#fi

/bin/echo ${links[@]} | 
    xargs -P20 -L1 -I{} /bin/bash -c "
    link={}; sed -r -i \"s|${link}|../media/${link##*/}|g\" \"${base_folder}/Clippings/${clipping}\";  /usr/bin/curl {} -s -q -o ${base_folder}/media/${link##*/}" && 
        rofi -e "A total of ${#links[@]} image links were converted." || 
        rofi -e "An error occured while downloading the images."


