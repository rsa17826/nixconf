let lastTarget = null

onmousemove = (e) => {
  const el = document.elementFromPoint(e.clientX, e.clientY)
  if (!el) return

  // If you're directly over a real input → just focus it
  if (isDirectInput(el)) {
    if (lastTarget === el) return
    lastTarget = el
    el.focus()
    return
  }

  const container = el.closest(
    ':is(.terminal, .monaco-editor, .repl, .interactive, .inputbox, [role="textbox"], [id="workbench.parts.sidebar"]',
  )
  log(container)
  if (!container || container === lastTarget) return
  lastTarget = container

  focusContainer(container)
}

function isDirectInput(el) {
  return el.matches('textarea, input, [contenteditable="true"]')
}

function focusContainer(container) {
  // Terminal
  let input = container.querySelector(".xterm-helper-textarea")
  if (input) return input.focus()

  // Monaco editor
  input = container.querySelector(".native-edit-context")
  if (input) return input.focus()

  // Search / input boxes (like Find in Files)
  input = container.querySelector("textarea.input, input.input")
  if (input) return input.focus()

  // Generic fallback
  const fallback = container.querySelector(
    'textarea, input, [tabindex]:not([tabindex="-1"])',
  )
  fallback?.focus()
}
