
const lastValue = new WeakMap()

const mify = (node) => {
  // 1. PROTECT THE EDITOR: Do not touch code lines or the terminal
  if (node.nodeType === 1) {
    // Element Node
    const blocklist = [
      ".monaco-editor",
      ".terminal",
      ".monaco-list-rows",
      ".lines-content",
    ]
    if (node.closest(blocklist.join(","))) return

    // Target Attributes
    const attrs = ["aria-label", "title", "placeholder"]
    attrs.forEach((attr) => {
      const currentVal = node.getAttribute(attr)
      if (!currentVal) return

      // Get the map of attributes for this specific node
      if (!lastValue.has(node)) lastValue.set(node, {})
      const savedAttrs = lastValue.get(node)

      // If the current attribute doesn't match our last 'm-ified' version, change it
      if (currentVal !== savedAttrs[attr]) {
        const newValue = owowify(currentVal)
        savedAttrs[attr] = newValue
        node.setAttribute(attr, newValue)
      }
    })
  }

  if (node.nodeType === 3) {
    // Text Node
    const currentVal = node.nodeValue
    if (!currentVal.trim()) return

    // If the text changed from what we last set it to, re-mify
    if (currentVal !== lastValue.get(node)) {
      const newValue = owowify(currentVal)
      lastValue.set(node, newValue)
      node.nodeValue = newValue
    }
  }
}

const observer = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
    if (mutation.type === "childList") {
      mutation.addedNodes.forEach((n) => {
        if (n.nodeType === 1) {
          mify(n)
          n.querySelectorAll("*").forEach(mify)
        } else if (n.nodeType === 3) {
          mify(n)
        }
      })
    } else if (
      mutation.type === "attributes" ||
      mutation.type === "characterData"
    ) {
      // characterData catches when the text inside an existing text node changes
      mify(mutation.target)
    }
  }
})

observer.observe(document.body, {
  childList: true,
  subtree: true,
  attributes: true,
  characterData: true, // Crucial for catching text updates
  attributeFilter: ["aria-label", "title", "placeholder"],
})

// Initial run
document.querySelectorAll("*").forEach(mify)
