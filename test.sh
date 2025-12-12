#! /usr/bin/env nix-shell
#! nix-shell -i bash -p cacert curl jq unzip
# shellcheck shell=bash
set -eu -o pipefail

# can be added to your configuration with the following command and snippet:
# $ ./pkgs/applications/editors/vscode/extensions/update_installed_exts.sh > extensions.nix
#
# packages = with pkgs;
#   (vscode-with-extensions.override {
#     vscodeExtensions = map
#       (extension: vscode-utils.buildVscodeMarketplaceExtension {
#         mktplcRef = {
#          inherit (extension) name publisher version sha256;
#         };
#       })
#       (import ./extensions.nix).extensions;
#   })
# ]

# Helper to just fail with a message and non-zero exit code.
function fail() {
    echo "$1" >&2
    exit 1
}

# Helper to clean up after ourselves if we're killed by SIGINT.
function clean_up() {
    TDIR="${TMPDIR:-/tmp}"
    echo "Script killed, cleaning up tmpdirs: $TDIR/vscode_exts_*" >&2
    rm -Rf "$TDIR/vscode_exts_*"
}

function get_vsixpkg() {
    N="$1.$2"

    # Create a tempdir for the extension download.
    EXTTMP=$(mktemp -d -t vscode_exts_XXXXXXXX)

    URL="https://$1.gallery.vsassets.io/_apis/public/gallery/publisher/$1/extension/$2/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage"

    # Quietly but delicately curl down the file, blowing up at the first sign of trouble.
    curl --silent --show-error --retry 3 --fail -X GET -o "$EXTTMP/$N.zip" "$URL"
    # Unpack the file we need to stdout then pull out the version
    VER=$(jq -r '.version' <(unzip -qc "$EXTTMP/$N.zip" "extension/package.json"))
    # Calculate the hash
    HASH=$(nix-hash --flat --sri --type sha256 "$EXTTMP/$N.zip")

    # Clean up.
    rm -Rf "$EXTTMP"
    # I don't like 'rm -Rf' lurking in my scripts but this seems appropriate.

    cat <<-EOF
  {
    name = "$2";
    publisher = "$1";
    version = "$VER";
    hash = "$HASH";
  }
EOF
}

# See if we can find our `code` binary somewhere.
if [ $# -ne 0 ]; then
    CODE=$1
else
    CODE=$(command -v code || command -v codium)
fi

if [ -z "$CODE" ]; then
    # Not much point continuing.
    fail "VSCode executable not found"
fi

# Try to be a good citizen and clean up after ourselves if we're killed.
trap clean_up SIGINT

# Begin the printing of the nix expression that will house the list of extensions.
printf '{ extensions = [/n'
text="
adamraichu.font-viewer
alexanderius.language-hosts
apinix.indent-jump
avoonix.furry-language
bbenoist.nix
betterthantomorrow.paste-replaced
blueglassblock.better-json5
britesnow.vscode-toggle-quotes
bvpav.rcdbg
chamboug.js-auto-backticks
cheshirekow.cmake-format
christian-kohler.npm-intellisense
dbaeumer.vscode-eslint
debugpyattacher.debugpy-attacher
dinopitstudios.dinoscan-vscode
dohe.godot-format
donjayamanne.githistory
dotjoshjohnson.xml
durzn.brackethighlighter
eclipse-cdt.memory-inspector
ericsia.pythonsnippets3pro
esbenp.prettier-vscode
exodiusstudios.comment-anchors
fernandoescolar.vscode-solution-explorer
franneck94.c-cpp-runner
franneck94.workspace-formatter
geequlim.godot-tools
gydunhn.javascript-essentials
gydunhn.nodejs-essentials
gydunhn.typescript-essentials
gydunhn.vsc-essentials
iliazeus.vscode-ansi
ionutvmi.path-autocomplete
jnoortheen.nix-ide
jota0222.multi-formatter
lujstn.synthwave-fluoromachine-cursor
mark-wiemer.vscode-autohotkey-plus-plus
mattpocock.ts-error-translator
mechatroner.rainbow-csv
mgesbert.indent-nested-dictionary
mhutchie.git-graph
mikestead.dotenv
ms-mssql.mssql
ms-python.black-formatter
ms-python.debugpy
ms-python.python
ms-python.vscode-pylance
ms-vscode.hexeditor
ms-vscode.powershell
ms-vscode.vscode-js-profile-flame
naumovs.color-highlight
njpwerner.autodocstring
oliversturm.fix-json
oracle.oracle-java
oxideops.vscode-code-jump
prismlink.lunar-theme
qcz.text-power-tools
ramonjaspers.neon-extra-dark
rectcircle.str-conv
redhat.java
rioj7.regex-text-gen
robertostermann.inline-parameters-extended
rodolphebarbanneau.python-docstring-highlighter
rssaromeo.4-to-2-formatter
rssaromeo.auto-regex
rssaromeo.simple-auto-formatter
rssaromeo.simpledatastorage
rust-lang.rust-analyzer
rvest.vs-code-prettier-eslint
s-nlf-fh.glassit
saidtorres3.dark-plus-material-saidtorres3
se-dev-pion.rainbow-struct-field-tags
shader-slang.slang-language-extension
simonhe.vscode-highlight-text
solomonkinard.chrome-extension-api
solomonkinard.chrome-extensions
soyreneon.themeeditor
tekumara.typos-vscode
thomaswebb.ardalive
thqby.vscode-autohotkey2-lsp
unthrottled.doki-theme
usernamehw.autolink
usernamehw.errorlens
vadimcn.vscode-lldb
vscjava.vscode-java-debug
wix.vscode-import-cost
xabikos.javascriptsnippets
yoavbls.pretty-ts-errors
zero-plusplus.vscode-autohotkey-debug
zuban.zubanls"

# Note that we are only looking to update extensions that are already installed.
IFS=$'\n' read -d '' -r -a lines <<< "$text"
#   echo "LINE: $line"
# done <<< "$text"

# for i in  "${lines[@]}";
while IFS= read -r i; do
# do
    OWNER=$(echo "$i" | cut -d. -f1)
    EXT=$(echo "$i" | cut -d. -f2)

    get_vsixpkg "$OWNER" "$EXT"
done <<< "$text"
# Close off the nix expression.
printf '];/n}'