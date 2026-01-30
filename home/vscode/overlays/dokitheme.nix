final: prev: {
  vscode = prev.vscode.overrideAttrs (oldAttrs: {
    postInstall = (oldAttrs.postInstall or "") + ''
      # Find the workbench HTML file
      workbench_html=$(find $out -name "workbench.html")

      # Inject code to load a custom CSS file from your home directory
      # This bypasses the read-only limitation by making VS Code load an external file
      sed -i 's|</body>|<link rel="stylesheet" href="file:///home/nyx/.config/Code/User/doki-custom.css"/></body>|' "$workbench_html"
    '';
  });
}
