self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      target="resources/app/out/vs/workbench/workbench.desktop.main.js"

      if [ ! -f "$target" ]; then
        echo "ERROR: VS Code bundle not found: $target"
        exit 1
      fi

      # Read owoify.js script and inject it
      owoify_script=${builtins.readFile ./owoify.js}
      echo "Injecting owoify.js script into VS Code"
      echo "$owoify_script" >> "$target"
    '';
  });
}
