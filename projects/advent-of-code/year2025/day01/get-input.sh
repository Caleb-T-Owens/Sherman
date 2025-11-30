#!/bin/zsh

source ../../.env

aocdl -session-cookie $SESSION_COOKIE -year 2025 -day 1 -output aoc-input.txt -force