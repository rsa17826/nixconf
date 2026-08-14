package main

import (
	_ "embed"
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

//go:embed emoji_data.json
var embeddedEmojiData []byte

type EmojiItem struct {
	Char string `json:"char"`
	Name string `json:"name"`
}

type EmojiEncoding struct {
	Label string `json:"label"`
	Value string `json:"value"`
}

// buildEmojiDatabase loads the embedded {char,name} table. It never changes
// at runtime (it's baked into the binary at build time), so there's no need
// for the on-disk version-keyed cache that the Python version used to avoid
// re-parsing the `emoji` package on every launch.
func buildEmojiDatabase() ([]EmojiItem, error) {
	var items []EmojiItem
	if err := json.Unmarshal(embeddedEmojiData, &items); err != nil {
		return nil, err
	}
	return items, nil
}

func emojiCharSet(items []EmojiItem) map[string]bool {
	set := make(map[string]bool, len(items))
	for _, it := range items {
		set[it.Char] = true
	}
	return set
}

func jsEscape(codepoint rune) string {
	if codepoint > 0xFFFF {
		cp := codepoint - 0x10000
		high := 0xD800 + (cp >> 10)
		low := 0xDC00 + (cp & 0x3FF)
		return fmt.Sprintf("\\u%04x\\u%04x", high, low)
	}
	return fmt.Sprintf("\\u%04x", codepoint)
}

func pythonEscape(codepoint rune) string {
	if codepoint > 0xFFFF {
		return fmt.Sprintf("\\U%08x", codepoint)
	}
	return fmt.Sprintf("\\u%04x", codepoint)
}

// getEmojiEncodings returns every common encoding for a (possibly
// multi-codepoint) emoji, mirroring get_emoji_encodings().
func getEmojiEncodings(char string) []EmojiEncoding {
	runes := []rune(char)

	var codepointStr, htmlStr, htmlHexStr, jsStr, pyStr, altStr, ibusStr strings.Builder
	for i, cp := range runes {
		if i > 0 {
			codepointStr.WriteString(" ")
			altStr.WriteString(" ")
			ibusStr.WriteString(" ")
		}
		codepointStr.WriteString(fmt.Sprintf("U+%04X", cp))
		htmlStr.WriteString(fmt.Sprintf("&#%d;", cp))
		htmlHexStr.WriteString(fmt.Sprintf("&#x%x;", cp))
		jsStr.WriteString(jsEscape(cp))
		pyStr.WriteString(pythonEscape(cp))
		altStr.WriteString(strings.ToUpper(strconv.FormatInt(int64(cp), 16)))
		ibusStr.WriteString(strconv.FormatInt(int64(cp), 16))
	}

	return []EmojiEncoding{
		{Label: "emoji", Value: char},
		{Label: "codepoint", Value: codepointStr.String()},
		{Label: "html", Value: htmlStr.String()},
		{Label: "html (hex)", Value: htmlHexStr.String()},
		{Label: "js/css", Value: jsStr.String()},
		{Label: "python", Value: pyStr.String()},
		{Label: "alt code", Value: altStr.String()},
		{Label: "^u code (ibus)", Value: ibusStr.String()},
	}
}

var nonAsciiRunRe = regexp.MustCompile(`[^\x00-\x7F]+`)

// tryParsePastedEmoji mirrors _try_parse_pasted_emoji().
func tryParsePastedEmoji(query string, charSet map[string]bool) string {
	q := strings.TrimSpace(query)
	if charSet[q] {
		return q
	}
	for _, token := range nonAsciiRunRe.FindAllString(q, -1) {
		if charSet[token] {
			return token
		}
	}
	return ""
}

var (
	htmlHexRe = regexp.MustCompile(`^&#x([0-9a-fA-F]+);?$`)
	htmlDecRe = regexp.MustCompile(`^&#(\d+);?$`)
	jsEscRe   = regexp.MustCompile(`\\u([0-9a-fA-F]{4,6})`)
	pyEscRe   = regexp.MustCompile(`^\\U([0-9a-fA-F]{8})$`)
	bareHexRe = regexp.MustCompile(`(?i)^(?:u\+|0x)?([0-9a-fA-F]{2,8})$`)
)

// tryParseCode mirrors _try_parse_code(): parses HTML entities, JS/CSS
// unicode escapes (incl. surrogate pairs), Python \U escapes, and bare hex
// codepoints (alt-code / ^U style).
func tryParseCode(query string) string {
	q := strings.TrimSpace(query)
	if q == "" {
		return ""
	}

	if m := htmlHexRe.FindStringSubmatch(q); m != nil {
		if cp, err := strconv.ParseInt(m[1], 16, 32); err == nil {
			return string(rune(cp))
		}
	}
	if m := htmlDecRe.FindStringSubmatch(q); m != nil {
		if cp, err := strconv.ParseInt(m[1], 10, 32); err == nil {
			return string(rune(cp))
		}
	}
	if parts := jsEscRe.FindAllStringSubmatch(q, -1); len(parts) > 0 {
		var codepoints []int64
		for _, p := range parts {
			cp, err := strconv.ParseInt(p[1], 16, 32)
			if err != nil {
				return ""
			}
			codepoints = append(codepoints, cp)
		}
		if len(codepoints) == 2 && codepoints[0] >= 0xD800 && codepoints[0] <= 0xDBFF && codepoints[1] >= 0xDC00 && codepoints[1] <= 0xDFFF {
			combined := ((codepoints[0] - 0xD800) << 10) + (codepoints[1] - 0xDC00) + 0x10000
			return string(rune(combined))
		}
		var sb strings.Builder
		for _, cp := range codepoints {
			sb.WriteRune(rune(cp))
		}
		return sb.String()
	}
	if m := pyEscRe.FindStringSubmatch(q); m != nil {
		if cp, err := strconv.ParseInt(m[1], 16, 32); err == nil {
			return string(rune(cp))
		}
	}
	if m := bareHexRe.FindStringSubmatch(q); m != nil {
		if cp, err := strconv.ParseInt(m[1], 16, 32); err == nil {
			return string(rune(cp))
		}
	}
	return ""
}

// searchEmojis mirrors search_emojis().
func searchEmojis(query string, allEmojis []EmojiItem, charSet map[string]bool, limit int) []EmojiItem {
	query = strings.TrimSpace(query)
	if query == "" {
		if len(allEmojis) > limit {
			return allEmojis[:limit]
		}
		return allEmojis
	}

	parsed := tryParsePastedEmoji(query, charSet)
	if parsed == "" {
		parsed = tryParseCode(query)
	}
	if parsed != "" {
		for _, item := range allEmojis {
			if item.Char == parsed {
				return []EmojiItem{item}
			}
		}
		return []EmojiItem{{Char: parsed, Name: "Unicode Character"}}
	}

	q := strings.ToLower(query)
	rank := func(item EmojiItem) int {
		name := strings.ToLower(item.Name)
		switch {
		case name == q:
			return 0
		case strings.HasPrefix(name, q):
			return 1
		case strings.Contains(name, q):
			return 2
		default:
			return 99
		}
	}

	var matches []EmojiItem
	for _, item := range allEmojis {
		if rank(item) < 99 {
			matches = append(matches, item)
		}
	}
	sort.SliceStable(matches, func(i, j int) bool {
		ri, rj := rank(matches[i]), rank(matches[j])
		if ri != rj {
			return ri < rj
		}
		return matches[i].Name < matches[j].Name
	})

	if len(matches) > limit {
		matches = matches[:limit]
	}
	return matches
}
