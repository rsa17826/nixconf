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
    position: relative;
    left: -2px;
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

function makeIconFinder(cache) {
  async function findIconUpwards(currentPath) {
    if (!currentPath || currentPath === "/" || currentPath === ".")
      return null
    if (cache.has(currentPath)) return cache.get(currentPath)

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

    cache.set(currentPath, promise)
    return promise
  }
  return findIconUpwards
}

const updateIcons = async () => {
  // Fresh cache per update — no stale results, no cross-update pollution
  const cache = new Map()
  const findIconUpwards = makeIconFinder(cache)

  const all = [
    ...document.querySelectorAll(".folder-icon"),
    ...document.querySelectorAll(".file-icon"),
  ]

  await Promise.all(
    all.map(async (el) => {
      const path = el.getAttribute("aria-label")
      if (!path) return

      const isFile = el.classList.contains("file-icon")

      let cleanPath = path
        .replace(/\\/g, "/")
        .replace(/ • [ \w]+$/, "")
        .replace(/^~/, USERHOME)

      if (isFile)
        cleanPath = cleanPath.substring(0, cleanPath.lastIndexOf("/"))
      if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

      const foundUrl = await findIconUpwards(cleanPath)
      if (foundUrl) {
        el.style.setProperty(
          "--folder-icon-url",
          `url('${foundUrl}')`,
        )
        el.setAttribute("data-has-custom-icon", "true")
      } else {
        el.style.removeProperty("--folder-icon-url")
        el.removeAttribute("data-has-custom-icon")
      }
    }),
  )
}

;(async () => {
  while (true) {
    const listContainer = document.querySelector(".monaco-list-rows")
    if (listContainer) {
      const observer = new MutationObserver(() => updateIcons())
      observer.observe(listContainer, {
        childList: true,
        subtree: true,
        attributeFilter: ["aria-label"],
      })
      updateIcons()
      console.log("🎨 Recursive Folder icon observer is live.")
      return
    }
    await new Promise((r) => setTimeout(r, 500))
  }
})()
