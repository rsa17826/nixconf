package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"sort"
	"strings"
)

type Line struct {
	Text string `json:"text"`
	Icon string `json:"icon"`
}

type Response struct {
	InputAction string `json:"input action,omitempty"`
	Message     string `json:"message"`
	Lines       []Line `json:"lines"`
}

type incoming struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type mode int

const (
	modeNormal mode = iota
	modeEmojiSearch
	modeEmojiDetail
)

func formatRofiLines(mathResult string, appList []App) []Line {
	var lines []Line
	if mathResult != "" {
		lines = append(lines, Line{Text: "➔ " + Owowify(mathResult), Icon: "edit-paste"})
	}
	for _, app := range appList {
		lines = append(lines, Line{Text: app.OwoName, Icon: app.Icon})
	}
	return lines
}

func formatEmojiSearchLines(matches []EmojiItem) []Line {
	var lines []Line
	for _, m := range matches {
		lines = append(lines, Line{Text: m.Char + " - " + m.Name, Icon: "accessories-character-map"})
	}
	return lines
}

func formatEmojiDetailLines(char string) []Line {
	var lines []Line
	for _, e := range getEmojiEncodings(char) {
		lines = append(lines, Line{Text: e.Value + " - " + e.Label, Icon: "accessories-character-map"})
	}
	return lines
}

func printResponse(r Response) {
	if len(r.Lines) == 0 {
		r.Lines = []Line{{Text: "", Icon: "dialog-warning"}}
	}
	data, err := json.Marshal(r)
	if err != nil {
		return
	}
	fmt.Println(string(data))
	os.Stdout.Sync()
}

func main() {
	allApps := getDesktopApps()
	allEmojis, err := buildEmojiDatabase()
	if err != nil {
		allEmojis = nil
	}
	charSet := emojiCharSet(allEmojis)

	printResponse(Response{
		InputAction: "send",
		Message:     Owowify("Type math or search apps, or : for emoji..."),
		Lines:       formatRofiLines("", allApps),
	})

	activeMathCalculation := ""
	curMode := modeNormal

	scanner := bufio.NewScanner(os.Stdin)
	scanner.Buffer(make([]byte, 0, 64*1024), 1024*1024)

	for scanner.Scan() {
		line := scanner.Text()
		if strings.TrimSpace(line) == "" {
			continue
		}

		var payload incoming
		if err := json.Unmarshal([]byte(line), &payload); err != nil {
			fmt.Println(mustJSON(map[string]any{"message": "Error: " + err.Error(), "lines": []Line{}}))
			continue
		}
		eventName := payload.Name
		userInput := strings.TrimSpace(payload.Value)

		// 1. HANDLE SELECTION ACTIONS
		if eventName == "select entry" {
			if curMode == modeEmojiDetail {
				parts := strings.SplitN(userInput, " - ", 2)
				codeValue := strings.TrimSpace(parts[0])
				if codeValue != "" {
					copyToClipboard(codeValue)
				}
				os.Exit(0)
			}

			if curMode == modeEmojiSearch {
				parts := strings.SplitN(userInput, " - ", 2)
				if len(parts) == 2 {
					selectedChar := strings.TrimSpace(parts[0])
					curMode = modeEmojiDetail
					printResponse(Response{
						InputAction: "send",
						Message:     Owowify(fmt.Sprintf("Encodings for %s - pick one to copy", selectedChar)),
						Lines:       formatEmojiDetailLines(selectedChar),
					})
				}
				continue
			}

			if strings.HasPrefix(userInput, "➔") {
				if activeMathCalculation != "" {
					copyToClipboard(activeMathCalculation)
					os.Exit(0)
				}
			} else {
				for _, app := range allApps {
					if app.OwoName == userInput || app.Name == userInput {
						launchApp(app.Exec, app.Workdir)
						os.Exit(0)
					}
				}
			}
			continue
		}

		// 2. HANDLE EMOJI MODE (prefix ':')
		if strings.HasPrefix(userInput, ":") {
			curMode = modeEmojiSearch
			query := userInput[1:]
			matches := searchEmojis(query, allEmojis, charSet, 60)
			// Mirrors launcher.py: only the "no query yet" message is
			// owowified; the match-count message is left as-is.
			var msg string
			if query != "" {
				msg = fmt.Sprintf("Emoji: %d match(es)", len(matches))
			} else {
				msg = Owowify("Type an emoji name, paste an emoji, or enter a code...")
			}
			lines := formatEmojiSearchLines(matches)
			if len(lines) == 0 {
				lines = []Line{{Text: "", Icon: "dialog-warning"}}
			}
			printResponse(Response{
				InputAction: "send",
				Message:     msg,
				Lines:       lines,
			})
			continue
		}

		// Leaving emoji mode falls through to normal app/math handling.
		if curMode == modeEmojiSearch || curMode == modeEmojiDetail {
			curMode = modeNormal
		}

		// 3. HANDLE DYNAMIC SEARCH FILTERING & MATH EVALUATION
		var response Response
		if userInput == "" {
			activeMathCalculation = ""
			response = Response{
				InputAction: "send",
				Message:     Owowify("Type math or search apps..."),
				Lines:       formatRofiLines("", allApps),
			}
		} else {
			query := strings.ToLower(userInput)

			matchRank := func(app App) int {
				name := strings.ToLower(app.Name)
				owoName := strings.ToLower(app.OwoName)
				execLower := strings.ToLower(app.Exec)

				switch {
				case name == query || owoName == query:
					return 0
				case strings.HasPrefix(name, query) || strings.HasPrefix(owoName, query):
					return 1
				case strings.Contains(name, query) || strings.Contains(owoName, query):
					return 2
				case strings.Contains(strings.ToLower(Owowify(execLower)), query):
					return 3
				default:
					return 99
				}
			}

			var displayed []App
			for _, app := range allApps {
				if matchRank(app) < 99 {
					displayed = append(displayed, app)
				}
			}
			sort.SliceStable(displayed, func(i, j int) bool {
				ri, rj := matchRank(displayed[i]), matchRank(displayed[j])
				if ri != rj {
					return ri < rj
				}
				return strings.ToLower(displayed[i].Name) < strings.ToLower(displayed[j].Name)
			})

			activeMathCalculation = ""
			if isMathLikeInput(userInput) {
				if result, err := evalMathExpr(userInput); err == nil {
					// Python 3's `/` always promotes to float, but +-*% on
					// plain ints stay int; mirror that in how we stringify,
					// since str(8) != str(8.0).
					forceFloat := strings.ContainsAny(userInput, "/.")
					activeMathCalculation = formatMathResult(result, forceFloat)
				}
			}

			if activeMathCalculation != "" || len(displayed) > 0 {
				var msg string
				if activeMathCalculation != "" {
					msg = "Result: " + activeMathCalculation
				} else {
					msg = "Searching apps..."
				}
				response = Response{
					InputAction: "send",
					Message:     Owowify(msg),
					Lines:       formatRofiLines(activeMathCalculation, displayed),
				}
			} else {
				response = Response{
					InputAction: "send",
					Message:     Owowify(fmt.Sprintf("No matches found for '%s'", userInput)),
					Lines:       []Line{},
				}
			}
		}

		printResponse(response)
	}
}

// isMathLikeInput mirrors the basic sanitization check in launcher.py that
// gates the eval() call: the input must consist solely of characters drawn
// from "+-*/%()0123456789 ".
func isMathLikeInput(s string) bool {
	for _, c := range s {
		if strings.ContainsRune("+-*/%()0123456789 ", c) {
			return true
		}
	}
	return false
}

func mustJSON(v any) string {
	data, err := json.Marshal(v)
	if err != nil {
		return "{}"
	}
	return string(data)
}
