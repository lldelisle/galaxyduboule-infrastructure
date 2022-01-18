#!/bin/bash
# I assume:
# input images are in input
# output csv are in output
# If there is no csv it will exit 1
version=$1
maxThreshold=$2
output=$3

nb_results_files=$(ls output | wc -l)
if [[ $nb_results_files -eq 0 ]]; then
    echo "No result found"
    exit 1
fi
header=$(head -n 1 $(ls output/*csv | head -n 1))
echo $header > $output
for img in input/*; do
    result_file=output/$(basename $img)__Results.csv
    if [ -e $result_file ]; then
        tail -n +2 $result_file >> $output
    else
        echo $header | awk -F ',' -v OFS="," -v label=$(basename $img) -v v=$version -v mt=$maxThreshold -v date=$(date +%Y-%m-%d_%H-%M) '
{
    for (i=1;i<=NF;i++){
        if ($i == "Label"){
            $i = label
        } else if ($i == "Date"){
            $i = date
        } else if ($i == "Version"){
            $i = v
        } else if ($i == "MaxThreshold"){
            $i = mt
        } else {
            $i=""
        }
    }
    print
}' >> $output
    fi
done
