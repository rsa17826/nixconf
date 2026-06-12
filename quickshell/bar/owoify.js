.pragma library

/**
 * @param {String} text
 * @returns {String}
 */
function owo(text) {
  const endSentencePattern = String.raw`([\w ,.!?]+)?` // endSentencePattern
  // const endSentencePattern1 = String.raw`([\w ,.?]+)?`; // endSentencePattern without "!" sign
  // const endSentencePattern2 = String.raw`([\w ,.]+)?`; // endSentencePattern without "!" and "?" sign
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
  // /*result = result replace all "r" to "w", no exception! */
  //     result = result.replace(/r/gi, $0 => subSameCase($0, "w"))
  /*result = result replace all "r" to "w", unless r is alone */
  text = text.replace(/(?<=\w)r/gi, ($0) => subSameCase($0, "w"))
  text = text.replace(/r(?=\w)/gi, ($0) => subSameCase($0, "w"))
  /* lame -> wame, goal -> goaw, gallery -> gallewy, lol -> lol, null -> null */
  // loaded -> woaded
  // url -> uwl instead of uww
  text = text.replace(
    reg`/(?<!([wl]${vowel}*))(?:l(?=\\w)|(?<=\\w)l)(?!([wl]))/gi`,
    ($0) => subSameCase($0, "w"),
  )
  /* na -> nya, nu -> nyu, no -> nyo, ne -> nye */
  // completionInfo -> compwetionInfo instead of compwetionYInfo
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
  // AhkStopAlt -> AhkStopAwt instead of AhkStopWAwt
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
 *
 * @param {string} emote
 * @returns
 */
function subOwoEmote(emote) {
  const matchEndSpace = /^\s+$/g

  /**
   *
   * @param {string} $0
   * @param {string} $sentenceBeforeEnd
   * @param {string} $endSentence
   * @returns
   */
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
