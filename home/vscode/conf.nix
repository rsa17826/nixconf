{ config, pkgs, uname, ... }:

{
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    mutableExtensionsDir = false;

    profiles.default = {
      extensions =
        with pkgs.vscode-extensions;
        [ ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "font-viewer";
            publisher = "adamraichu";
            version = "1.1.1";
            hash = "sha256-0T5gxxFkb+Muf65aoU4ONtEbhsqE5H5W9BhVhsqTySM=";
          }
          {
            name = "indent-jump";
            publisher = "apinix";
            version = "1.0.3";
            hash = "sha256-rvYc5bF2pakEUjtniKjE5wDnoZM9JGDEN2Lxhh3AdMo=";
          }
          {
            name = "furry-language";
            publisher = "avoonix";
            version = "0.1.1";
            hash = "sha256-d4y17dG2J7VZq1g7uo+3Y1gp8+0qyaQKHAUqsSvlmq8=";
          }
          {
            name = "nix";
            publisher = "bbenoist";
            version = "1.0.1";
            hash = "sha256-qwxqOGublQeVP2qrLF94ndX/Be9oZOn+ZMCFX1yyoH0=";
          }
          {
            name = "paste-replaced";
            publisher = "betterthantomorrow";
            version = "1.1.13";
            hash = "sha256-yW51Vo7nSyQCVQAfrDjuWTSMAptv/h5oNV8z5KHFvIE=";
          }
          {
            name = "better-json5";
            publisher = "blueglassblock";
            version = "1.6.0";
            hash = "sha256-ySGU7LZqymZBfsKaVwKrqrIMGEItBMea5LM+/DHABFM=";
          }
          {
            name = "vscode-toggle-quotes";
            publisher = "britesnow";
            version = "0.3.6";
            hash = "sha256-Hn3Mk224ePAAnNtkhKMcCil/kTgbonweb1i884Q62rs=";
          }
          {
            name = "rcdbg";
            publisher = "bvpav";
            version = "0.0.1";
            hash = "sha256-6zDA3WacBlj0qn0D+WlrDqg90FOqTmQ9eajJfVv0bEs=";
          }
          {
            name = "js-auto-backticks";
            publisher = "chamboug";
            version = "1.2.0";
            hash = "sha256-sXs5B8sFFqDR1EiCfDIV92RXiaZPpcAfSosfYYSCJng=";
          }
          {
            name = "cmake-format";
            publisher = "cheshirekow";
            version = "0.6.11";
            hash = "sha256-NdU8J0rkrH5dFcLs8p4n/j2VpSP/X7eSz2j4CMDiYJM=";
          }
          {
            name = "npm-intellisense";
            publisher = "christian-kohler";
            version = "1.4.5";
            hash = "sha256-liuFGnyvvVHzSv60oLkemFyv85R+RiGKErRIUz2PYKs=";
          }
          {
            name = "vscode-eslint";
            publisher = "dbaeumer";
            version = "3.0.21";
            hash = "sha256-Ip9q7BroIVNsxbO/OcZuJWagYsYtV2xJhe0z0NFiR2U=";
          }
          # {
          #   name = "debugpy-attacher";
          #   publisher = "debugpyattacher";
          #   version = "1.3.0";
          #   hash = "sha256-L3x5jTKSQ94JCJbo4LKk2m/xovtYeafwBZNSY/vr6VY=";
          # }
          # {
          #   name = "dinoscan-vscode";
          #   publisher = "dinopitstudios";
          #   version = "2.0.4";
          #   hash = "sha256-SgFVGDG+GazOn4xsH3tpqgTzcZVOraI3Vsz9Z0wW7Lg=";
          # }
          {
            name = "godot-format";
            publisher = "dohe";
            version = "0.2.12";
            hash = "sha256-CdP3hiOZctv++3KsMIzL3yKa9XStaKGHg6NSDYHyCno=";
            #hash = "sha256-Q2MytY6oECn4RmSHxzo/dOfOvwlUU70kiYSiX7peyFQ=";
          }
          {
            name = "githistory";
            publisher = "donjayamanne";
            version = "0.6.20";
            hash = "sha256-nEdYS9/cMS4dcbFje23a47QBZr9eDK3dvtkFWqA+OHU=";
          }
          {
            name = "xml";
            publisher = "dotjoshjohnson";
            version = "2.5.1";
            hash = "sha256-ZwBNvbld8P1mLcKS7iHDqzxc8T6P1C+JQy54+6E3new=";
          }
          {
            name = "brackethighlighter";
            publisher = "durzn";
            version = "3.0.4";
            hash = "sha256-zCi+4tJPOYd2flisWBCd+dI+fMxCEEzxNnYbeIEaLmY=";
          }
          {
            name = "memory-inspector";
            publisher = "eclipse-cdt";
            version = "1.2.0";
            hash = "sha256-hlABFIYoCpwLsm7860xP0vmVDtVeDbAFDPfZJzfgXF8=";
          }
          {
            name = "pythonsnippets3pro";
            publisher = "ericsia";
            version = "3.3.4";
            hash = "sha256-Pdn6vq30eMZQF0n07eMqZtRlLyvy688JowZ79kXoeaY=";
          }
          {
            name = "prettier-vscode";
            publisher = "esbenp";
            version = "11.0.2";
            hash = "sha256-PwP49p1gpxfx3AmGFhNvRBBc4SxWM2b9aaiUG/C+Uhg=";
          }
          {
            name = "comment-anchors";
            publisher = "exodiusstudios";
            version = "1.10.4";
            hash = "sha256-FvfjPpQsgCsnY1BylhLCM/qDQChf9/iTr3cKkCGfMVI=";
          }
          {
            name = "vscode-solution-explorer";
            publisher = "fernandoescolar";
            version = "0.9.2";
            hash = "sha256-8RtHYumWkdZhU71RQ/jauKUzWgwJxpEZqB/fVfZ501w=";
          }
          {
            name = "c-cpp-runner";
            publisher = "franneck94";
            version = "9.5.0";
            hash = "sha256-DNoDe118tJAB2buN8/4PJ73z2xg+HQOoRaLF1pldJTM=";
          }
          {
            name = "workspace-formatter";
            publisher = "franneck94";
            version = "1.2.2";
            hash = "sha256-YooThmx+FUMD9eSaiI1NHO2AZppSBHtYdFJ9La4k0pQ=";
          }
          {
            name = "godot-tools";
            publisher = "geequlim";
            version = "2.5.1";
            hash = "sha256-kAzRSNZw1zaECblJv7NzXnE2JXSy9hzdT2cGX+uwleY=";
          }
          {
            name = "javascript-essentials";
            publisher = "gydunhn";
            version = "0.3.0";
            hash = "sha256-J889tzSewEYFhw47rW0IrvdAwCnOpus2qEuvdGk1b0o=";
          }
          {
            name = "nodejs-essentials";
            publisher = "gydunhn";
            version = "1.0.0";
            hash = "sha256-MrlY0mhCQ5WLPEDADcTmDlKJIQN8VPtjiza5Rtwv2v0=";
          }
          {
            name = "typescript-essentials";
            publisher = "gydunhn";
            version = "1.2.0";
            hash = "sha256-mfhSiVpuluMmtwm5k504rgJZYJ/68CTNeFjG3Y30eQQ=";
          }
          {
            name = "vsc-essentials";
            publisher = "gydunhn";
            version = "2.3.0";
            hash = "sha256-svNVoaGZDHB5CdOykeQcQLQPSJ0spzoAw0Nr/dFB+2g=";
          }
          {
            name = "vscode-ansi";
            publisher = "iliazeus";
            version = "1.1.7";
            hash = "sha256-3/rsYq+HZgRW2Vd91ZW9rkXWUTUFzG/mCWD0pm++WA4=";
          }
          {
            name = "path-autocomplete";
            publisher = "ionutvmi";
            version = "1.25.0";
            hash = "sha256-iz32o1znwKpbJSdrDYf+GDPC++uGvsCdUuGaQu6AWEo=";
          }
          {
            name = "nix-ide";
            publisher = "jnoortheen";
            version = "0.5.0";
            hash = "sha256-jVuGQzMspbMojYq+af5fmuiaS3l3moG8L8Kyf40vots=";
          }
          {
            name = "multi-formatter";
            publisher = "jota0222";
            version = "1.6.2";
            hash = "sha256-YDX5MOgNMQu1R6evYqKm/R4y70lLsa+SKfwchTd2oHM=";
          }
          {
            name = "synthwave-fluoromachine-cursor";
            publisher = "lujstn";
            version = "0.2.1";
            hash = "sha256-OOQu0OJMx54dGpH4dqx/jszwhZEDtE2nMvjUol0uc+U=";
          }
          {
            name = "vscode-autohotkey-plus-plus";
            publisher = "mark-wiemer";
            version = "6.7.1";
            hash = "sha256-kwFVUhT1W5iQhxvKhHy00cCgL1jcSFGLCSg4/3TH78Q=";
          }
          {
            name = "ts-error-translator";
            publisher = "mattpocock";
            version = "0.10.1";
            hash = "sha256-WBdtRFaGKUmsriwUgNRToaqGJ6sdzrvOMs/fhEQFmws=";
          }
          {
            name = "rainbow-csv";
            publisher = "mechatroner";
            version = "3.23.0";
            hash = "sha256-HEbx7vjuVFjAG0koFI/JRehivRiLBF0cgx24LhdwCBc=";
          }
          {
            name = "indent-nested-dictionary";
            publisher = "mgesbert";
            version = "0.0.4";
            hash = "sha256-zML2jEAouVVw3J5EWk4vRIyC9WXHVDRsaviIB5Zets8=";
          }
          {
            name = "git-graph";
            publisher = "mhutchie";
            version = "1.30.0";
            hash = "sha256-sHeaMMr5hmQ0kAFZxxMiRk6f0mfjkg2XMnA4Gf+DHwA=";
          }
          {
            name = "dotenv";
            publisher = "mikestead";
            version = "1.0.1";
            hash = "sha256-dieCzNOIcZiTGu4Mv5zYlG7jLhaEsJR05qbzzzQ7RWc=";
          }
          {
            name = "mssql";
            publisher = "ms-mssql";
            version = "1.37.1";
            hash = "sha256-OmJgyh6nX2nbhrF/cjbhpll+1gh5bLGlqCAbtst8wsY=";
          }
          {
            name = "black-formatter";
            publisher = "ms-python";
            version = "2025.3.11831009";
            hash = "sha256-FsJHxYHae1NuDXQfOJ4TPnXDy05tTuyCElHD4MiaMDU=";
          }
          {
            name = "debugpy";
            publisher = "ms-python";
            version = "2025.17.2025121103";
            hash = "sha256-Mt129kktLvt4Xs2ElV5HfxsAsAkg67vjJQqutJyjZRc=";
          }
          {
            name = "python";
            publisher = "ms-python";
            version = "2025.20.0";
            hash = "sha256-+VaAABB3/AgSTg2JzoqUtTz8fRNFr0aQjwzBYYFLhYE=";
          }
          {
            name = "vscode-pylance";
            publisher = "ms-python";
            version = "2025.10.100";
            hash = "sha256-XOuI0WPYV3Nnvst7keizPHUnQfa3P+WULttoHb3ZRVI=";
          }
          {
            name = "hexeditor";
            publisher = "ms-vscode";
            version = "1.11.1";
            hash = "sha256-RB5YOp30tfMEzGyXpOwPIHzXqZlRGc+pXiJ3foego7Y=";
          }
          {
            name = "powershell";
            publisher = "ms-vscode";
            version = "2025.5.0";
            hash = "sha256-783H9vJngIdQrPBVjyTuMOwJaxr7gswmclvR6E4jwjQ=";
          }
          {
            name = "vscode-js-profile-flame";
            publisher = "ms-vscode";
            version = "1.0.9";
            hash = "sha256-t/LbnMt8zeQKqlf0YWjoLggxIaxTZOOOswPW1GGSh6o=";
          }
          {
            name = "color-highlight";
            publisher = "naumovs";
            version = "2.8.0";
            hash = "sha256-mT2P1lEdW66YkDRN6fi0rmmvvyBfXiJjAUHns8a8ipE=";
          }
          {
            name = "autodocstring";
            publisher = "njpwerner";
            version = "0.6.1";
            hash = "sha256-NI0cbjsZPW8n6qRTRKoqznSDhLZRUguP7Sa/d0feeoc=";
          }
          {
            name = "fix-json";
            publisher = "oliversturm";
            version = "0.2.0";
            hash = "sha256-TOu+/oo42dq5wJu1HcYe0Kz+AtOHEnFUsdy3zKruTRw=";
          }
          {
            name = "oracle-java";
            publisher = "oracle";
            version = "25.0.0";
            hash = "sha256-e0DO+42+3CyMP3+25gj0kLDFK53vkv4UqD2pQhXmqng=";
          }
          {
            name = "vscode-code-jump";
            publisher = "oxideops";
            version = "1.0.5";
            hash = "sha256-bDwqHacMyq1yo3IngWeWOIEAeT6fdbLdiFEx1/unyZo=";
          }
          {
            name = "lunar-theme";
            publisher = "prismlink";
            version = "1.2.1";
            hash = "sha256-pw16cSiDT8yujQrbRyw9sRiE8YzEdhZL4iOrDZwZs6c=";
          }
          {
            name = "text-power-tools";
            publisher = "qcz";
            version = "1.51.0";
            hash = "sha256-VM4JKkmpLQwgGriMVFrUt58fA/9e+ZRxy3yHDTi6Sxg=";
          }
          {
            name = "str-conv";
            publisher = "rectcircle";
            version = "1.2.1";
            hash = "sha256-60QSI8jXO7OiGMKvpuSYOQ1BTi/XnM6sECWUperbuYk=";
          }
          {
            name = "regex-text-gen";
            publisher = "rioj7";
            version = "0.14.0";
            hash = "sha256-9gv9+tbiAT6bI4Oy0Y/N/KW9+nKGg32sIxGGeLot0M0=";
          }
          {
            name = "inline-parameters-extended";
            publisher = "robertostermann";
            version = "1.3.5";
            hash = "sha256-eG7+16Y3lh/AHWu2Is19/6Va5vlqve5yRDReeerSzHU=";
          }
          {
            name = "python-docstring-highlighter";
            publisher = "rodolphebarbanneau";
            version = "0.2.4";
            hash = "sha256-g0LcV/S1eZij+8YXW3NpfGm5gJGeoobqDUcAF66UpWI=";
          }
          {
            name = "rust-analyzer";
            publisher = "rust-lang";
            version = "0.4.2715";
            hash = "sha256-v5htid5XsJu3cbZ+zO4R3VSY7JUD+M2/kWXyhS4H370=";
          }
          {
            name = "vs-code-prettier-eslint";
            publisher = "rvest";
            version = "6.0.0";
            hash = "sha256-PogNeKhIlcGxUKrW5gHvFhNluUelWDGHCdg5K+xGXJY=";
          }
          {
            name = "glassit";
            publisher = "s-nlf-fh";
            version = "0.2.6";
            hash = "sha256-LcAomgK91hnJWqAW4I0FAgTOwr8Kwv7ZhvGCgkokKuY=";
          }
          {
            name = "dark-plus-material-saidtorres3";
            publisher = "saidtorres3";
            version = "2.7.5";
            hash = "sha256-tkOyPCJQhDgsXGNG6zS9UuBGBt81BGAzQlX7o5sfKoE=";
          }
          {
            name = "rainbow-struct-field-tags";
            publisher = "se-dev-pion";
            version = "0.3.1";
            hash = "sha256-GtuvLfEmdA2oRaDGksWPcw12fJugskCXT9gwSP3MYTk=";
          }
          {
            name = "slang-language-extension";
            publisher = "shader-slang";
            version = "2.0.3";
            hash = "sha256-7Dr4+6IwpgpuXX5qPU/ZpwBLPMl+ckqqIBc7Vja2Apc=";
          }
          {
            name = "vscode-highlight-text";
            publisher = "simonhe";
            version = "0.0.49";
            hash = "sha256-YBHJmVBRu37Xtc76cp2V60pQUBwKqBcsprVKDxeGHlY=";
          }
          {
            name = "chrome-extension-api";
            publisher = "solomonkinard";
            version = "0.0.5";
            hash = "sha256-pAAoRu7IAbwk3rVzTti2rD3tNot7uD4mrASzm66NSuk=";
          }
          {
            name = "chrome-extensions";
            publisher = "solomonkinard";
            version = "0.1.1";
            hash = "sha256-T4RvRYbUw+BDvdGWSySeR7ta3k7adtSOJZfSG0t9nHA=";
          }
          # {
          #   name = "themeeditor";
          #   publisher = "soyreneon";
          #   version = "1.14.3";
          #   hash = "sha256-nn8eQl9ZhFuHtZ6ZGcvJsDSkbucN6kf9vrWjL3TFrB4=";
          # }
          {
            name = "typos-vscode";
            publisher = "tekumara";
            version = "0.1.46";
            hash = "sha256-J4dXECKOq+EF4JnzpyWg6GQI9EAL8YlMtbR0zaX3dUU=";
          }
          # {
          #   name = "doki-theme";
          #   publisher = "unthrottled";
          #   version = "88.1.18";
          #   hash = "sha256-7Ditwj7U26t3v4ofpqw/sHar6uE46E4DWVwGZjziZfM=";
          # }
          {
            name = "autolink";
            publisher = "usernamehw";
            version = "1.0.0";
            hash = "sha256-DHw6Sy2ziLstoJeeCbTNZC1STgzRlXWzbjrjIpqe2u8=";
          }
          {
            name = "errorlens";
            publisher = "usernamehw";
            version = "3.26.0";
            hash = "sha256-pAkk3QURnlLNMZ2cFBks2lAEl/Hk8Z2i/QgvjUv+u2Y=";
          }
          {
            name = "vscode-java-debug";
            publisher = "vscjava";
            version = "0.58.2025112507";
            hash = "sha256-uYrpfZfK3Vuq89/hW9TGVqmmyELAFJsJVFZmDNtD2CI=";
          }
          {
            name = "vscode-import-cost";
            publisher = "wix";
            version = "3.3.0";
            hash = "sha256-GQ26Cmu9F/6+3NMoxsb1BHqKqaVAx+qWNW0rYBHdiHI=";
          }
          {
            name = "javascriptsnippets";
            publisher = "xabikos";
            version = "1.8.0";
            hash = "sha256-ht6Wm1X7zien+fjMv864qP+Oz4M6X6f2RXjrThURr6c=";
          }
          {
            name = "pretty-ts-errors";
            publisher = "yoavbls";
            version = "0.6.3";
            hash = "sha256-7yoNuYg31hbtU4HATG4VAERcMk5KPRA3WLouSJo3rxs=";
          }
          {
            name = "vscode-autohotkey-debug";
            publisher = "zero-plusplus";
            version = "1.11.1";
            hash = "sha256-4PZHB3NZz5++w+zCuJ21B+aSVhtzaD4puAP2z+HmBWA=";
          }

        ];
    };
  };
  home.activation.copy-vscode-settings = ''
    echo "Copying VSCode settings..."
    mkdir -p "$HOME/.config/VSCodium/User"
    cp -f ${./settings.json} "$HOME/.config/VSCodium/User/settings.json"
    cp -f ${./keybindings.json} "$HOME/.config/VSCodium/User/keybindings.json"
    sed -ri 's/\$\{uname\}/${uname}/g' "$HOME/.config/VSCodium/User/settings.json"
  '';
}
