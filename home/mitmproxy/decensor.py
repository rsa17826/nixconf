"""
text-replace-addon.py
mitmproxy addon — port of the browser userscript text replacement logic.
Intercepts HTTP/HTTPS responses and de-censors text in HTML/JSON/plain-text.
"""

import re
from mitmproxy import http

# ---------------------------------------------------------------------------
# Word list — each entry is matched with character-level substitution:
# any char can be replaced with % # * or ♥ in the source text.
# ---------------------------------------------------------------------------
_WORD_LIST = """\
fuck
shitshow
fucks
shitposts
pornstar
sucked
bisexual
cumdump
vagina
crap
shitload
shithole
stupidness
fuckery
retardation
horshit
smut
bitching
stupids
bumfucks
bumblefuck
fuckin
fucktard
licked
crotch
hitler
crotchless
incestuous
batshit
penis
masturbate
Goddamn
damn
enslave
slavery
socked
enslavement
murderess
molest
molestation
dicks
cockblock
scrape
perverts
cock
stupidest
boobs
stupidity
sadist
stupid
trashest
fag
erotic
cockroach
tits
murdering
bitchy
trashing
trashiest
bullshitting
cocky
cockiness
murderous
Hancock
trashy
trashcan
horny
suicide
retard
clicked
incestual
basement
rapes
thorny
virgin
murderers
murderer
murder
virgins
assholes
rapest
whore
slut
bitchest
raped
morons
amusement
cocks
incest
fingerfuck
molested
murders
trash
cockroaches
monsterfucker
intersex
Futanari
trashhero
fucked
motherfucker
bitches
bastard
fucking
hell
nasty
scum
pissed
bastards
raping
bitch
shit
bastard
fucker
scumbag
shitless
ass
badass
virginity
slave
pervert
futanari
sex
futa
Impregnating
Impregnated
trashes
murderfest
Impregnate
rapey
retards
fuckk
Cunnilingus
slaves
sexual
edgefuckfests
anal
stupider
assed
Intercourse
Fallatio
Handjob
Masturbation
Masturbating
Orgy
Prostitutes
rape
enslaved
perverted
stupidly
prostitution
sexually
bullshits
shits
porn
dick
shitty
dicking
bullshit
sexuality
retardedness
Futadomworld
asshole
pussy
sexy
murdered
cocktail
virginal
retarded
hentai
dogshit
fricking
frick
fricker\
"""

# Boundary character class used in look-around assertions
_BOUND = r"[^a-z0-9@#$%^&\*x♥]"
_BOUND_OR_START = rf"(?<![a-z0-9])"
_BOUND_OR_END = rf"(?![a-z0-9])"

def _build_word_pattern(word: str) -> re.Pattern[str]:
  """Build a regex that matches a word even when chars are swapped for %#*♥."""
  char_classes = [rf"[{re.escape(ch)}%#*♥]" for ch in word]
  inner = r" ?".join(char_classes)
  return re.compile(
    _BOUND_OR_START + inner + _BOUND_OR_END,
    re.IGNORECASE,
  )


# ---------------------------------------------------------------------------
# Build the replacement list: [(pattern, replacement), ...]
# ---------------------------------------------------------------------------
REPLACEMENTS: list[tuple[re.Pattern[str], str]] = []

seen: set[str] = set()
for _w in _WORD_LIST.splitlines():
  _w = _w.strip().lower()
  if _w and _w not in seen:
    seen.add(_w)
    REPLACEMENTS.append((_build_word_pattern(_w), _w))

# Manual / special-case replacements (same order as the original script)
REPLACEMENTS += [ # pyright: ignore[reportConstantRedefinition]
  # Remove bold markdown (*word*)
  (re.compile(r"(?<![a-z0-9])\*(\w+( \w+)*)\*(?![a-z0-9])", re.IGNORECASE), r"\1"),
  # Duck → fuck euphemisms
  (re.compile(r"what( ?ever)? the duck", re.IGNORECASE), r"what\1 the fuck"),
  (re.compile(r"duck(ed)? up", re.IGNORECASE), r"fuck\1 up"),
  # Leet / starred variants
  (re.compile(r"R4P3", re.IGNORECASE), "rape"),
  (re.compile(r"fked", re.IGNORECASE), "fucked"),
  (re.compile(r"borked", re.IGNORECASE), "fucked"),
  (re.compile(r"MotherF'er(s?)", re.IGNORECASE), r"motherfucker\1"),
  (re.compile(r"(?<!\w)minf\*+ks(?!\w)", re.IGNORECASE), "mindfucks"),
  (re.compile(r"(?<!\w)asspull(?!\w)", re.IGNORECASE), "asshole"),
  (re.compile(r"\bfriggin\b", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)fupping(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)frigg(ing|er|ed)(s?)(?!\w)", re.IGNORECASE), r"fuck\1\2"),
  # Remove ASCII-art / spam lines
  (re.compile(r".*░.*", re.IGNORECASE), ""),
  (re.compile(r".*THIS IS BOB.*", re.IGNORECASE), ""),
  (re.compile(r"F\**CK", re.IGNORECASE), "fuck"),
  (re.compile(r".*\@\#\$\&.*", re.IGNORECASE), ""),
  (re.compile(r"(?<!\w)friking?(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)shyt(?!\w)", re.IGNORECASE), "shit"),
  (re.compile(r"(?<!\w)arse?(holes?)?(?!\w)", re.IGNORECASE), r"ass\1"),
  (re.compile(r"f\*ing(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"motherf\*(?!\w)", re.IGNORECASE), "motherfucker"),
  (re.compile(r"b\*\*\*", re.IGNORECASE), "bitch"),
  (re.compile(r"(?<!\w)f'ing(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)NSFW(?!\w)", re.IGNORECASE), "porn"),
  (
    re.compile(
      r"(?<![a-z0-9@#$%^&\*x♥])[h%#*♥] ?[e%#*♥] ?[c%#*♥] ?[k%#*♥](?=[^a-z0-9@#$%^&\*x♥]|$)",
      re.IGNORECASE,
    ),
    "hell",
  ),
  (re.compile(r"(?<!\w)prosti\*ion(?!\w)", re.IGNORECASE), "prostitution"),
  # Artist names with stars (preserve them clean)
  (re.compile(r"(?<!\w)Ayaponzu\*(?!\w)", re.IGNORECASE), "Ayaponzu"),
  (re.compile(r"(?<!\w)DECO\*27(?=[^\w\d]|$)", re.IGNORECASE), "DECO27"),
  # More euphemisms
  (re.compile(r"(?<!\w)freakin'?(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)(?:pron|p0rn)(?!\w)", re.IGNORECASE), "porn"),
  (re.compile(r"(?<!\w)fricking(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)frick(?!\w)", re.IGNORECASE), "fuck"),
  (re.compile(r"(?<!\w)fricker(?!\w)", re.IGNORECASE), "fucker"),
  (re.compile(r"(?<!\w)HECKINg?(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)helling?(?!\w)", re.IGNORECASE), "fucking"),
  (re.compile(r"(?<!\w)s\*\*tposts(?!\w)", re.IGNORECASE), "shitposts"),
]

# Content-types we'll attempt to rewrite (binary types are skipped)
_TEXT_TYPES = (
  "text/html",
  "text/plain",
  "application/json",
  "application/javascript",
  "text/javascript",
  "application/xml",
  "text/xml",
  "text/css",
)

REPLACEMENT_MAP = {p.pattern: r for p, r in REPLACEMENTS}

# 2. Combine all patterns into one giant 'OR' regex
# This is the "Magic Bullet" for performance
combined_pattern = re.compile(
  "|".join(p.pattern for p, _ in REPLACEMENTS), re.IGNORECASE
)


def replace_text(text: str) -> str:
  def dispatch(match):
    # match.re.pattern gives us the specific sub-pattern that triggered the match
    return REPLACEMENT_MAP.get(match.re.pattern, match.group(0))

  return combined_pattern.sub(dispatch, text)


# def replace_text(text: str) -> str:
#   for pattern, repl in REPLACEMENTS:
#     text = pattern.sub(repl, text)
#   return text


# def request(self, flow: http.HTTPFlow) -> None:
#   # Strip compression headers so the server sends raw HTML
#   flow.request.headers.pop("Accept-Encoding", None)


class TextReplaceAddon:
  def response(self, flow: http.HTTPFlow) -> None:
    ct = flow.response.headers.get("content-type", "").lower()
    if not any(t in ct for t in _TEXT_TYPES):
      return

    # Skip tiny or clearly binary responses
    # return
    cl = int(flow.response.headers.get("content-length", 0))
    if cl > 5_000_000: # skip responses > 5 MB
      return

    try:
      text = flow.response.get_text(strict=False)
    except Exception:
      return

    replaced = replace_text(text)
    if replaced != text:
      flow.response.set_text(replaced)


addons = [TextReplaceAddon()]
