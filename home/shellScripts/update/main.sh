#!/usr/bin/env bash
cd $HOME/nixconf
movedIn = $?
push
if [[movedIn]] ;then
cd -
fi
sudo nixos-rebuild switch --flake ~/nixconf#$USER --impure --log-format internal-json -v --show-trace |& nom --json
