self: super: {
  vscode = super.vscode.overrideAttrs (oldAttrs: {
    postFixup = (oldAttrs.postFixup or "") + ''
      # 1. Identify the product.json location
      PRODUCT_JSON="$out/lib/vscode/resources/app/product.json"

      # 2. Use a python script to recalculate checksums of the actual files
      # This mimics the logic in your TypeScript function
      ${super.python3}/bin/python3 <<EOF
      import json
      import hashlib
      import base64
      import os

      def compute_checksum(filename):
          with open(filename, "rb") as f:
              content = f.read()
              # VS Code uses MD5 hashed then Base64 encoded without padding
              m = hashlib.md5(content).digest()
              return base64.b64encode(m).decode('utf-8').replace("=", "")

      with open("$PRODUCT_JSON", "r") as f:
          data = json.load(f)

      if "checksums" in data:
          for rel_path, old_checksum in data["checksums"].items():
              # Construct absolute path to the file
              full_path = os.path.join("$out/lib/vscode/resources/app", rel_path)
              if os.path.exists(full_path):
                  new_checksum = compute_checksum(full_path)
                  data["checksums"][rel_path] = new_checksum

          with open("$PRODUCT_JSON", "w") as f:
              json.dump(data, f, indent='\t')
      EOF
    '';
  });
}
