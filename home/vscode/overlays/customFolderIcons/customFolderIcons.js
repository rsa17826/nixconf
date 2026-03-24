// 1. Create the master style tag ONCE
const USERHOME = "${USERHOME}"
const styleElement = document.createElement("style")
styleElement.id = "dynamic-folder-icons-style"
styleElement.textContent = `
  /* This rule stays static and just listens for the variable on the element */
  .folder-icon[data-has-custom-icon]::before {
    background-image: var(--folder-icon-url) !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
    content: "" !important;
    width: 16px;
    height: 16px;
    display: inline-block;
  }
`
document.head.appendChild(styleElement)

// 2. The function to update elements (no textContent rewriting needed)
const updateIcons = () => {
  const folders = document.querySelectorAll(
    ".folder-icon:not([data-has-custom-icon])"
  )

  folders.forEach((el) => {
    const path = el.getAttribute("aria-label")
    if (path) {
      // Convert path and format URL
      const formattedPath =
        path
          .replace(/\\/g, "/")
          .replace(/ • Contains emphasized items$/, "").replace(/^~/, USERHOME) + "/image.png"
      const vscodePath = `vscode-file://vscode-app/${formattedPath}`

      // Set the variable directly on the element's style
      el.style.setProperty(
        "--folder-icon-url",
        `url('${vscodePath}')`
      )
      // Mark as processed
      el.setAttribute("data-has-custom-icon", "true")
    }
  })
}

// 3. Setup MutationObserver to watch the Explorer list
const listContainer = document.querySelector(".monaco-list-rows")

if (listContainer) {
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.addedNodes.length > 0) {
        updateIcons()
        break
      }
    }
  })

  observer.observe(listContainer, { childList: true, subtree: true })

  // Initial trigger
  updateIcons()
  console.log("🎨 Folder icon observer is live.")
} else {
  console.error(
    "Could not find .monaco-list-rows. Is the Explorer visible?"
  )
}
