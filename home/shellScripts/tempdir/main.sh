#!/usr/bin/env bash
t=$(mktemp -d)
pushd "$t" || exit
$SHELL
popd || exit
rm -rf "$t"
