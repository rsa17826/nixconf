self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    # We use postPatch to inject the CSS and sticker before the installation phase.
    # This assumes the standard Nixpkgs vscodium derivation which unpacks the binary.
    postPatch = (old.postPatch or "") + ''
      # 1. Define the Sticker URL (You can change this to any image)
      # This example uses a generic Doki-like placeholder or you can fetch one.
      sticker_url="https://doki.assets.unthrottled.io/stickers/v2/rwby/ruby/secondary/sticker.png"

      # 2. Download the sticker to the resources directory
      # We place it in 'resources/app/out/vs/workbench' so it's accessible relative to the HTML
      mkdir -p resources/app/out/vs/workbench
      copy -f ${./bg.png} resources/app/out/vs/workbench/sticker.png

      # 3. Define the CSS to inject
      # This mimics the Doki Theme CSS:
      # - Targets the workbench container
      # - Adds a pseudo-element with the background image
      # - Positions it in the bottom-right corner
      # - Sets opacity and pass-through events
      custom_css="
      <style>
      /* Main Workbench Container Sticker Injection */
      body > .monaco-workbench > .monaco-grid-view > .monaco-grid-branch-node > .monaco-split-view2 > .monaco-scrollable-element > .split-view-container::after {
        content: '${"'"};
        pointer-events: none;
        position: absolute;
        bottom: 0;
        right: 0;
        width: 100%;
        height: 100%;
        z-index: 99999;
        background-image: url('sticker.png'); /* Relative to workbench.html */
        background-position: 100% 100%;
        background-repeat: no-repeat;
        background-size: 300px auto; /* Adjust size as needed */
        opacity: 0.1; /* Adjust opacity (0.1 to 1.0) */
      }
      </style>
      "

      # 4. Inject the CSS into workbench.html
      # We look for the closing </head> tag and insert our style before it.
      # Note: The path to workbench.html varies slightly by version.
      # Common paths:
      # - resources/app/out/vs/code/electron-sandbox/workbench/workbench.html (Newer)
      # - resources/app/out/vs/code/electron-browser/workbench/workbench.html (Older)

      find resources/app/out/vs/code -name "workbench.html" -or -name "workbench.esm.html" | while read html_file; do
        echo "Patching \$html_file with sticker..."
        # Use sed to insert the CSS before </head>
        #We escape the CSS for sed using a temporary file or careful escaping
        # Here we append it to the file just before the end for simplicity or use perl/sed
        
        # Simple injection at the end of <head>
        sed -i "s|</head>|$custom_css</head>|" "\$html_file"
      done
    '';
  });
}
