# #FFF to #FFF0
find . -name ".git" -prune -o -name ".foldericon.png" -exec magick "{}" -fuzz 1% -transparent "#ffffff" "{}" ';'
# find folders with no icons
c;find . -name ".git" -prune -o -type d ! -exec test -e "{}/.foldericon.png" ';' -print

find . -name ".git" -prune -o -name ".foldericon.png" -exec sh -c '
  # Check for white pixels
  WHITE_PIXELS=$(magick "$1" -fuzz 5% -format "%[fx:int(mean*w*h)]" info:)

  if [ "$WHITE_PIXELS" -gt 0 ]; then
    echo "Processing ($WHITE_PIXELS pixels): $1"

    # 1. Add write permission so we can actually edit the file
    chmod +w "$1"

    # 2. Perform the transparency conversion
    magick "$1" -strip -fuzz 5% -transparent "#ffffff" "$1"

    # 3. Optional: Set it back to read-only to match original Nix state
    chmod -w "$1"
  else
    echo "Skipping (already transparent): $1"
  fi
' _ {} ';'find . -name ".git" -prune -o -name ".foldericon.png" -exec sh -c '
  # Check for white pixels
  WHITE_PIXELS=$(magick "$1" -fuzz 5% -format "%[fx:int(mean*w*h)]" info:)

  if [ "$WHITE_PIXELS" -gt 0 ]; then
    echo "Processing ($WHITE_PIXELS pixels): $1"
    
    # 1. Add write permission so we can actually edit the file
    chmod +w "$1"
    
    # 2. Perform the transparency conversion
    magick "$1" -strip -fuzz 5% -transparent "#ffffff" "$1"
    
    # 3. Optional: Set it back to read-only to match original Nix state
    chmod -w "$1"
  else
    echo "Skipping (already transparent): $1"
  fi
' _ {} ';'