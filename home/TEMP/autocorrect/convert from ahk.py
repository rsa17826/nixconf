import re
import yaml

input_file = r"./AutoCorrect.ahk"
output_file = "~/.config/espanso/match/default.yml"

espanso_data = {"matches": []}

# Regex to capture optional modifier (:, :?:, :*:, :?*:, :c:, etc.), trigger, replacement
hotstring_pattern = re.compile(r"^\s*(:[\w?:*]*:)?(\S+?)::(.+)$")

with open(input_file, "r", encoding="utf-8") as f:
  for line in f:
    line = line.strip()
    if (
      not line
      or line.startswith(";")
      or line.startswith("{")
      or line.startswith("}")
    ):
      continue

    m = hotstring_pattern.match(line)
    if m:
      modifier, trigger, replace = m.groups()
      replace = replace.split(";")[0].strip()

      match_entry = {"trigger": trigger, "replace": replace}

      # Handle AHK modifiers
      modifier = modifier or ""  # ensure it's a string

      if "*:" in modifier:
        match_entry["regex"] = True  # wildcard anywhere in word
      if "?" in modifier:
        match_entry["word_boundary"] = False  # non-backspacing
      if ":c:" in modifier.lower():
        match_entry["ignore_case"] = False

      espanso_data["matches"].append(match_entry)

with open(output_file, "w", encoding="utf-8") as f:
  yaml.dump(espanso_data, f, sort_keys=False, allow_unicode=True)

print(f"Converted {len(espanso_data['matches'])} hotstrings to {output_file}")
