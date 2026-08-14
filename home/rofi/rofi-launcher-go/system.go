package main

import (
	"os"
	"os/exec"
	"strings"
)

// copyToClipboard mirrors copy_to_clipboard(): strip the "➔" marker, then
// try wl-copy, falling back to xclip.
func copyToClipboard(text string) {
	clean := strings.TrimSpace(strings.ReplaceAll(text, "➔", ""))

	if tryRunWithStdin("wl-copy", nil, clean) {
		return
	}
	tryRunWithStdin("xclip", []string{"-selection", "clipboard"}, clean)
}

func tryRunWithStdin(name string, args []string, stdin string) bool {
	cmd := exec.Command(name, args...)
	cmd.Stdin = strings.NewReader(stdin)
	cmd.Env = os.Environ()
	return cmd.Run() == nil
}

// launchApp launches an application in the background, detached, mirroring
// launch_app().
func launchApp(execCommand, workdir string) {
	parts, err := shlexSplit(execCommand)
	if err != nil || len(parts) == 0 {
		return
	}

	cmd := exec.Command(parts[0], parts[1:]...)
	cmd.Stdout = nil
	cmd.Stderr = nil
	cmd.Env = os.Environ()
	if workdir != "" {
		cmd.Dir = workdir
	}
	_ = cmd.Start()
	if cmd.Process != nil {
		go func() { _ = cmd.Process.Release() }()
	}
}

// shlexSplit is a minimal re-implementation of Python's shlex.split() for
// POSIX-style shell word splitting: whitespace-separated tokens, with single
// and double quoting and backslash escaping.
func shlexSplit(s string) ([]string, error) {
	var tokens []string
	var cur strings.Builder
	inToken := false

	runes := []rune(s)
	i := 0
	for i < len(runes) {
		c := runes[i]
		switch {
		case c == ' ' || c == '\t' || c == '\n':
			if inToken {
				tokens = append(tokens, cur.String())
				cur.Reset()
				inToken = false
			}
			i++
		case c == '\'':
			inToken = true
			i++
			for i < len(runes) && runes[i] != '\'' {
				cur.WriteRune(runes[i])
				i++
			}
			i++ // skip closing quote
		case c == '"':
			inToken = true
			i++
			for i < len(runes) && runes[i] != '"' {
				if runes[i] == '\\' && i+1 < len(runes) && (runes[i+1] == '"' || runes[i+1] == '\\') {
					cur.WriteRune(runes[i+1])
					i += 2
					continue
				}
				cur.WriteRune(runes[i])
				i++
			}
			i++ // skip closing quote
		case c == '\\':
			inToken = true
			if i+1 < len(runes) {
				cur.WriteRune(runes[i+1])
				i += 2
			} else {
				i++
			}
		default:
			inToken = true
			cur.WriteRune(c)
			i++
		}
	}
	if inToken {
		tokens = append(tokens, cur.String())
	}
	return tokens, nil
}
