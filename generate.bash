#!/bin/bash
#
# NAME
#   generate.bash - Generate HTML from Markdown
#
# SYNOPSIS
#   generate.bash SOURCE... DIR
#

# TODO(PM): Check command-line arguments

set -x
set -e

if ! command -v pandoc >/dev/null 2>&1; then
    echo "Missing dependency: pandoc"
    exit 1
fi

parse_xattr () {
    local FILE="$1"
    local OUTPUT_DIR="$2"
    local PANDOC="pandoc --standalone --data-dir=$DATA_DIR --to=html"
    IFS=$'\n'                               # Use new lines to split

    OUTPUT=( $(getfattr -d $FILE) )         # Array with each line as an element
    for LINE in ${OUTPUT[@]}; do            # Loop through `getfattr` output
        if [ ${LINE:0:4} = "user" ]; then   # Lines starting with `user`
            local IFS="="
            read -a ARRAY <<< "${LINE:5}"   # Split on `=`
            KEY="${ARRAY[0]}"
            VALUE="${ARRAY[1]//\"}"
            if [ $KEY = "birth" ]; then
                PANDOC+=" --variable "
                VALUE=$(date -d "$VALUE" +"%A, %B %e, %Y")
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
            echo -e "    $KEY:\t$VALUE"
        fi
    done

    eval "$PANDOC --template=default.html -c screen.css -o $OUTPUT_DIR/$(basename -s .md $FILE).html $FILE"
}

generate_directory () {
    local INPUT_DIR="$1"   # Path to directory containing Markdown
    local OUTPUT_DIR="$2"
    local PANDOC_INPUT=$(mktemp)

    mkdir -p "$OUTPUT_DIR/$INPUT_DIR"

    cd $INPUT_DIR
    echo -e "---\npost:" > $PANDOC_INPUT
    for FILE in $(ls -t .); do
        if [ -d "$FILE" ]; then
            echo -e "  - file:\t$(basename $FILE)/" >> $PANDOC_INPUT
            # TODO(PM): Use user.title
            echo -e "    title:\t$(getfattr -d $FILE | grep -o '".*"')" \
                 >> $PANDOC_INPUT
            generate_directory "$FILE" "$OUTPUT_DIR/$INPUT_DIR"
        elif [[ "$FILE" == *.md ]]; then
            echo -e "  - file:\t$(basename $FILE .md).html" >> $PANDOC_INPUT
            parse_xattr "$FILE" "$OUTPUT_DIR/$INPUT_DIR" >> $PANDOC_INPUT
        fi
    done
    echo -e "---\n" >> $PANDOC_INPUT
    cat $PANDOC_INPUT
    pandoc --standalone \
           --data-dir=$DATA_DIR \
           --variable pagetitle="Philip Molloy" \
           --template=index.html -c ../screen.css \
           -o "${OUTPUT_DIR}/${INPUT_DIR}/index.html" $PANDOC_INPUT
    #rm $PANDOC_INPUT
    cd ..
}

DATA_DIR=/home/philip/repos/public/blog-pandoc-xattr/

if [[ "$2" = /* ]]; then
    OUTPUT_DIR="$2"
else
    OUTPUT_DIR="$PWD/$2"
fi

# TODO(PM): Don't create posts directory
cd "$1"; cd ..
generate_directory "${1##*/}" "$OUTPUT_DIR"

set +x
