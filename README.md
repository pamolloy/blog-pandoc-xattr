# blog-pandoc-xattr
This masterly crafted computer science project sits proudly on the dull edge of technological innovation. A few short BASH scripts and HTML templates wrap `pandoc`, which generates static HTML files.

## File attributes
The values of regular and extended file attributes are passed to `pandoc` using `generate.bash`.

The Linux kernel stores in-memory representations of inodes within `struct inode`, which are derived by the low-level filesystem from on-disk inodes.[^brouwer] It appears that those representations persist in memory.[^21325] This does not garantuee that extended file attributes are treated the same way, and it may be dependent upon the filesystem implementation. For example, see [ext3/xattr.c](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/fs/ext3/xattr.c?id=HEAD), [ext4/xattr.c](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/tree/fs/ext4/xattr.c?id=HEAD), and [reiserfs/xattr.c](http://lxr.free-electrons.com/source/fs/reiserfs/xattr.c).

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
[^21325]: [Is the file table in the filesystem or in memory?](http://unix.stackexchange.com/questions/21325)
[^brouwer]: [The Linux Virtual File System](http://www.win.tue.nl/~aeb/linux/lk/lk-8.html) from notes by Andries Brouwer
