#!/bin/bash
omero_server="$1"
omero_user="$(cat $2 | awk 'NR==2{print $0}')"
omero_password="$(cat $2 | awk 'NR==3{print $0}')"
to_create=$3
screen_name_or_id=$4

if [ "$to_create" = "create" ]; then
    # Create a screen:
    screen_name_or_id=$(omero obj -s ${omero_server} -u ${omero_user} -w ${omero_password} new Screen name="${screen_name_or_id}" | awk -F ":" 'END{print $NF}')
    echo "Just created the new screen ${screen_name_or_id}"
fi

echo "Start upload"
companion_file=$(ls output/*.companion.ome)
omero import -s ${omero_server} -u ${omero_user} -w ${omero_password} -T Screen:id:"${screen_name_or_id}" "${companion_file}" 2>&1
echo "Upload finished"
