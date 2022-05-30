#!/bin/bash

base_folder="/home/odysseus/OneDrive/Documents/Notes"
clipping=$(/bin/ls ${base_folder}/Clippings/ | rofi -dmenu -i)
#clipping=$(/bin/ls ${base_folder}/Hackermindset/_posts/ | rofi -dmenu -i)
links=($(grep -oE 'http.+\.(gif|jpg|jpeg|png|bmp|svg)' "${base_folder}/Clippings/${clipping}" | sort -u))
#echo $links | rofi -dmenu
#links=($(grep -oE 'http[^)(]+?\.(gif|jpg|jpeg|png|bmp|svg)' "${base_folder}/Hackermindset/_posts/${clipping}" | sort -u))

[[ -z "${links}" ]] && {
    rofi -e "There are no images in this clipping."
    exit 1
}

{
echo "${links[@]}" | 
    xargs -P30 -d' ' -I{} /bin/bash -c "url={}; new_name=\$RANDOM\$RANDOM\$RANDOM-\${url##*/}; /usr/bin/curl -k \${url} -o ${base_folder}/media/\${new_name}; echo \"s@\${url}@../media/\${new_name}@g\">/tmp/sedstr_\$$.sed" 2>/dev/null
    #xargs -P30 -d' ' -I{} /bin/bash -c "url={}; new_name=\$RANDOM\$RANDOM\$RANDOM-\${url##*/}; /usr/bin/curl -k \${url} -o ${base_folder}/Hackermindset/assets/img/\${new_name}; echo \"s@\${url}@/assets/img/\${new_name}@g\">/tmp/sedstr_\$$.sed" 2>/dev/null

all_seds=$(/bin/cat /tmp/sedstr_*.sed | tr '\n' ';')
#/bin/cat /tmp/sedstr_*.sed | rofi -dmenu 
sed -r -i "${all_seds}" "${base_folder}/Clippings/${clipping}" 
#sed -r -i "${all_seds}" "${base_folder}/Hackermindset/_posts/${clipping}" 
\rm /tmp/sedstr_*.sed
} &&
    rofi -e "A total of ${#links[@]} images were successfully downloaded and replaced." ||
    rofi -e "There was a problem with the process."
