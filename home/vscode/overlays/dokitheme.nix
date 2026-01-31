self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # 1. Create the CSS block
      cat <<EOF > doki_sticker.css
<style>
  body > .monaco-workbench > .monaco-grid-view > .monaco-grid-branch-node > .monaco-split-view2 > .monaco-scrollable-element > .split-view-container::after {
    content: "";
    pointer-events: none;
    position: absolute;
    bottom: 0;
    right: 0;
    width: 400px; /* Adjusted size */
    height: 400px;
    z-index: 99999;
    background-image: url('sticker.png');
    background-position: bottom right;
    background-repeat: no-repeat;
    background-size: contain;
    opacity: 0.2;
  }
  
  /* Optional: Background image for the whole editor */
  .monaco-workbench {
    background-image: url('bg.png') !important;
    background-size: cover !important;
    background-position: center !important;
  }
</style>
EOF

      # 2. Iterate through potential workbench HTML files
      # This handles different VSCodium versions/structures
      find resources/app/out/vs -name "workbench.html" -or -name "workbench.esm.html" | while read html_file; do
        target_dir=$(dirname "$html_file")
        echo "Patching HTML at: $html_file"
        echo "Placing assets in: $target_dir"

        # Copy images directly next to the HTML file so url('file.png') works
        cp -f ${./bg.png} "$target_dir/bg.png"
        cp -f ${./sticker.png} "$target_dir/sticker.png"

        # Inject the CSS before the closing </head> tag
        # We use the 'r' (read) command which is more standard for multi-line injection
        sed -i '/<\/head>/e cat doki_sticker.css' "$html_file"
      done

      rm doki_sticker.css
    '';
  });
}