self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # 1. Prepare the CSS content in a temporary file to avoid sed newline issues
      cat <<EOF > doki_sticker.css
<style>
  body > .monaco-workbench > .monaco-grid-view > .monaco-grid-branch-node > .monaco-split-view2 > .monaco-scrollable-element > .split-view-container::after {
    content: "";
    pointer-events: none;
    position: absolute;
    bottom: 0;
    right: 0;
    width: 100%;
    height: 100%;
    z-index: 99999;
    background-image: url('sticker.png');
    background-position: 100% 100%;
    background-repeat: no-repeat;
    background-size: 300px auto;
    opacity: 0.15;
  }
</style>
EOF

      # 2. Copy the sticker image (assuming bg.png is in the same directory as your nix file)
      # We put it where the HTML can find it via relative path
      mkdir -p resources/app/out/vs/workbench
      cp -f ${./bg.png} resources/app/out/vs/workbench/sticker.png

      # 3. Inject the CSS into workbench.html
      # We use 'sed' to find </head> and 'r' (read) our file before it
      find resources/app/out/vs/code -name "workbench.html" -or -name "workbench.esm.html" | while read html_file; do
        echo "Patching \$html_file with Doki sticker..."
        
        # This sed command finds the line with </head> and 
        # reads (r) the file doki_sticker.css right before it.
        sed -i '/<\/head>/e cat doki_sticker.css' "$html_file"
      done

      # Cleanup temp file
      rm doki_sticker.css
    '';
  });
}