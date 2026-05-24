self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    style = builtins.readFile ./style.css;

    postPatch = (old.postPatch or "") + ''
      target="resources/app/out/vs/workbench/workbench.desktop.main.css"

      if [ ! -f "$target" ]; then
        echo "ERROR: VS Code bundle not found: $target"
        exit 1
      fi

      echo "Injecting pythonSmallSpaces script into VS Code"
      echo "$style" >> "$target"
    '';
  });
}
