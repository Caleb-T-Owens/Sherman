#!/bin/zsh

source ../../.env

aocdl -session-cookie $SESSION_COOKIE -year 2024 -day 15 -output aoc-input.txt -force