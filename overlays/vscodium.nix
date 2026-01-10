self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      target="resources/app/out/vs/workbench/workbench.desktop.main.js"

      if [ ! -f "$target" ]; then
        echo "ERROR: VS Code bundle not found: $target"
        exit 1
      fi

      echo "Patching VS Code: injecting toLocaleString override"

      sed -i '1i\
;[Number, String].map((e) => {\
  var temp = e.prototype.toLocaleString.bind(e.prototype)\
  e.prototype.toLocaleString = function (...a) {\
    return this\
  }\
})\
' "$target"
    '';
  });
}
