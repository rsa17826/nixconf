/**
 * @param {String} inputText
 * @returns {String}
 */
function owowify(inputText) {
  const endSentencePattern = String.raw`([\w ,.!?]+)?` // endSentencePattern
  // const endSentencePattern1 = String.raw`([\w ,.?]+)?`; // endSentencePattern without "!" sign
  // const endSentencePattern2 = String.raw`([\w ,.]+)?`; // endSentencePattern without "!" and "?" sign
  inputText = String(inputText)
  const vowel = "[aiueo]"
  const vowelNoE = "[aiuo]" // vowel without e
  const vowelNoIE = "[auo]" // vowel without i and e
  const zackqyWord = "[jzckq]"
  var result = inputText
  // OwO emote
  result = result.replace(
    reg`/(i(?:'|)m(?:\s+|\s+so+\s+)bored)${endSentencePattern}/gi`,
    subOwoEmote("-w-"),
  )
  result = result.replace(
    reg`/(love\s+(?:you|him|her|them))${endSentencePattern}/gi`,
    subOwoEmote("uwu"),
  )
  result = result.replace(
    reg`/(i\s+don(?:'|)t\s+care|i\s*d\s*c)${endSentencePattern}/gi`,
    subOwoEmote("0w0"),
  )
  // world substitution
  result = result.replace(reg`/l[ou]ve?/gi`, ($0) =>
    subSameCase($0, "luv"),
  )
  // OwO translation
  // /*result = result replace all "r" to "w", no exception! */
  //     result = result.replace(/r/gi, $0 => subSameCase($0, "w"))
  /*result = result replace all "r" to "w", unless r is alone */
  result = result.replace(/(?<=\w)r/gi, ($0) => subSameCase($0, "w"))
  result = result.replace(/r(?=\w)/gi, ($0) => subSameCase($0, "w"))
  /* lame -> wame, goal -> goaw, gallery -> gallewy, lol -> lol, null -> null */
  // loaded -> woaded
  // url -> uwl instead of uww
  result = result.replace(
    reg`/(?<!([wl]${vowel}*))(?:l(?=\\w)|(?<=\\w)l)(?!([wl]))/gi`,
    ($0) => subSameCase($0, "w"),
  )
  /* na -> nya, nu -> nyu, no -> nyo, ne -> nye */
  // completionInfo -> compwetionInfo instead of compwetionYInfo
  result = result.replace(reg`/[nN](${vowelNoE}+)/g`, ($0, $vowel) =>
    subSameCase($0 + $vowel, `ny${$vowel}`),
  )
  result = result.replace(
    reg`/N(${vowelNoE.toUpperCase()}+)/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `ny${$vowel}`),
  )
  /* ma -> mya, mu -> myu, mo -> myo */
  result = result.replace(
    reg`/[mM](${vowelNoIE}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `my${$vowel}`),
  )
  result = result.replace(
    reg`/M(${vowelNoE.toUpperCase()}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `my${$vowel}`),
  )
  /* pa -> pwa, pu -> pwu, po -> pwo */
  // AhkStopAlt -> AhkStopAwt instead of AhkStopWAwt
  result = result.replace(
    reg`/[pP](${vowelNoIE}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `pw${$vowel}`),
  )
  result = result.replace(
    reg`/P(${vowelNoIE.toUpperCase()}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `pw${$vowel}`),
  )

  return result
}

function subOwoEmote(emote) {
  const matchEndSpace = /^\s+$/g

  return ($0, $setenceBeforeEnd, $endSentence) => {
    if (
      $endSentence == undefined ||
      matchEndSpace.test($endSentence)
    ) {
      return `${$setenceBeforeEnd} ${emote}`
    } else return $0
  }
}

/**
 * @param {string} inputText
 * @param {string} replaceText
 */
function subSameCase(inputText, replaceText) {
  let result = ""

  for (let i = 0; i < replaceText.length; i++) {
    if (inputText[i] != undefined && replaceText[i] != undefined) {
      if (inputText[i].toUpperCase() == inputText[i]) {
        result += replaceText[i].toUpperCase()
      } else if (inputText[i].toLowerCase() == inputText[i]) {
        result += replaceText[i].toLowerCase()
      } else {
        result += replaceText[i]
      }
    } else {
      result += replaceText[i]
    }
  }

  return result
}

/** @param {[string[], ...any[]]} templateArgs */
function reg(...templateArgs) {
  const rawString = String.raw(...templateArgs)
  const pattern = rawString.substring(1, rawString.lastIndexOf("/"))
  const flags = rawString.substring(
    rawString.lastIndexOf("/") + 1,
    rawString.length,
  )

  return new RegExp(pattern, flags)
}

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
const originalDeleteRule = CSSStyleSheet.prototype.deleteRule
const originalInsertRule = CSSStyleSheet.prototype.insertRule

CSSStyleSheet.prototype.insertRule = function (rule, index) {
  try {
    // Only touch rules that actually contain `content:`
    if (rule.includes("content")) {
      rule = rule.replace(
        /content\s*:\s*(['"])(.*?)\1/g,
        (match, quote, text) => {
          const owo = owowify(text)
          return `content: ${quote}${owo}${quote}`
        },
      )
    }
  } catch (e) {
    // fail silently — don't break CSS injection
  }

  return originalInsertRule.call(this, rule, index)
}
if (CSSStyleSheet.prototype.replaceSync) {
  const originalReplaceSync = CSSStyleSheet.prototype.replaceSync

  CSSStyleSheet.prototype.replaceSync = function (text) {
    try {
      if (text.includes("content")) {
        text = text.replace(
          /content\s*:\s*(['"])(.*?)\1/g,
          (match, quote, str) => {
            return `content: ${quote}${owowify(str)}${quote}`
          },
        )
      }
    } catch {}

    return originalReplaceSync.call(this, text)
  }
}

// const desc = Object.getOwnPropertyDescriptor(HTMLStyleElement.prototype, "textContent")

// Object.defineProperty(HTMLStyleElement.prototype, "textContent", {
//   set(value) {
//     try {
//       if (value.includes("content")) {
//         value = value.replace(
//           /content\s*:\s*(['"])(.*?)\1/g,
//           (m, q, t) => `content: ${q}${owowify(t)}${q}`
//         )
//       }
//     } catch {}

//     return desc.set.call(this, value)
//   },
//   get: desc.get
// })
