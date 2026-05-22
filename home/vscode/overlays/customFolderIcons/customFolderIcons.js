// @ts-nocheck
const USERHOME = "${USERHOME}"
const styleElement = document.createElement("style")
styleElement.id = "dynamic-folder-icons-style"
styleElement.textContent = `
  .folder-icon[data-has-custom-icon="true"]::before,
  .folder-icon[data-has-custom-icon="true"]::after {
    background-image: var(--folder-icon-url) !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
    content: "" !important;
    width: 16px;
    height: 16px;
    position: relative;
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
    display: inline-block;
  }
  .folder-icon[data-has-custom-icon="true"]::before{
    width: 14px !important;
    height: 14px !important;
  }
`
document.head.appendChild(styleElement)

// Global cache: path -> resolved url|null (never promises, only settled values)
const globalIconCache = new Map()

async function fetchIconUpwards(currentPath) {
  if (!currentPath || currentPath === "/" || currentPath === ".")
    return null
  const iconUrl = `vscode-file://vscode-app${currentPath}/.foldericon.png`
  try {
    const response = await fetch(iconUrl, { method: "HEAD" })
    if (response.ok) return iconUrl
  } catch (e) {}
  const parentPath = currentPath.substring(
    0,
    currentPath.lastIndexOf("/"),
  )
  return fetchIconUpwards(parentPath)
}

function makeIconFinder(localCache) {
  async function findIconUpwards(currentPath) {
    if (!currentPath || currentPath === "/" || currentPath === ".")
      return null
    if (localCache.has(currentPath))
      return localCache.get(currentPath)

    // Global cache hit: return immediately, refresh in background
    if (globalIconCache.has(currentPath)) {
      const cached = globalIconCache.get(currentPath)
      // Schedule background revalidation
      fetchIconUpwards(currentPath).then((fresh) => {
        if (fresh !== globalIconCache.get(currentPath)) {
          globalIconCache.set(currentPath, fresh)
          updateIcons() // value changed, re-apply
        }
      })
      localCache.set(currentPath, cached)
      return cached
    }

    // Cache miss: fetch, populate both caches
    const promise = fetchIconUpwards(currentPath).then((url) => {
      globalIconCache.set(currentPath, url)
      return url
    })
    // Store promise in local cache to deduplicate parallel calls within this update
    localCache.set(currentPath, promise)
    const result = await promise
    localCache.set(currentPath, result) // replace promise with resolved value
    return result
  }
  return findIconUpwards
}

const updateIcons = async () => {
  const localCache = new Map()
  const findIconUpwards = makeIconFinder(localCache)

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
