self: super: {
  vscodium = super.vscodium.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      # 1. Create the CSS block
      cat <<EOF > doki_sticker.css
<style>
  body > .monaco-workbench > .monaco-grid-view > .monaco-grid-branch-node > .monaco-split-view2 > .monaco-scrollable-element > .split-view-container::after {
    content: "";
    pointer-events: none;
    position: absolute;
    bottom: 0;
    right: 0;
    width: 400px; /* Adjusted size */
    height: 400px;
    z-index: 99999;
    background-image: url('sticker.png');
    background-position: bottom right;
    background-repeat: no-repeat;
    background-size: contain;
    opacity: 0.2;
  }
  /* Hide Watermark */
  .monaco-workbench .part.editor.has-watermark>.content.empty .editor-group-container>.editor-group-letterpress,
  .part.editor>.content .editor-group-container .editor-group-watermark>.letterpress,
  .monaco-workbench .part.editor>.content .editor-group-container>.editor-group-watermark>.shortcuts>.watermark-box,
  .monaco-workbench .part.editor>.content.empty>.watermark>.watermark-box 
  {
    display: none !important;
  }
  /* Background Image */
  [id="workbench.parts.editor"] .split-view-view .editor-container .editor-instance>.monaco-editor .overflow-guard>.monaco-scrollable-element>.monaco-editor-background{background: none;}


  [id="workbench.parts.editor"] .split-view-view .editor-container .editor-instance>.monaco-editor  .overflow-guard>.monaco-scrollable-element::before,
  .overflow-guard,
  .tab,
  /* settings UI */
  .settings-editor>.settings-body .settings-toc-container,
  /* end settings UI */
  .tabs-container,
  .monaco-pane-view, 
  .composite.title,
  /* welcome window */
  .editor-container,
  button.getting-started-category,
  /* end welcome window */
  div.header, /* extensions header */
  .content,
  /* terminal stuff */
  .terminal .xterm,
  .monaco-workbench .pane-body.integrated-terminal .terminal-wrapper,
  .xterm .xterm-screen canvas,
  /* end terminal stuff */
  .monaco-select-box,
  .pane-header, 
  .minimap-decorations-layer,
  .xterm-cursor-layer,
  .monaco-breadcrumbs,
  /* sticky lines */
  .monaco-editor .sticky-line-content,
  .monaco-editor .sticky-line-number,
  .monaco-list .monaco-scrollable-element .monaco-tree-sticky-container .monaco-tree-sticky-row.monaco-list-row,
  /* end sticky lines */
  .decorationsOverviewRuler,
  .monaco-workbench .part.editor>.content .editor-group-container>.title .tabs-breadcrumbs .breadcrumbs-control,
  .ref-tree, /* find usages */
  .head, /* find usages */
  .monaco-workbench .part.editor>.content .editor-group-container>.title .editor-actions,  
  .welcomePageFocusElement /* welcome screen */
  /*.terminal-outer-container  Terminal outer edge */
  {
    background-image: url('bg.png') !important;
    background-position: center !important;
    /* background-position: $\{backgroundAnchoring} !important;*/
    background-attachment: fixed !important;
    background-repeat: no-repeat !important;
    background-size: cover !important;
  }
  
  /*settings UI */
  .monaco-list.list_id_1 .monaco-list-rows,
  .settings-tree-container > .monaco-list > .monaco-scrollable-element > .monaco-list-rows,
  .monaco-list.list_id_2:not(.drop-target) .monaco-list-row:hover:not(.selected):not(.focused),
  /* source control diff editor */  
  .lines-content.monaco-editor-background,
  /* output panel */
  .overflow-guard > .margin,
  .overflow-guard > .margin > .margin-view-overlays,
  .monaco-workbench .part.panel > .content .monaco-editor .monaco-editor-background,
  /* debugger panel */
  [id="workbench.panel.repl"] *
   {
    background-color: transparent !important;
  }

  .quick-input-widget
  {
    backdrop-filter: blur(5px) !important;
  }

  .monaco-breadcrumbs {
    background-color: #00000000 !important;
  }

  [id="workbench.view.explorer"] .monaco-list-rows,
  [id="workbench.view.explorer"] .pane-header,
  [id="workbench.view.explorer"] .monaco-pane-view,
  [id="workbench.view.explorer"] .split-view-view,
  [id="workbench.view.explorer"] .monaco-tl-twistie,
  [id="terminal"] .pane-header,
  [id="terminal"] .monaco-pane-view,
  .explorer-folders-view > .monaco-list > .monaco-scrollable-element > .monaco-list-rows,
  .show-file-icons > .monaco-list > .monaco-scrollable-element > .monaco-list-rows,
  .extensions-list > .monaco-list > .monaco-scrollable-element > .monaco-list-rows,
  div.details .header-container .header, /* extension list tree*/
  /* Welcome Page */
  .monaco-workbench .part.editor>.content .gettingStartedContainer .gettingStartedSlideCategories>.gettingStartedCategoriesContainer>.header,
  .monaco-workbench .part.editor>.content .gettingStartedContainer .gettingStartedSlideCategories .getting-started-category
  /* end welcome page */
  {
    background-color: #00000000 !important;
    background-image: none !important;
    border: none !important;
  }

  .monaco-icon-label-container {
    background: none !important;
  }
</style>
EOF

      # 2. Iterate through potential workbench HTML files
      # This handles different VSCodium versions/structures
      find resources/app/out/vs -name "workbench.html" -or -name "workbench.esm.html" | while read html_file; do
        target_dir=$(dirname "$html_file")
        echo "Patching HTML at: $html_file"
        echo "Placing assets in: $target_dir"

        # Copy images directly next to the HTML file so url('file.png') works
        cp -f ${./bg.png} "$target_dir/bg.png"
        cp -f ${./sticker.png} "$target_dir/sticker.png"

        # Inject the CSS before the closing </head> tag
        # We use the 'r' (read) command which is more standard for multi-line injection
        sed -i '/<\/head>/e cat doki_sticker.css' "$html_file"
      done

      rm doki_sticker.css
    '';
  });
}