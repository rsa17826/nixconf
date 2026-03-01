#!/bin/bash

DB_PATH="$HOME/keepassdb/keepass.kdbx"

# 1. Get the current Window Title
WINDOW_TITLE=$(hyprctl activewindow -j | jq -r '.title')
WINDOW_TITLE="https://portal.my.vccs.edu/idp/AuthnEngine#/authn"

# 1. Securely get Master Password using pinentry
# This creates a pop-up that grabs focus and hides input
# KP_PASS=$(echo -e "SETDESC Enter KeePass Master Password\nGETPIN" | pinentry | grep "^D " | sed 's/^D //')

# 2. Securely export only Title and URL to a variable (Metadata only)
# We use CSV format: "Group","Title","Username","URL","Notes"
# We extract only the Title (Index 2) and URL (Index 4)
#!/bin/bash

# 2. Export Metadata (Stripping passwords immediately with awk)
# Note: Adjust $5 to $3 if your URL is in the 3rd column based on previous tests
SAFE_DATA=$(echo "$KP_PASS" | keepassxc-cli export --format csv "$DB_PATH" | awk -v FPAT='([^,]+)|("[^"]+")' 'BEGIN {OFS=","} {print $1,$2,$5}')

MATCHED_PATH=""

while IFS=',' read -r group title url; do
  c_group=$(echo "$group" | tr -d '"')
  c_title=$(echo "$title" | tr -d '"')
  c_url=$(echo "$url" | tr -d '"')

  if [[ -n "$c_url" && "$WINDOW_TITLE" == *"$c_url"* ]] ||
    [[ -n "$c_title" && "$WINDOW_TITLE" == *"$c_title"* ]]; then

    # FIX: Strip the first part of the path (the Database/Root name)
    # This converts "Database/school/school" -> "school/school"
    MATCHED_PATH=$(echo "${c_group}/${c_title}" | cut -d'/' -f2-)
    break
  fi
done <<<"$SAFE_DATA"

# 3. Targeted Extraction
if [ -n "$MATCHED_PATH" ]; then
  echo "Using Normalized Path: $MATCHED_PATH"

  # We use a function to avoid repeating the 'echo $KP_PASS | ...' logic
  get_attr() {
    echo "$KP_PASS" | keepassxc-cli show "$DB_PATH" "$MATCHED_PATH" --all
  }

  # Fetch sequence
  SEQ=$(get_attr "Auto-Type")
  SEQ=${SEQ:-"{USERNAME}{TAB}{PASSWORD}{ENTER}"}

  # Execute Sequence
  echo "$SEQ"
  # echo "$SEQ" | grep -oP '\{[A-Z0-9_-]+\}|[^{]+' | while read -r PART; do
  #   case "$PART" in
  #   "{USERNAME}") echo "$(get_attr username)" ;;
  #   "{PASSWORD}") echo "$(get_attr password)" ;;
  #   "{TAB}") echo -k Tab ;;
  #   "{ENTER}") echo -k Return ;;
  #   "{TOTP}" | "{KPOTP}")
  #     echo "$(echo "$KP_PASS" | keepassxc-cli totp "$DB_PATH" "$MATCHED_PATH")"
  #     ;;
  #   *) echo "$PART" ;;
  #   esac
  # done
else
  echo "No match found."
fi
