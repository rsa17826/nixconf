package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

type App struct {
	Name    string `json:"name"`
	OwoName string `json:"owo_name"`
	Exec    string `json:"exec"`
	Icon    string `json:"icon"`
	Workdir string `json:"workdir"`
}

type sigEntry struct {
	Path  string  `json:"path"`
	Mtime float64 `json:"mtime"`
}

type appsCache struct {
	Signature []sigEntry `json:"signature"`
	Apps      []App      `json:"apps"`
}

func cacheDir() string {
	if xdg := os.Getenv("XDG_CACHE_HOME"); xdg != "" {
		return filepath.Join(xdg, "launcher")
	}
	home, _ := os.UserHomeDir()
	return filepath.Join(home, ".cache", "launcher")
}

func appsCacheFile() string {
	return filepath.Join(cacheDir(), "apps_cache.json")
}

func desktopSearchPaths() []string {
	xdgDataDirs := os.Getenv("XDG_DATA_DIRS")
	if xdgDataDirs == "" {
		xdgDataDirs = "/usr/local/share:/run/current-system/sw/share:/usr/share"
	}
	xdgDataHome := os.Getenv("XDG_DATA_HOME")
	if xdgDataHome == "" {
		home, _ := os.UserHomeDir()
		xdgDataHome = filepath.Join(home, ".local", "share")
	}

	paths := []string{filepath.Join(xdgDataHome, "applications", "*.desktop")}
	for _, dir := range strings.Split(xdgDataDirs, ":") {
		if dir == "" {
			continue
		}
		if info, err := os.Stat(filepath.Join(dir, "applications")); err == nil && info.IsDir() {
			paths = append(paths, filepath.Join(dir, "applications", "*.desktop"))
		}
	}
	return paths
}

// desktopFileSignature is a cheap fingerprint of every .desktop file that
// would be scanned: (path, mtime) pairs, sorted by path.
func desktopFileSignature() []sigEntry {
	var sig []sigEntry
	for _, pattern := range desktopSearchPaths() {
		matches, _ := filepath.Glob(pattern)
		for _, path := range matches {
			info, err := os.Stat(path)
			if err != nil {
				continue
			}
			sig = append(sig, sigEntry{Path: path, Mtime: float64(info.ModTime().UnixNano()) / 1e9})
		}
	}
	sort.Slice(sig, func(i, j int) bool { return sig[i].Path < sig[j].Path })
	return sig
}

func sigEqual(a, b []sigEntry) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i].Path != b[i].Path || a[i].Mtime != b[i].Mtime {
			return false
		}
	}
	return true
}

var (
	nameRe      = regexp.MustCompile(`(?m)^Name=(.+)$`)
	execRe      = regexp.MustCompile(`(?m)^Exec=(.+)$`)
	iconRe      = regexp.MustCompile(`(?m)^Icon=(.+)$`)
	pathRe      = regexp.MustCompile(`(?m)^Path=(.+)$`)
	noDisplayRe = regexp.MustCompile(`(?m)^NoDisplay=[Tt]rue$`)
	execArgRe   = regexp.MustCompile(` %Internal| %[uUfFdiInm]`)
)

// getDesktopApps scans XDG application directories for .desktop files and
// extracts names, execs, and icons, mirroring get_desktop_apps(). Parsing
// and owowifying every file is the slow part, so the result is cached on
// disk and reused as long as the set of .desktop files (and their mtimes)
// hasn't changed.
func getDesktopApps() []App {
	currentSig := desktopFileSignature()

	if cached, ok := loadAppsCache(); ok && sigEqual(cached.Signature, currentSig) {
		return cached.Apps
	}

	var apps []App
	seen := make(map[string]bool)

	for _, pattern := range desktopSearchPaths() {
		matches, _ := filepath.Glob(pattern)
		for _, path := range matches {
			data, err := os.ReadFile(path)
			if err != nil {
				continue
			}
			content := string(data)

			nameMatch := nameRe.FindStringSubmatch(content)
			execMatch := execRe.FindStringSubmatch(content)
			if nameMatch == nil || execMatch == nil || noDisplayRe.MatchString(content) {
				continue
			}

			name := strings.TrimSpace(nameMatch[1])
			executable := strings.TrimSpace(execMatch[1])
			executable = execArgRe.ReplaceAllString(executable, "")

			icon := "application-x-executable"
			if m := iconRe.FindStringSubmatch(content); m != nil {
				icon = strings.TrimSpace(m[1])
			}
			workdir := ""
			if m := pathRe.FindStringSubmatch(content); m != nil {
				workdir = strings.TrimSpace(m[1])
			}

			if !seen[name] {
				apps = append(apps, App{
					Name:    name,
					OwoName: Owowify(name),
					Exec:    executable,
					Icon:    icon,
					Workdir: workdir,
				})
				seen[name] = true
			}
		}
	}

	sort.Slice(apps, func(i, j int) bool {
		return strings.ToLower(apps[i].Name) < strings.ToLower(apps[j].Name)
	})

	saveAppsCache(appsCache{Signature: currentSig, Apps: apps})
	return apps
}

func loadAppsCache() (appsCache, bool) {
	data, err := os.ReadFile(appsCacheFile())
	if err != nil {
		return appsCache{}, false
	}
	var cache appsCache
	if err := json.Unmarshal(data, &cache); err != nil {
		return appsCache{}, false
	}
	return cache, true
}

func saveAppsCache(cache appsCache) {
	data, err := json.Marshal(cache)
	if err != nil {
		return
	}
	dir := cacheDir()
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return
	}
	tmp := appsCacheFile() + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		return
	}
	_ = os.Rename(tmp, appsCacheFile())
}
