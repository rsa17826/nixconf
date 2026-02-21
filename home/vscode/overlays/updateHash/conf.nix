self: super: {
  vscode = super.vscode.overrideAttrs (oldAttrs: {
    # We add python3 to nativeBuildInputs to handle the JSON patching
    nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ self.python3 ];

    postFixup = (oldAttrs.postFixup or "") + ''
      # The path to product.json varies by platform; this finds it automatically
      PRODUCT_JSON=$(find $out -name product.json)

      python3 <<EOF
      import json
      import hashlib
      import base64
      import os

      def compute_checksum(filename):
          with open(filename, "rb") as f:
              content = f.read()
          # SHA256 in Base64 without padding
          sha256_hash = hashlib.sha256(content).digest()
          return base64.b64encode(sha256_hash).decode('utf-8').replace('=', ${"'"}')

      with open('$PRODUCT_JSON', 'r') as f:
          data = json.load(f)

      if 'checksums' in data:
          app_dir = os.path.dirname('$PRODUCT_JSON')
          # The app root is usually one level up from the 'out' directory
          # Adjusting path to find the actual source files
          base_path = os.path.join(os.path.dirname(app_dir), 'out')
          
          for file_path, old_hash in data['checksums'].items():
              full_path = os.path.join(base_path, file_path)
              if os.path.exists(full_path):
                  new_hash = compute_checksum(full_path)
                  data['checksums'][file_path] = new_hash
          
          with open('$PRODUCT_JSON', 'w') as f:
              json.dump(data, f, indent='\t')
      EOF
    '';
  });
}
# final: prev: {
#   vscodium = prev.vscodium.overrideAttrs (oldAttrs: {
#     nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [ prev.python3 ];

#     postFixup = (oldAttrs.postFixup or "") + ''
#       # VSCodium usually stores product.json in resources/app/
#       PRODUCT_JSON=$(find $out -name product.json | grep "resources/app/product.json" | head -n 1)

#       if [ -n "$PRODUCT_JSON" ]; then
#         echo "Patching VSCodium checksums in $PRODUCT_JSON"
#         python3 <<EOF
# import json, hashlib, base64, os

# def compute_checksum(filename):
#     with open(filename, "rb") as f:
#         return base64.b64encode(hashlib.sha256(f.read()).digest()).decode('utf-8').replace('=', '')

# with open('$PRODUCT_JSON', 'r') as f:
#     data = json.load(f)

# if 'checksums' in data:
#     # Path logic: checksums are relative to the 'out' directory in VS Code,
#     # but in VSCodium/Nixpkgs they are relative to the app root.
#     app_dir = os.path.dirname('$PRODUCT_JSON')

#     for file_path, _ in data['checksums'].items():
#         # Search for the file in the package output
#         full_path = os.path.join(app_dir, file_path)
#         if os.path.exists(full_path):
#             data['checksums'][file_path] = compute_checksum(full_path)

#     with open('$PRODUCT_JSON', 'w') as f:
#         json.dump(data, f, indent='\t')
# EOF
#       else
#         echo "Warning: product.json not found, skipping checksum patch."
#       fi
#     '';
#   });
# }
