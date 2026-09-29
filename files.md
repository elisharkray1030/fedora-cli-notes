# Files

Navigating, finding, and moving files around.

## Moving around

```bash
pwd                                   # where am I
ls -lah                               # long listing, human-readable sizes, hidden files
ls -laFt                              # newest first
cd -                                  # back to previous directory
cd ~                                  # home
pushd /tmp && popd                    # stack-based navigation
```

Prefer `fd` and `rg` if installed (much faster and friendlier than `find`/`grep`):

```bash
sudo dnf install fd-find ripgrep bat tree
fd <name>                             # find by name
fd -e pdf                            # find by extension
fd -t d <name>                        # directories only
rg <pattern>                          # recursive content search
rg -i <pattern> -g '*.md'             # case-insensitive, markdown only
bat <file>                            # cat with syntax highlighting
```

## Finding files with find

```bash
find . -name '*.log'                  # by name (case-sensitive)
find . -iname '*.log'                 # case-insensitive
find . -type d -name 'node_modules'
find . -type f -size +100M            # files over 100 MB
find . -mtime -1                      # modified in the last 24h
find . -mtime +30                     # older than 30 days
find . -user <user>
find . -perm -o+w                     # world-writable (security check)
find . -name '*.tmp' -delete          # delete (be careful!)
find . -type f -exec grep -l '<text>' {} +   # grep across files
```

## If dnf's `fd-find` installed `fd`, alias it

```bash
alias fd='fdfind'   # only needed on some setups; Fedora generally ships `fd`
```

## Searching inside files

```bash
grep -rin '<text>' .                  # recursive, case-insensitive, with line numbers
grep -rl '<text>' .                   # just filenames
grep -v '<text>' file                 # lines NOT matching
grep -E '<regex>' file                # extended regex
grep -A3 -B3 '<text>' file            # 3 lines after/before context
rg -n --hidden -g '!.git' '<text>'    # ripgrep, include hidden, skip .git
```

## Viewing files

```bash
less <file>                           # scrollable pager (q to quit, / to search)
head -n 20 <file>
tail -n 20 <file>
tail -f <file>                        # follow a growing log
wc -l <file>                          # count lines
file <file>                           # what type is this really
cat -n <file>                         # number lines
```

## Copy, move, remove

```bash
cp -r <dir> <dest>                    # recursive copy
cp -a <src> <dest>                    # preserve permissions/timestamps/links
mv <src> <dest>
rm <file>
rm -r <dir>
rm -rf <dir>                          # no prompts — use with care
rmdir <emptydir>
mkdir -p a/b/c
```

## Symlinks and links

```bash
ln -s /path/to/target <linkname>      # symbolic link
ln <file> <hardlink>                  # hard link
readlink -f <link>                    # resolve to the real path
ls -la | grep -- '->'                 # show symlinks
```

Dotfiles trick — keep real files in a repo and symlink them home:

```bash
ln -s ~/dotfiles/.bashrc ~/.bashrc
```

## Permissions and ownership

```bash
chmod +x <script>                     # make executable
chmod 644 <file>                      # rw-r--r--
chmod 755 <dir>                       # rwxr-xr-x
chmod -R u+rwX <dir>                  # add owner rw; X = dirs/traverse
chown <user>:<group> <file>
sudo chown -R <user>:<user> <dir>
```

Access Control Lists (fine-grained permissions):

```bash
getfacl <file>
setfacl -m u:<user>:rw <file>
setfacl -x u:<user> <file>
```

Special bits and the sticky bit:

```bash
chmod u+s <file>                      # setuid
chmod g+s <dir>                       # setgid (inherit group)
chmod +t <dir>                        # sticky (only owner deletes)
```

## Archives and compression

```bash
tar -czf archive.tar.gz <dir>         # create gzip tarball
tar -xzf archive.tar.gz               # extract here
tar -xzf archive.tar.gz -C /tmp       # extract elsewhere
tar -tzf archive.tar.gz               # list contents without extracting
zip -r archive.zip <dir>
unzip archive.zip -d <dest>
unzip -l archive.zip                  # list contents
xz -9 <file>                          # heavy compression
zstd -19 <file>                       # fast + strong compression
```

## Syncing with rsync

```bash
rsync -avh <src>/ <dest>/             # archive, verbose, human-readable (trailing / matters)
rsync -avh --progress <src>/ <dest>/
rsync -avh --delete <src>/ <dest>/    # mirror: delete extras at destination
rsync -avh -e ssh <src>/ user@host:<dest>/
rsync -avhn --delete <src>/ <dest>/   # dry run (-n) — do this first!
```

## Comparing and hashing

```bash
diff -u <file1> <file2>
diff -rq <dir1> <dir2>                # which files differ
cmp <file1> <file2>
sha256sum <file>
sha256sum -c checksums.txt            # verify a manifest
md5sum <file>
```

## Disk usage

```bash
du -sh <dir>                          # total size of a directory
du -h --max-depth=1 . | sort -h       # sizes of immediate subdirs
du -ah . | sort -rh | head -20        # 20 biggest files/dirs under here
df -h                                 # free space per filesystem
ncdu                                  # interactive disk usage browser
```

## Trash instead of rm

```bash
gio trash <file>                      # send to Trash
gio trash --list
gio trash --empty
```

## Watch a directory for changes

```bash
inotifywait -m -r <dir>               # requires inotify-tools
watch -n2 'ls -lah <dir>'             # re-run a command every 2s
```
