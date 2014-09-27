#!/bin/bash
#
#   convert.bash - Convert posts from Jeykll to new format
#
# TODO
#   - There may be other YAML lines
#   - Programming language in syntax highlighting declarations are lost
#

for FILE in "$1"/*.md; do
    FN=$(basename $FILE)            # If a path is specified store the filename
    STAT=$(stat -c%y $FILE)         # Store last modification time
    MTIME=$(date -d "$STAT")        # Convert to format understood by `touch -d`
    DATE="${FN:0:10}"               # Store creation date from filename
    sed -i '/{: id="genutiv"}/d' $FILE  # Delete lines with `{: id="genutiv"}`
    sed -i '/^---$/d' $FILE          # Delete `---` markdown footnote and YAML
    LINE=$(grep title: $FILE)       # Convert `title` to markdown header
    IFS=":" read -a ARRAY <<< "$LINE"           # Split on `:`
    TITLE=$(echo "${ARRAY[1]}" | sed 's/^ *//') # Remove leading spaces
    sed -i '/title: /d' $FILE       # Delete YAML `title` line
    sed -i '/permalink: /d' $FILE   # Delete YAML `permalink` line
    sed -i '/layout: /d' $FILE      # Delete YAML `layout` line
    sed -i 's#^{% highlight.*#```#g' $FILE
    sed -i 's#^{% endhighlight.*#```#g' $FILE
    NEW="posts/${FN:11}"            # Remove date from filename
    setfattr -n user.birth -v "$(date --date=$DATE)" $FILE
    setfattr -n user.title -v "$TITLE" $FILE
    rsync -ptgo -A -X $FILE $NEW    # Copy and preserve file attributes
    touch -d "$MTIME" $NEW          # Change modification time to original
    rm $FILE                        # Delete original file
done
