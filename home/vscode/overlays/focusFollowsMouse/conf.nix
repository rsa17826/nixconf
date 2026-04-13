self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    # 1. Pass the file content via an environment variable to avoid shell escaping issues
    js = builtins.readFile ./ffm.js;

    postPatch = (old.postPatch or "") + ''
      target="resources/app/out/vs/workbench/workbench.desktop.main.js"

      if [ ! -f "$target" ]; then
        echo "ERROR: VS Code bundle not found: $target"
        exit 1
      fi

      echo "Injecting focusFollowsMouse script into VS Code"
      # 2. Reference the variable we defined above using shell syntax
      echo "$js" >> "$target"
    '';
  });
}
