/**
 * @type {HTMLElement|null}
 */
let lastTarget = null
let lastPos = { x: 0, y: 0 }

const HOVER_DELAY = 0
const MOVE_THRESHOLD = 4 // px (ignore tiny jitters)

onmousemove = (e) => {
  const dx = Math.abs(e.clientX - lastPos.x)
  const dy = Math.abs(e.clientY - lastPos.y)

  // Ignore tiny mouse jitter
  if (dx < MOVE_THRESHOLD && dy < MOVE_THRESHOLD) return

  lastPos = { x: e.clientX, y: e.clientY }

  const el = document.elementFromPoint(e.clientX, e.clientY)
  if (!el) return

  const target = resolveTarget(el)
  if (!target || target === lastTarget) return

  lastTarget = target
  applyFocus(target)
}

/**
 *
 * @param {HTMLElement|Element} el
 * @returns {HTMLElement|null}
 */
function resolveTarget(el) {
  // 1. Direct real inputs (search box etc)
  if (
    el.matches(
      '.terminal, .monaco-editor, .editor-scrollable, .repl, .interactive, .inputbox, [role="textbox"], [id="workbench.parts.sidebar"], .editor-container, iframe.webview',
    )
  ) {
    // if matching it is htmlelement
    // @ts-ignore
    return el
  }

  if (el.closest(".monaco-editor-pane-placeholder")) {
    return el.closest(".monaco-editor-pane-placeholder")
  }

  // 2. Terminal
  const terminal = el.closest(".terminal")
  if (terminal) {
    return terminal.querySelector(".xterm-helper-textarea")
  }

  // 3. Editor (Monaco)
  const editor = el.closest(".monaco-editor")
  if (editor) {
    return editor.querySelector(".native-edit-context")
  }

  // 4. Search / input panels
  const inputBox = el.closest(".inputbox, .search-view")
  if (inputBox) {
    return inputBox.querySelector("textarea, input")
  }

  // 5. Generic fallback
  return el.closest('[role="textbox"], [contenteditable="true"]')
}
/**
 *
 * @param {HTMLElement} target
 * @returns {void}
 */
function applyFocus(target) {
  if (!target) return

  // Avoid unnecessary focus calls
  if (document.activeElement === target) return

  requestAnimationFrame(() => {
    target.focus()
  })
}
// $0.querySelector(".monaco-editor-pane-placeholder").focus()
