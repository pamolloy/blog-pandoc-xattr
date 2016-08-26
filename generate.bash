#!/bin/bash
#
# NAME
#   generate.bash - Generate HTML from Markdown
#
# SYNOPSIS
#   generate.bash SOURCE... DIRECTORY
#

YAML=$(mktemp)
echo -e "---\npost:" > $YAML
for FILE in $(ls -t "$1"/*.md); do
    echo -e "  - file:\t$(basename $FILE .md).html" >> $YAML
    PANDOC="pandoc --standalone --data-dir=$PWD --to=html"
    IFS=$'\n'                               # Use new lines to split
    OUTPUT=( $(getfattr -d $FILE) )         # Array with each line as an element
    for LINE in ${OUTPUT[@]}; do            # Loop through `getfattr` output
        if [ ${LINE:0:4} = "user" ]; then   # Lines starting with `user`
            IFS="="
            read -a ARRAY <<< "${LINE:5}"   # Split on `=`
            KEY="${ARRAY[0]}"
            VALUE="${ARRAY[1]//\"}"
            if [ $KEY = "birth" ]; then
                PANDOC+=" --variable "
                VALUE=$(date -d "$VALUE" +"%A, %B %e, %Y")
                echo "$DATE"
                PANDOC+="$KEY=\"$VALUE\""
            elif [ $KEY = "pandoc" ]; then
                PANDOC+=" $VALUE "          # Use pandoc flags e.g. --mathjax
            elif [ $KEY = "title" ]; then
                PANDOC+=" --variable "
                PANDOC+=${LINE:5}
                PANDOC+=" --variable "
                PANDOC+="pagetitle${LINE:10}"
            else 
                PANDOC+=" --variable "      # Add a Pandoc template variable
                PANDOC+=${LINE:5}           # e.g. `birth="1365307200"`
            fi
            echo -e "    $KEY:\t$VALUE" >> $YAML
        fi
    done
    echo $PANDOC
    eval "$PANDOC -c screen.css -o html/$(basename $FILE .md).html $FILE"
done
echo -e "---\n" >> $YAML
cat $YAML
pandoc --standalone --data-dir=$PWD --variable pagetitle="Philip Molloy" --template=index.html \
    -c ../screen.css -o "$2"/index.html $YAML
rm $YAML
