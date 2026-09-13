final: prev: {
  xemu = prev.xemu.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace system/vl.c \
        --replace-fail \
          'g_strdup_printf("index=0,media=disk,file=%s%s",' \
          'g_strdup_printf("index=0,media=disk,file=%s%s,cache=writeback,aio=threads",'
    '';
  });
}
