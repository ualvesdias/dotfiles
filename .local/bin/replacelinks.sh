#!/bin/bash

base_folder="/home/odysseus/OneDrive/Documents/MyZettelkasten"
clipping=$(/bin/ls ${base_folder}/Clippings/ | rofi -dmenu -i)
links=($(grep -oE 'http[^)(]+?\.(gif|jpg|jpeg|png|bmp)' "${base_folder}/Clippings/${clipping}" | sort -u))

[[ -z ${links} ]] && {
    rofi -e "There are no images in this clipping."
    exit 1
}

{
echo ${links[@]} | 
    xargs -P30 -d' ' -I{} /bin/bash -c "url={}; new_name=\$RANDOM\$RANDOM\$RANDOM-\${url##*/}; /usr/bin/curl -k \${url} -o ${base_folder}/media/\${new_name}; echo \"s@\${url}@../media/\${new_name}@g\">/tmp/sedstr_\$$.sed" 2>/dev/null

all_seds=$(/bin/cat /tmp/sedstr_*.sed | tr '\n' ';')
sed -r -i "${all_seds}" "${base_folder}/Clippings/${clipping}" 
\rm /tmp/sedstr_*.sed
} &&
    rofi -e "A total of ${#links[@]} images were successfully downloaded and replaced." ||
    rofi -e "There was a problem with the process."
