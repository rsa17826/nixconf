const USERHOME = "${USERHOME}"
const styleElement = document.createElement("style")
styleElement.id = "dynamic-folder-icons-style"
styleElement.textContent = `
  .folder-icon[data-has-custom-icon="true"]::before {
    background-image: var(--folder-icon-url) !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
    content: "" !important;
    width: 16px;
    height: 16px;
    position:relative;
    left:-2px;
    display: inline-block;
  }
  .file-icon[data-has-custom-icon="true"]::after {
    background-image: var(--folder-icon-url) !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
    content: "" !important;
    width: 16px;
    height: 16px;
    position: relative;
    left: -2px;
    display: inline-block;
  }
`
document.head.appendChild(styleElement)

async function findIconUpwards(currentPath) {
  if (!currentPath || currentPath === "/" || currentPath === ".")
    return null

  const promise = (async () => {
    const iconUrl = `vscode-file://vscode-app${currentPath}/.foldericon.png`
    try {
      const response = await fetch(iconUrl, { method: "HEAD" })
      if (response.ok) return iconUrl
    } catch (e) {}

    const parentPath = currentPath.substring(
      0,
      currentPath.lastIndexOf("/"),
    )
    return findIconUpwards(parentPath)
  })()

  return promise
}

const updateIcons = async () => {
  const folders = document.querySelectorAll(".folder-icon")
  const files = document.querySelectorAll(".file-icon")
  const iconCache = new Map()

  await Promise.all(
    Array.from(folders).map(async (el) => {
      const path = el.getAttribute("aria-label")
      if (!path) return

      let cleanPath = path
        .replace(/\\/g, "/")
        // .replace(/ • Contains emphasized items$/, "")
        // .replace(/ • Symbolic Link$/, "")
        .replace(/ • [ \w]+$/, "")
        .replace(/^~/, USERHOME)
      if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

      const foundUrl = await findIconUpwards(cleanPath)
      if (foundUrl) {
        iconCache.set(cleanPath, foundUrl)
        el.style.setProperty(
          "--folder-icon-url",
          `url('${foundUrl}')`,
        )
        el.setAttribute("data-has-custom-icon", "true")
      } else {
        iconCache.set(cleanPath, null)
        // el.removeAttribute("data-has-custom-icon")
      }
    }),
  )

  for (var el of files) {
    const path = el.getAttribute("aria-label")
    if (!path) continue

    let cleanPath = path
      .replace(/\\/g, "/")
      .replace(/ • [ \w]+$/, "")
      .replace(/^~/, USERHOME)
    cleanPath = cleanPath.substring(0, cleanPath.lastIndexOf("/"))
    if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

    const iconel = el.querySelector(".monaco-icon-label-container")
    if (!iconel) continue

    const foundUrl = iconCache.get(cleanPath)
    if (foundUrl) {
      el.style.setProperty("--folder-icon-url", `url('${foundUrl}')`)
      iconel.setAttribute("data-has-custom-icon", "true")
    } else {
      // iconel.removeAttribute("data-has-custom-icon")
    }
  }
}

;(async () => {
  while (true) {
    const listContainer = document.querySelector(".monaco-list-rows")
    if (listContainer) {
      const observer = new MutationObserver(() => updateIcons())
      observer.observe(listContainer, {
        childList: true,
        subtree: true,
      })
      updateIcons()
      console.log("🎨 Recursive Folder icon observer is live.")
      return
    }
    await new Promise((r) => setTimeout(r, 500))
  }
})()
