self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
            # 1. Identify the target file
            # We use find to ensure we catch it regardless of internal folder nesting
            target=$(find . -name "workbench.desktop.main.js" | grep "workbench" | head -n 1)

            if [ -n "$target" ] && [ -f "$target" ]; then
              echo "Found target for toLocaleString fix: $target"

              # 2. Create the patch file using a quoted Heredoc to avoid Bash evaluation
              cat << 'EOF' > prefix.js
      ;[Number, String].map((e) => {
        var temp = e.prototype.toLocaleString.bind(e.prototype)
        e.prototype.toLocaleString = function (...a) {
          return this
        }
      });
      EOF

              # 3. Prepend the fix to the main bundle
              cat prefix.js "$target" > "$target.tmp" && mv "$target.tmp" "$target"
              rm prefix.js
              echo "Successfully patched toLocaleString override."
            else
              echo "Warning: workbench.desktop.main.js not found. Skipping patch."
            fi
    '';
  });
}
