self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
            # 1. Identify the target file
            target=$(find . -name "workbench.desktop.main.js" | grep "workbench" | head -n 1)

            if [ -n "$target" ] && [ -f "$target" ]; then
              echo "Found target for decoration newline fix: $target"

              # 2. Create the patch file (using quoted Heredoc to prevent Nix/Bash evaluation)
              cat << 'EOF' > prefix.js
      ;(function() {
        const origInsertRule = CSSStyleSheet.prototype.insertRule;
        CSSStyleSheet.prototype.insertRule = function(rule, index) {
          if (rule && rule.includes("<NL>")) {
            // 1. Replace '<NL>' with the CSS linefeed character '\A' (\A requires being written as \\A in JS)
            // 2. Inject 'white-space: pre' and 'display: inline-block' to force the linefeed to render
            rule = rule
              .replace(/<NL>/g, "\\\\A")
              .replace(/(::after\s*\{[^}]+)/, "$1 white-space: pre !important; display: inline-block !important;");
          }
          return origInsertRule.call(this, rule, index);
        };
      })();
      EOF

              # 3. Prepend the fix to the main bundle
              cat prefix.js "$target" > "$target.tmp" && mv "$target.tmp" "$target"
              rm prefix.js
              echo "Successfully patched CSSStyleSheet to support <NL> replacements."
            else
              echo "Warning: workbench.desktop.main.js not found. Skipping patch."
            fi
    '';
  });
}
