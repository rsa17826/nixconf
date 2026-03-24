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

const updateIcons = () => {
  // Use a data attribute to avoid re-processing if needed,
  // though checking the style variable is also fine.
  const folders = document.querySelectorAll(".folder-icon")

  folders.forEach((el) => {
    const path = el.getAttribute("aria-label")
    if (!path) return

    // 1. Clean and Format the Path
    // We keep the leading slash for absolute paths after the protocol
    let cleanPath = path
      .replace(/\\/g, "/")
      .replace(/ • Contains emphasized items$/, "")
      .replace(/^~/, USERHOME)

    // Ensure it starts with a / so vscode-app/ + /home/... works correctly
    if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

    const iconUrl = `vscode-file://vscode-app${cleanPath}/image.png`

    // 2. Correct way to get current style properties
    const lastTried = el.style.getPropertyValue(
      "--tried-folder-icon-url"
    )

    if (lastTried !== iconUrl) {
      el.style.setProperty("--tried-folder-icon-url", iconUrl)

      // 3. Fix fetch syntax (method: 'HEAD' is more efficient than GET)
      fetch(iconUrl, { method: "HEAD" })
        .then((response) => {
          if (response.ok) {
            el.style.setProperty(
              "--folder-icon-url",
              `url('${iconUrl}')`
            )
            el.setAttribute("data-has-custom-icon", "true")
          }
        })
        .catch(() => {
          // Silent catch if image doesn't exist
        })
    }
  })
}

// 3. Setup MutationObserver to watch the Explorer list
;(async () => {
  while (1) {
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

      observer.observe(listContainer, {
        childList: true,
        subtree: true,
      })

      // Initial trigger
      updateIcons()
      console.log("🎨 Folder icon observer is live.")
      return
    } else {
      console.error(
        "Could not find .monaco-list-rows. Is the Explorer visible?"
      )
      await new Promise((resolve) => {
        setTimeout(resolve, 100)
      })
    }
  }
})()
