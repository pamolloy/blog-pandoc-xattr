# blog-pandoc-xattr
This masterly crafted computer science project sits proudly on the dull edge of technological innovation. A few short BASH scripts and HTML templates wrap `pandoc`, which generates static HTML files.

## File attributes
The values of regular and extended file attributes are passed to `pandoc` using `generate.bash`.

Sometimes it is desirable to modify a file without changing the modification date and time. The following BASH function stores the modification date and time before modifying the file and then saves it back to the modified file. Simply add it to a `bashrc` file and called from the command-line:

``` bash
mod ()
{
    FILE=$1
    STAT=$(stat -c%y "$FILE")
    MTIME=$(date -d "$STAT")
    $EDITOR "$FILE"
    touch -d "$MTIME" "$FILE"
}
```

### Extended file attributes
To get `vim` to preserve extended file attributes when editing a file the following needs to be set:

```viml
set backupcopy=yes
```
