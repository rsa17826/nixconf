# #FFF to #FFF0
find . -name ".git" -prune -o -name ".foldericon.png" -exec magick "{}" -fuzz 1% -transparent "#ffffff" "{}" ';'
# find folders with no icons
c;find . -name ".git" -prune -o -type d ! -exec test -e "{}/.foldericon.png" ';' -print
