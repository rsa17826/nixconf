self: super: {
  vscodium = super.vscodium.overrideAttrs (oldAttrs: {
    # We use jq to modify the json directly
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ super.jq ];

    postFixup = (oldAttrs.postFixup or "") + ''
      # Find the product.json (it's often in different places depending on version)
      PJSON=$(find $out -name product.json)

      if [ -f "$PJSON" ]; then
        echo "Fixing checksums in $PJSON..."
        chmod +w "$PJSON"
        # Removing the checksums key tells VSCodium to skip the check entirely
        ${super.jq}/bin/jq 'del(.checksums)' "$PJSON" > "$PJSON.tmp" && mv "$PJSON.tmp" "$PJSON"
      else
        echo "Could not find product.json to fix checksums!"
      fi
    '';
  });
}
