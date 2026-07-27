{ pkgs, ... }:
{
  programs = {
    vscodium = {
      profiles = {
        default = {
          extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "ruff-toolkit";
              publisher = "sagarkarn";
              version = "1.0.2";
              hash = "sha256-iJJ+Cd7qFMaGLd87E4lfI9U4yvvzDt1H5scz4dzLKBU=";
            }
            {
              name = "vscode-autohotkey2-lsp";
              publisher = "thqby";
              version = "3.0.10";
              hash = "sha256-ESshpZk2zG8ADqhzqpiAYK/W6jWmlySzyf31IZxlWZg=";
            }
            {
              name = "lua";
              publisher = "sumneko";
              version = "3.18.2";
              hash = "sha256-8mvauayksFk/3A7VMJ3EZYyRK8YLgX03W7bzEIdGkXQ=";
            }
            {
              name = "shader";
              publisher = "slevesque";
              version = "1.1.5";
              hash = "sha256-Pf37FeQMNlv74f7LMz9+CKscF6UjTZ7ZpcaZFKtX2ZM=";
            }
            {
              name = "clang-format";
              publisher = "xaver";
              version = "1.9.0";
              hash = "sha256-q9DvkXbv+GTyeMVIyUQDK49Njsl9msbnOD1gyS4ljC8=";
            }
            {
              name = "hide-error-cases";
              publisher = "taqanori";
              version = "1.0.8";
              hash = "sha256-U3W7gO2EvMuZWrBmdHSPSWQbJNL4wIoo9IL/6GKB+pc=";
            }
            {
              name = "Go";
              publisher = "golang";
              version = "0.57.0";
              hash = "sha256-q3YnRT1CyD5/lLQ3sIewW4yGkBGbGZxTrnceAC6+qMU=";
            }
            {
              name = "csstools-design-tokens";
              publisher = "RomainMenke";
              version = "1.2.1";
              hash = "sha256-YVtByhQxebH3fdnNweVSBsTugm9hhhi4qNM21EWxOW8=";
            }
            {
              name = "css-custom-property-inspector";
              publisher = "schalkneethling";
              version = "0.1.1";
              hash = "sha256-SA7AX9pam3mBm18JlGEMyh/bua2xEWnyoI9zQYq3Gg8=";
            }
            {
              name = "search-everywhere-lite";
              publisher = "Maorlevinshtein";
              version = "0.2.4";
              hash = "sha256-8GL1s72CR9A3OkcLQNnalyfDWEoAYGVbrsTDZNKxQ6I=";
            }
            {
              name = "language-stylus";
              publisher = "sysoev";
              version = "1.16.0";
              hash = "sha256-9Wwlz6IXQiqevFSu3oZkKbyg+ix99JNpYKUSgOQpd6k=";
            }
            {
              name = "stylua";
              publisher = "JohnnyMorganz";
              version = "1.7.2";
              hash = "sha256-l/znKp+myNqS8RYVAyBGn5Up9LfXs0HPUr1ZrV4CrKE=";
            }
            {
              name = "Kotlin";
              publisher = "mathiasfrohlich";
              version = "1.7.1";
              hash = "sha256-MuAlX6cdYMLYRX2sLnaxWzdNPcZ4G0Fdf04fmnzQKH4=";
            }
            {
              name = "compare-folders";
              publisher = "moshfeu";
              version = "0.30.0";
              hash = "sha256-XBMHEk5iRW6n9fjDUbD8c/FFGNRttrnV0tH1qUphXYo=";
            }
            # {
            #   name = "fix-all-json";
            #   publisher = "zardoy";
            #   version = "0.1.6";
            #   hash = "sha256-5XQqdy5BlFhtNyrzgd/P+CTOc+fhciGGwpvipTRdpqM=";
            # }
            {
              name = "shellcheck";
              publisher = "timonwong";
              version = "0.39.5";
              hash = "sha256-8f9LGmNE8ilPYZmbJpmmAx9DkKJXbQzAia11rM3wTec=";
            }
            {
              name = "zubanls";
              publisher = "zuban";
              version = "0.2.3";
              hash = "sha256-O46EMBoyXEYBe63UIRTLjHHNSKnQqAYj5dHnqn86/co=";
            }
            {
              name = "direnv";
              publisher = "mkhl";
              version = "0.17.0";
              hash = "sha256-9sFcfTMeLBGw2ET1snqQ6Uk//D/vcD9AVsZfnUNrWNg=";
            }
            {
              name = "shell-tidy-vscode";
              publisher = "xqvvu";
              version = "1.1.2";
              hash = "sha256-wi2JDzeWbJpzYlp224XZ7wDXRy09V+VEaXVubAfbuZw=";
            }
            {
              name = "qml-format";
              publisher = "Delgan";
              version = "1.1.0";
              hash = "sha256-QOovj9loSWAgaBCwW3HBPD/Wr7GwVppSRcCJ4R5X/as=";
            }
            {
              name = "qt-python";
              publisher = "theqtcompany";
              version = "1.15.1";
              hash = "sha256-OqU9IYZd1pJ+9GlD1HUqJxSnWl1c+f3Klv9q6Ypf7vg=";
            }
            {
              name = "qt-core";
              publisher = "theqtcompany";
              version = "1.15.1";
              hash = "sha256-KOQPOsoEbNkdSTbLAVmCQiy9G3bguxU+ZMNC761PzPw=";
            }
            {
              name = "qt-ui";
              publisher = "theqtcompany";
              version = "1.15.1";
              hash = "sha256-+2Cy+wqW4FBZZAAmU78keJr28MPDV+g/hQ7xtkuZGTg=";
            }
            {
              name = "qt-qml";
              publisher = "theqtcompany";
              version = "1.15.1";
              hash = "sha256-pHWqTvuWJKm6Mmt5ycR9C69v+ANgu1tXCNtzliR/dHA=";
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
              name = "vscode-toggle-quotes";
              publisher = "britesnow";
              version = "0.3.6";
              hash = "sha256-Hn3Mk224ePAAnNtkhKMcCil/kTgbonweb1i884Q62rs=";
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
              version = "3.0.34";
              hash = "sha256-ynCPFzne4YS4WNjQSmGky+e2IaE3SLxj6FkjKyLPcAs=";
            }
            {
              name = "godot-format";
              publisher = "dohe";
              version = "0.4.1";
              hash = "sha256-Hjh0iB402MgWlsOQMb2ipGuCdvTxnpwYf72rnGVPg2Y=";
            }
            {
              name = "githistory";
              publisher = "donjayamanne";
              version = "0.6.20";
              hash = "sha256-nEdYS9/cMS4dcbFje23a47QBZr9eDK3dvtkFWqA+OHU=";
            }
            {
              name = "prettier-vscode";
              publisher = "esbenp";
              version = "12.4.0";
              hash = "sha256-RtIqVns16+W9/9coBFd0LNZ+ZdfhslC7d1qyvoZHmkI=";
            }
            {
              name = "comment-anchors";
              publisher = "exodiusstudios";
              version = "1.10.4";
              hash = "sha256-FvfjPpQsgCsnY1BylhLCM/qDQChf9/iTr3cKkCGfMVI=";
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
              version = "2.7.1";
              hash = "sha256-TNCMSmZdBXxAHkcFLpTDkCzaXNO4yvkCfQ8Xrb9gquo=";
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
              version = "0.5.13";
              hash = "sha256-0pMMnYFX+Ghs42Tvfcv9QqwhrEhCjIa7+6xJ51Fa0Dk=";
            }
            {
              name = "multi-formatter";
              publisher = "jota0222";
              version = "1.6.2";
              hash = "sha256-YDX5MOgNMQu1R6evYqKm/R4y70lLsa+SKfwchTd2oHM=";
            }
            {
              name = "basedpyright";
              publisher = "detachhead";
              version = "1.39.9";
              hash = "sha256-Iycuj7EXzRwVgvpk0KXa3dNw2rL21DnG4ohqIExS6Go=";
            }
            # {
            #   name = "synthwave-fluoromachine-cursor";
            #   publisher = "lujstn";
            #   version = "0.2.1";
            #   hash = "sha256-OOQu0OJMx54dGpH4dqx/jszwhZEDtE2nMvjUol0uc+U=";
            # }
            {
              name = "ts-error-translator";
              publisher = "mattpocock";
              version = "0.10.1";
              hash = "sha256-WBdtRFaGKUmsriwUgNRToaqGJ6sdzrvOMs/fhEQFmws=";
            }
            {
              name = "rainbow-csv";
              publisher = "mechatroner";
              version = "3.24.1";
              hash = "sha256-xZpK6pJNXnxudauzJihEi9VASRXi89+hn7vfF33qRgY=";
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
              name = "debugpy";
              publisher = "ms-python";
              version = "2026.7.12031010";
              hash = "sha256-rxfDCNyW3zQLZrzyiu04LCm9f7TiK8Q8pBxiWk8x0rY=";
            }
            {
              name = "python";
              publisher = "ms-python";
              version = "2026.5.2026070801";
              hash = "sha256-ft9F6Ok/0VU3P9+AAAxW51NE5RlEK6VwtFPaMYq+GLg=";
            }
            {
              name = "hexeditor";
              publisher = "ms-vscode";
              version = "1.11.1";
              hash = "sha256-RB5YOp30tfMEzGyXpOwPIHzXqZlRGc+pXiJ3foego7Y=";
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
              name = "vs-code-prettier-eslint";
              publisher = "rvest";
              version = "6.0.0";
              hash = "sha256-PogNeKhIlcGxUKrW5gHvFhNluUelWDGHCdg5K+xGXJY=";
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
              version = "0.4.0";
              hash = "sha256-uxxNa51ZA3wdWkydSX223L7DoikEjuIlLIuJYJunkUE=";
            }
            {
              name = "vscode-highlight-text";
              publisher = "simonhe";
              version = "0.0.49";
              hash = "sha256-YBHJmVBRu37Xtc76cp2V60pQUBwKqBcsprVKDxeGHlY=";
            }
            # {
            #   name = "chrome-extension-api";
            #   publisher = "solomonkinard";
            #   version = "0.0.5";
            #   hash = "sha256-pAAoRu7IAbwk3rVzTti2rD3tNot7uD4mrASzm66NSuk=";
            # }
            {
              name = "typos-vscode";
              publisher = "tekumara";
              version = "0.1.52";
              hash = "sha256-o+AQDdToXTV/pUSt2zw19hf7nwbOb4gb9dlSsB7t32E=";
            }
            {
              name = "autolink";
              publisher = "usernamehw";
              version = "1.0.0";
              hash = "sha256-DHw6Sy2ziLstoJeeCbTNZC1STgzRlXWzbjrjIpqe2u8=";
            }
            {
              name = "errorlens";
              publisher = "usernamehw";
              version = "3.28.0";
              hash = "sha256-7eu7y9IR1uxSFZ0IplDieFt3iWbcmdwf1lAcXq+S4C8=";
            }
            {
              name = "vscode-import-cost";
              publisher = "wix";
              version = "3.3.0";
              hash = "sha256-GQ26Cmu9F/6+3NMoxsb1BHqKqaVAx+qWNW0rYBHdiHI=";
            }
            # {
            #   name = "font-viewer";
            #   publisher = "adamraichu";
            #   version = "1.1.1";
            #   hash = "sha256-0T5gxxFkb+Muf65aoU4ONtEbhsqE5H5W9BhVhsqTySM=";
            # {
            #   name = "better-json5";
            #   publisher = "blueglassblock";
            #   version = "1.6.0";
            #   hash = "sha256-ySGU7LZqymZBfsKaVwKrqrIMGEItBMea5LM+/DHABFM=";
            # {
            #   name = "rcdbg";
            #   publisher = "bvpav";
            #   version = "0.0.1";
            #   hash = "sha256-6zDA3WacBlj0qn0D+WlrDqg90FOqTmQ9eajJfVv0bEs=";
            # }
            # {
            #   name = "js-auto-backticks";
            #   publisher = "chamboug";
            #   version = "1.2.0";
            #   hash = "sha256-sXs5B8sFFqDR1EiCfDIV92RXiaZPpcAfSosfYYSCJng=";
            # }
            # {
            #   name = "cmake-format";
            #   publisher = "cheshirekow";
            #   version = "0.6.11";
            #   hash = "sha256-NdU8J0rkrH5dFcLs8p4n/j2VpSP/X7eSz2j4CMDiYJM=";
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
            # {
            #   name = "xml";
            #   publisher = "dotjoshjohnson";
            #   version = "2.5.1";
            #   hash = "sha256-ZwBNvbld8P1mLcKS7iHDqzxc8T6P1C+JQy54+6E3new=";
            # }
            # {
            #   name = "brackethighlighter";
            #   publisher = "durzn";
            #   version = "3.0.4";
            #   hash = "sha256-zCi+4tJPOYd2flisWBCd+dI+fMxCEEzxNnYbeIEaLmY=";
            # }
            # {
            #   name = "memory-inspector";
            #   publisher = "eclipse-cdt";
            #   version = "1.2.0";
            #   hash = "sha256-hlABFIYoCpwLsm7860xP0vmVDtVeDbAFDPfZJzfgXF8=";
            # }
            # {
            #   name = "pythonsnippets3pro";
            #   publisher = "ericsia";
            #   version = "3.3.4";
            #   hash = "sha256-Pdn6vq30eMZQF0n07eMqZtRlLyvy688JowZ79kXoeaY=";
            # {
            #   name = "vscode-solution-explorer";
            #   publisher = "fernandoescolar";
            #   version = "0.9.2";
            #   hash = "sha256-8RtHYumWkdZhU71RQ/jauKUzWgwJxpEZqB/fVfZ501w=";
            # }
            # {
            #   name = "c-cpp-runner";
            #   publisher = "franneck94";
            #   version = "9.5.0";
            #   hash = "sha256-DNoDe118tJAB2buN8/4PJ73z2xg+HQOoRaLF1pldJTM=";
            # {
            #   name = "vscode-autohotkey-plus-plus";
            #   publisher = "mark-wiemer";
            #   version = "6.7.1";
            #   hash = "sha256-kwFVUhT1W5iQhxvKhHy00cCgL1jcSFGLCSg4/3TH78Q=";
            # {
            #   name = "mssql";
            #   publisher = "ms-mssql";
            #   version = "1.37.1";
            #   hash = "sha256-OmJgyh6nX2nbhrF/cjbhpll+1gh5bLGlqCAbtst8wsY=";
            # {
            #   name = "powershell";
            #   publisher = "ms-vscode";
            #   version = "2025.5.0";
            #   hash = "sha256-783H9vJngIdQrPBVjyTuMOwJaxr7gswmclvR6E4jwjQ=";
            # }
            # {
            #   name = "vscode-js-profile-flame";
            #   publisher = "ms-vscode";
            #   version = "1.0.9";
            #   hash = "sha256-t/LbnMt8zeQKqlf0YWjoLggxIaxTZOOOswPW1GGSh6o=";
            # {
            #   name = "fix-json";
            #   publisher = "oliversturm";
            #   version = "0.2.0";
            #   hash = "sha256-TOu+/oo42dq5wJu1HcYe0Kz+AtOHEnFUsdy3zKruTRw=";
            # {
            #   name = "str-conv";
            #   publisher = "rectcircle";
            #   version = "1.2.1";
            #   hash = "sha256-60QSI8jXO7OiGMKvpuSYOQ1BTi/XnM6sECWUperbuYk=";
            # }
            # {
            # TODO
            #   name = "regex-text-gen";
            #   publisher = "rioj7";
            #   version = "0.14.0";
            #   hash = "sha256-9gv9+tbiAT6bI4Oy0Y/N/KW9+nKGg32sIxGGeLot0M0=";
            # {
            #   name = "rust-analyzer";
            #   publisher = "rust-lang";
            #   version = "0.4.2715";
            #   hash = "sha256-v5htid5XsJu3cbZ+zO4R3VSY7JUD+M2/kWXyhS4H370=";
            # {
            #   name = "glassit";
            #   publisher = "s-nlf-fh";
            #   version = "0.2.6";
            #   hash = "sha256-LcAomgK91hnJWqAW4I0FAgTOwr8Kwv7ZhvGCgkokKuY=";
            # {
            #   name = "slang-language-extension";
            #   publisher = "shader-slang";
            #   version = "2.0.3";
            #   hash = "sha256-7Dr4+6IwpgpuXX5qPU/ZpwBLPMl+ckqqIBc7Vja2Apc=";
            # {
            #   name = "themeeditor";
            #   publisher = "soyreneon";
            #   version = "1.14.3";
            #   hash = "sha256-nn8eQl9ZhFuHtZ6ZGcvJsDSkbucN6kf9vrWjL3TFrB4=";
            # {
            #   name = "doki-theme";
            #   publisher = "unthrottled";
            #   version = "88.1.18";
            #   hash = "sha256-7Ditwj7U26t3v4ofpqw/sHar6uE46E4DWVwGZjziZfM=";
            # {
            #   name = "javascriptsnippets";
            #   publisher = "xabikos";
            #   version = "1.8.0";
            #   hash = "sha256-ht6Wm1X7zien+fjMv864qP+Oz4M6X6f2RXjrThURr6c=";
            # }
            #{
            #  name = "pretty-ts-errors";
            #  publisher = "yoavbls";
            #  version = "0.6.3";
            #  hash = "sha256-7yoNuYg31hbtU4HATG4VAERcMk5KPRA3WLouSJo3rxs=";
            #}
            # {
            #   name = "vscode-autohotkey-debug";
            #   publisher = "zero-plusplus";
            #   version = "1.11.1";
            #   hash = "sha256-4PZHB3NZz5++w+zCuJ21B+aSVhtzaD4puAP2z+HmBWA=";
            # }
          ];
        };
      };
    };
  };
}
