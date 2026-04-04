// 1. Create the master style tag ONCE
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
  .file-icon[data-has-custom-icon="true"] {
    position: relative;
  }
  .file-icon[data-has-custom-icon="true"]::after {
    background-image: var(--folder-icon-url) !important;
    background-size: contain !important;
    background-repeat: no-repeat !important;
    content: "" !important;
    width: 16px;
    height: 16px;
    position: absolute;
    left: 18px;
    top: 50%;
    transform: translateY(-50%);
  }`
document.head.appendChild(styleElement)

/**
 * Recursively checks for image.png in the current and parent directories.
 */
async function findIconUpwards(currentPath) {
  // Stop if we hit the root or go above home (safety check)
  if (!currentPath || currentPath === "/" || currentPath === ".") {
    return null
  }

  const iconUrl = `vscode-file://vscode-app${currentPath}/.foldericon.png`

  try {
    const response = await fetch(iconUrl, { method: "HEAD" })
    if (response.ok) {
      return iconUrl
    }
  } catch (e) {
    // Ignore fetch errors and keep climbing
  }

  // Move one directory up: /home/user/project/src -> /home/user/project
  const parentPath = currentPath.substring(
    0,
    currentPath.lastIndexOf("/"),
  )
  return findIconUpwards(parentPath)
}

const updateIcons = async () => {
  const folders = document.querySelectorAll(".folder-icon")
  var files = document.querySelectorAll(".file-icon")
  for (const el of folders) {
    const path = el.getAttribute("aria-label")
    if (!path) continue

    // Clean and Format the Path
    let cleanPath = path
      .replace(/\\/g, "/")
      .replace(/ • Contains emphasized items$/, "")
      .replace(/^~/, USERHOME)

    if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

    // Start the recursive search
    findIconUpwards(cleanPath).then((foundUrl) => {
      if (foundUrl) {
        el.style.setProperty(
          "--folder-icon-url",
          `url('${foundUrl}')`,
        )
        el.setAttribute("data-has-custom-icon", "true")
      } else {
        el.removeAttribute("data-has-custom-icon")
      }
    })
  }
  for (const el of files) {
    const path = el.getAttribute("aria-label")
    if (!path) continue

    // Clean and Format the Path
    let cleanPath = path
      .replace(/\\/g, "/")
      .replace(/ • Contains emphasized items$/, "")
      .replace(/^~/, USERHOME)
    cleanPath = cleanPath.substring(0, cleanPath.lastIndexOf("/"))

    if (!cleanPath.startsWith("/")) cleanPath = "/" + cleanPath

    // Apply icon to `el` directly, same as folders
    findIconUpwards(cleanPath).then((foundUrl) => {
      if (foundUrl) {
        el.style.setProperty(
          "--folder-icon-url",
          `url('${foundUrl}')`,
        )
        el.setAttribute("data-has-custom-icon", "true")
      } else {
        el.removeAttribute("data-has-custom-icon")
      }
    })
  }
}

// 3. Setup MutationObserver
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
