final: prev: {
  xemu = prev.xemu.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./xemu-hdd-cache-writeback.patch
    ];
  });
}
