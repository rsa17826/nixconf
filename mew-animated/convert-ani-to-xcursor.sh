#!/nix/store/imad8dvhp77h0pjbckp6wvmnyhp8dpgg-coreutils-9.8/bin/env bash

# Ensure the script receives an .ani file as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <cursor.ani>"
    exit 1
fi

ANI_FILE="$1"
CURSOR_NAME=$(basename "$ANI_FILE" .ani)
DEST_DIR="$HOME/.icons/MyCursor/cursors"

# Create destination directory if not exists
mkdir -p "$DEST_DIR"

# Extract frames using icotool
echo "Extracting frames from $ANI_FILE..."
icotool -x "$ANI_FILE"

# Create the cursor config file
echo "Creating cursor configuration..."

# Generate frame and delay info
frame_index=0
cursor_config="${CURSOR_NAME}.cursor"
echo "" > "$cursor_config"

# Process each extracted frame (handle spaces in filenames)
for frame in *.png; do
    if [[ -f "$frame" ]]; then
        # Using a default delay of 100ms, can be customized later
        delay=100

        # Add frame to config with proper escaping
        echo "32 0 0 \"$frame\" $delay" >> "$cursor_config"

        frame_index=$((frame_index + 1))
    fi
done

# Generate the animated cursor using xcursorgen
echo "Generating animated cursor..."
xcursorgen "$cursor_config" "$CURSOR_NAME"

# Move the generated cursors to the destination directory
mv "$CURSOR_NAME" "$DEST_DIR"

# Clean up temporary frames and config file
rm *.png "$cursor_config"

echo "Cursor theme created in $DEST_DIR"
