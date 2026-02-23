final: prev: {
  vscodium = prev.vscodium.overrideAttrs (oldAttrs: {
    # We use postFixup to ensure we're modifying the final binaries
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ prev.tinyxxd ];
    postFixup = (oldAttrs.postFixup or "") + ''
      # Path to product.json inside the nix store output
      PRODUCT_JSON="$out/lib/vscode/resources/app/product.json"

      # Check if jq is available (it usually is in the build env, or add to nativeBuildInputs)
      # This script recreates the checksums for all files currently in the workbench
      echo "Patching VSCodium checksums..."

      # We need to find the files that were modified. 
      # The Doki theme usually modifies:
      # out/vs/workbench/workbench.desktop.main.css
      # out/vs/workbench/workbench.desktop.main.js

      APP_DIR="$out/lib/vscode/resources/app"

      # Helper function to get base64 md5 hash (VS Code's format)
      get_hash() {
        local file=$1
        # VS Code uses MD5 hashed then base64 encoded
        md5sum "$file" | cut -d' ' -f1 | xxd -r -p | base64 | tr -d '\n'
      }

      # List of files to re-hash (add any others modified by your theme)
      FILES=(
        "out/vs/workbench/workbench.desktop.main.css"
        "out/vs/workbench/workbench.desktop.main.js"
      )

      # Create a temporary product.json
      cp "$PRODUCT_JSON" "$PRODUCT_JSON.tmp"
      chmod +w "$PRODUCT_JSON.tmp"

      for FILE in "''${FILES[@]}"; do
        if [ -f "$APP_DIR/$FILE" ]; then
          HASH=$(get_hash "$APP_DIR/$FILE")
          echo "New hash for $FILE: $HASH"
          
          # Use jq to update the specific file hash in the checksums object
          # Note: we use --arg to safely pass strings to jq
          ${prev.jq}/bin/jq --arg file "$FILE" --arg hash "$HASH" \
            '.checksums[$file] = $hash' "$PRODUCT_JSON.tmp" > "$PRODUCT_JSON.tmp.2" && mv "$PRODUCT_JSON.tmp.2" "$PRODUCT_JSON.tmp"
        fi
      done

      # Overwrite the original product.json
      mv "$PRODUCT_JSON.tmp" "$PRODUCT_JSON"
    '';
  });
}
