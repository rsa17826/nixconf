#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 file" >&2
  exit 1
fi

file=$1

awk '
BEGIN {
    in_userstyle = 0
}

# Detect UserStyle metadata block.
# Adjust these if your delimiters differ.
/^/\* ==UserStyle==/ {
    in_userstyle = 1
    print
    next
}

/^ *==\/UserStyle==/ {
    in_userstyle = 0
    print
    next
}

{
    if (in_userstyle || /@-moz-document/) {
        print
        next
    }

    line = $0

    while (match(line, /https?:\/\/[^")'\''[:space:]]+/)) {
        url = substr(line, RSTART, RLENGTH)

        cmd = "curl -Ls \"" url "\" | base64 -w0"
        cmd | getline b64
        close(cmd)

        mime = "application/octet-stream"
        mcmd = "curl -LsI \"" url "\" | awk '\''tolower($1)==\"content-type:\"{print $2; exit}'\'' | tr -d \"\\r\""
        mcmd | getline type
        close(mcmd)

        if (type != "")
            mime = type

        data = "data:" mime ";base64," b64

        line = substr(line,1,RSTART-1) data substr(line,RSTART+RLENGTH)
    }

    print line
}
' "$file"
