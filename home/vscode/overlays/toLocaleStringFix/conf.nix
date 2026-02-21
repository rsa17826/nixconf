# overlays/toLocaleStringFix/conf.nix
self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # Define the patch in a variable (Nix will handle the string safely here)
      patch_code=';[Number, String].map((e) => { var temp = e.prototype.toLocaleString.bind(e.prototype); e.prototype.toLocaleString = function (...a) { return this; } });'

      # Prepend using a temporary file (The most robust way in a Nix builder)
      echo "$patch_code" | cat - "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    '';
  });
}
