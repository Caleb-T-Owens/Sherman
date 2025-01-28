#!/bin/bash

if type -a rustup >&2;
then
    rustup update
else
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
fi