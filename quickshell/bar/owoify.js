.pragma library

/**
 * @param {String} text
 * @returns {String}
 */
function owo(text) {
  const endSentencePattern = String.raw`([\w ,.!?]+)?` // endSentencePattern
  text = String(text)
  const vowel = "[aiueo]"
  const vowelNoE = "[aiuo]" // vowel without e
  const vowelNoIE = "[auo]" // vowel without i and e
  const zackqyWord = "[jzckq]"

  // OwO emote
  text = text.replace(
    reg`/(i(?:'|)m(?:\s+|\s+so+\s+)bored)${endSentencePattern}/gi`,
    subOwoEmote("-w-"),
  )
  text = text.replace(
    reg`/(love\s+(?:you|him|her|them))${endSentencePattern}/gi`,
    subOwoEmote("uwu"),
  )
  text = text.replace(
    reg`/(i\s+don(?:'|)t\s+care|i\s*d\s*c)${endSentencePattern}/gi`,
    subOwoEmote("0w0"),
  )

  // world substitution
  text = text.replace(reg`/l[ou]ve?/gi`, ($0) =>
    subSameCase($0, "luv"),
  )

  // OwO translation
  /* replace all "r" to "w", unless r is alone */
  // FIXED: Replaced lookbehinds by processing on a word-by-word basis
  text = text.replace(/\w+/g, (word) => {
    if (word.toLowerCase() === "r") return word;
    return word.replace(/r/gi, ($0) => subSameCase($0, "w"));
  });

  /* lame -> wame, goal -> goaw, gallery -> gallewy, lol -> lol, null -> null */
  // loaded -> woaded
  // url -> uwl instead of uww
  // FIXED: Replaced complex lookbehinds with manual character index inspection
  text = text.replace(/l/gi, (match, offset, fullString) => {
    // Check if adjacent to a word character (mimics (?:l(?=\w)|(?<=\w)l))
    const hasPrecedingWord = offset > 0 && /\w/.test(fullString[offset - 1]);
    const hasFollowingWord = offset + 1 < fullString.length && /\w/.test(fullString[offset + 1]);
    if (!hasPrecedingWord && !hasFollowingWord) return match;

    // Check if followed by w or l (mimics (?!([wl])))
    if (offset + 1 < fullString.length && /[wl]/i.test(fullString[offset + 1])) {
      return match;
    }

    // Check if preceded by [wl] followed by zero or more vowels (mimics (?<!([wl]${vowel}*)))
    let prevIdx = offset - 1;
    while (prevIdx >= 0 && /[aiueo]/i.test(fullString[prevIdx])) {
      prevIdx--;
    }
    if (prevIdx >= 0 && /[wl]/i.test(fullString[prevIdx])) {
      return match;
    }

    return subSameCase(match, "w");
  });

  /* na -> nya, nu -> nyu, no -> nyo, ne -> nye */
  text = text.replace(reg`/[nN](${vowelNoE}+)/g`, ($0, $vowel) =>
    subSameCase($0 + $vowel, `ny${$vowel}`),
  )
  text = text.replace(
    reg`/N(${vowelNoE.toUpperCase()}+)/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `ny${$vowel}`),
  )

  /* ma -> mya, mu -> myu, mo -> myo */
  text = text.replace(
    reg`/[mM](${vowelNoIE}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `my${$vowel}`),
  )
  text = text.replace(
    reg`/M(${vowelNoE.toUpperCase()}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `my${$vowel}`),
  )

  /* pa -> pwa, pu -> pwu, po -> pwo */
  text = text.replace(
    reg`/[pP](${vowelNoIE}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `pw${$vowel}`),
  )
  text = text.replace(
    reg`/P(${vowelNoIE.toUpperCase()}+)(?!w*${zackqyWord})/g`,
    ($0, $vowel) => subSameCase($0 + $vowel, `pw${$vowel}`),
  )

  return text
}

/**
 * @param {string} emote
 * @returns
 */
function subOwoEmote(emote) {
  const matchEndSpace = /^\s+$/g

  return ($0, $sentenceBeforeEnd, $endSentence) => {
    if (
      $endSentence == undefined ||
      matchEndSpace.test($endSentence)
    ) {
      return `${$sentenceBeforeEnd} ${emote}`
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

/** @param {[TemplateStringsArray, ...any[]]} templateArgs */
function reg(...templateArgs) {
  const rawString = String.raw(...templateArgs)
  const pattern = rawString.substring(1, rawString.lastIndexOf("/"))
  const flags = rawString.substring(
    rawString.lastIndexOf("/") + 1,
    rawString.length,
  )
  return new RegExp(pattern, flags)
}
