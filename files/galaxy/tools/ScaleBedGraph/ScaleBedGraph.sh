#!/bin/bash

awk -v s=$2 'BEGIN {OFS="\t"}{if (substr($0,0,5)=="track"){print $0}else{$4=$4/s;print$0}}' $1 > $3 

