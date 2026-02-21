# overlays/toLocaleStringFix/conf.nix
self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
            # In newer VSCodium, we might need to look in different spots
            # Use find to be safe, or check the specific 1.108 path
            target="resources/app/out/vs/workbench/workbench.desktop.main.js"

            if [ -f "$target" ]; then
              echo "Patching VS Code: injecting toLocaleString override"
              
              # Using a heredoc with 'EOF' (quoted) prevents Bash variable expansion
              cat << 'EOF' > temp_prefix.js
      ;[Number, String].map((e) => {
        var temp = e.prototype.toLocaleString.bind(e.prototype)
        e.prototype.toLocaleString = function (...a) {
          return this
        }
      });
      EOF
              # Prepend the fix to the file
              cat temp_prefix.js "$target" > "$target.tmp" && mv "$target.tmp" "$target"
            else
              echo "Warning: Target $target not found, skipping toLocaleString fix"
            fi
    '';
  });
}
