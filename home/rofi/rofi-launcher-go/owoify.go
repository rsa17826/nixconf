package main

import (
	"fmt"
	"strings"
	"unicode"

	"github.com/dlclark/regexp2"
)

const (
	endSentencePattern = `([\w ,.!?]+)?`
	vowel              = "[aiueo]"
	vowelNoE           = "[aiuo]"
	vowelNoIE          = "[auo]"
	zackqyWord         = "[jzckq]"
)

// Owowify converts text into "owo" speak, matching launcher.py's owowify().
func Owowify(text string) string {
	// 1. OwO Emotes
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)(i(?:'|)m(?:\s+|\s+so+\s+)bored)`+endSentencePattern, 0),
		text,
		subOwoEmote(text, "-w-"),
	)
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)(love\s+(?:you|him|her|them))`+endSentencePattern, 0),
		text,
		subOwoEmote(text, "uwu"),
	)
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)(i\s+don(?:'|)t\s+care|i\s*d\s*c)`+endSentencePattern, 0),
		text,
		subOwoEmote(text, "0w0"),
	)

	// 2. Word substitution
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)l[ou]ve?`, 0),
		text,
		func(m regexp2.Match) string { return subSameCase(m.String(), "luv") },
	)

	// 3. r -> w
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)(?<=\w)r`, 0),
		text,
		func(m regexp2.Match) string { return subSameCase(m.String(), "w") },
	)
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)r(?=\w)`, 0),
		text,
		func(m regexp2.Match) string { return subSameCase(m.String(), "w") },
	)

	// 4. l -> w adjustments (custom rune-walk, matches python's l_repl exactly)
	text = replaceWordsFunc(text, lRepl)

	// 5. n -> ny variants
	text = replaceAllStringFunc(
		regexp2.MustCompile(`(?i)n(`+vowelNoE+`+)`, 0),
		text,
		func(m regexp2.Match) string {
			v := m.Groups()[1].Captures[0].String()
			return subSameCase(m.String(), "ny"+v)
		},
	)

	// 6. m -> my / p -> pw variants, with lookahead against j/z/c/k/q
	text = lookaheadSub(text, `(?i)m(`+vowelNoIE+`+)`, "my")
	text = lookaheadSub(text, `(?i)p(`+vowelNoIE+`+)`, "pw")

	return text
}

// subOwoEmote replicates sub_emote()'s closure: if the trailing "end of
// sentence" capture is empty or whitespace-only, append the emote after the
// matched phrase; otherwise leave the match untouched.
func subOwoEmote(_ string, emote string) func(regexp2.Match) string {
	matchEndSpace := regexp2.MustCompile(`^\s+$`, 0)
	return func(m regexp2.Match) string {
		g := m.Groups()
		sentenceBeforeEnd := g[1].Captures[0].String()

		var endSentence string
		if len(g) > 2 && len(g[2].Captures) > 0 {
			endSentence = g[2].Captures[0].String()
		}

		isSpace, _ := matchEndSpace.MatchString(endSentence)
		if endSentence == "" || isSpace {
			return fmt.Sprintf("%s %s", sentenceBeforeEnd, emote)
		}
		return m.String()
	}
}

// subSameCase preserves upper/lower casing based on the input template.
func subSameCase(inputText, replaceText string) string {
	var result strings.Builder
	inputRunes := []rune(inputText)
	replaceRunes := []rune(replaceText)

	for i := 0; i < len(replaceRunes); i++ {
		if i < len(inputRunes) {
			switch {
			case unicode.IsUpper(inputRunes[i]):
				result.WriteRune(unicode.ToUpper(replaceRunes[i]))
			case unicode.IsLower(inputRunes[i]):
				result.WriteRune(unicode.ToLower(replaceRunes[i]))
			default:
				result.WriteRune(replaceRunes[i])
			}
		} else {
			result.WriteRune(replaceRunes[i])
		}
	}
	return result.String()
}

// lRepl replicates l_repl(): walk each letter of a word, turning a bare 'l'
// into 'w' unless it's immediately followed by w/l, or preceded only by a
// run of w/l/vowels from the start of the word.
func lRepl(word string) string {
	runes := []rune(word)
	vowelRe := regexp2.MustCompile(`(?i)^[wl]`+vowel+`*$`, 0)

	for i, char := range runes {
		if unicode.ToLower(char) != 'l' || len(runes) == 1 {
			continue
		}
		if i+1 < len(runes) {
			next := unicode.ToLower(runes[i+1])
			if next == 'w' || next == 'l' {
				continue
			}
		}
		prefix := string(runes[:i])
		if prefix != "" {
			if ok, _ := vowelRe.MatchString(prefix); ok {
				continue
			}
		}
		if unicode.IsUpper(char) {
			runes[i] = 'W'
		} else {
			runes[i] = 'w'
		}
	}
	return string(runes)
}

// replaceWordsFunc applies fn to every maximal run of [a-zA-Z]+ in text.
func replaceWordsFunc(text string, fn func(string) string) string {
	runes := []rune(text)
	var out strings.Builder
	i := 0
	for i < len(runes) {
		if isAsciiLetter(runes[i]) {
			j := i
			for j < len(runes) && isAsciiLetter(runes[j]) {
				j++
			}
			out.WriteString(fn(string(runes[i:j])))
			i = j
		} else {
			out.WriteRune(runes[i])
			i++
		}
	}
	return out.String()
}

func isAsciiLetter(r rune) bool {
	return (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z')
}

// lookaheadSub replicates lookahead_sub(): substitute pattern with
// insertion+group1 unless what follows the match (in the *original* text) is
// a run of w's leading into j/z/c/k/q.
func lookaheadSub(text, pattern, insertion string) string {
	re := regexp2.MustCompile(pattern, 0)
	zackqyRe := regexp2.MustCompile(`(?i)^w*`+zackqyWord, 0)

	runes := []rune(text)

	type repl struct {
		start, end int
		text       string
	}
	var repls []repl

	m, err := re.FindStringMatch(text)
	for err == nil && m != nil {
		full := m.String()
		start := m.Index
		end := m.Index + m.Length
		following := string(runes[end:])

		if ok, _ := zackqyRe.MatchString(following); ok {
			m, err = re.FindNextMatch(m)
			continue
		}

		group1 := m.Groups()[1].Captures[0].String()
		repls = append(repls, repl{start: start, end: end, text: subSameCase(full, insertion+group1)})
		m, err = re.FindNextMatch(m)
	}

	if len(repls) == 0 {
		return text
	}

	var out strings.Builder
	last := 0
	for _, r := range repls {
		out.WriteString(string(runes[last:r.start]))
		out.WriteString(r.text)
		last = r.end
	}
	out.WriteString(string(runes[last:]))
	return out.String()
}

// replaceAllStringFunc applies replacer to every match of re in input and
// stitches the result back together (rune-safe).
func replaceAllStringFunc(re *regexp2.Regexp, input string, replacer func(regexp2.Match) string) string {
	runes := []rune(input)

	type matchInfo struct {
		index, length int
		replacement   string
	}

	var matches []matchInfo
	m, err := re.FindStringMatch(input)
	for err == nil && m != nil {
		matches = append(matches, matchInfo{
			index:       m.Index,
			length:      m.Length,
			replacement: replacer(*m),
		})
		m, err = re.FindNextMatch(m)
	}

	var result strings.Builder
	last := 0
	for _, mi := range matches {
		result.WriteString(string(runes[last:mi.index]))
		result.WriteString(mi.replacement)
		last = mi.index + mi.length
	}
	result.WriteString(string(runes[last:]))
	return result.String()
}
