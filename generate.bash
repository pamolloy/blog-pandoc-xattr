#!/usr/bin/env bash

if ! command -v pandoc >/dev/null 2>&1; then
    echo "ERROR: Missing pandoc"
    return 1
fi

# Return the value of the given extended attribute key
function get_xattr {
    local file="${1}"
    local key="${2}"

    getfattr --only-values --absolute-names -n "${key}" "${file}"
}

# Convert a markdown file with extended attributes to HTML
function xattr_markdown_to_html {
    local file="${1}"
    local output="${2}"
    local timestamp

    # TODO(PM): Support arbitrary arguments
    timestamp=$(get_xattr "${file}" "user.birth")
    pandoc --standalone \
           --data-dir="${BASH_SOURCE[0]}" \
           --to=html \
           --variable "title=$(get_xattr "${file}" "user.title")" \
           --variable "pagetitle=$(get_xattr "${file}" "user.title")" \
           --variable "birth=$(date -d "${timestamp}" "+%B %d, %Y")" \
           --template="$(dirname "${BASH_SOURCE[0]}")/templates/default.html" \
           -c screen.css \
           -o "${output}" \
           "${file}"
}

# Recursively generate HTML pages and create an index page for each directory
function xattr_markdown_dir_to_html {
    local input_dir="$1"   # Path to directory containing Markdown
    local output_dir="$2"
    local pandoc_input=$(mktemp)
    local timestamp

    trap "rm ${pandoc_input}" EXIT

    echo -e "---\npost:" > "${pandoc_input}"
    for file in $(ls -t "${input_dir}"); do
        echo "Converting ${file}..."
        if [ -d "${input_dir}/${file}" ]; then
            echo -e "  - file:\t${file}" >> "${pandoc_input}"
            echo -e "    title:\t$(get_xattr "${input_dir}/${file}" "user.title")" \
                 >> $pandoc_input
            mkdir "$output_dir/$(basename "${file}")"
            xattr_markdown_dir_to_html "${input_dir}/$file" \
                "$output_dir/$(basename "${file}")"
        elif [[ "$file" == *.md ]]; then
            echo -e "  - file:\t$(basename $file .md).html" >> $pandoc_input
            echo -e "    title:\t$(get_xattr "${input_dir}/${file}" "user.title")" \
                 >> $pandoc_input
            timestamp=$(get_xattr "${input_dir}/${file}" "user.birth")
            echo -e "    birth: $(date -d "${timestamp}" "+%B %d, %Y")\t" \
                >> $pandoc_input
            xattr_markdown_to_html "${input_dir}/$file" \
                "${output_dir}/$(basename "${file}" .md).html"
        fi
    done
    echo -e "---\n" >> $pandoc_input

    pandoc --standalone \
           --data-dir=$DATA_DIR \
           --variable pagetitle="Philip Molloy" \
           --template=index.html \
           -c ../screen.css \
           -o "${output_dir}/index.html" "$pandoc_input"
}
