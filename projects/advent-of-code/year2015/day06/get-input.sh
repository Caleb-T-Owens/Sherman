#!/bin/zsh

source ../../.env

aocdl -session-cookie $SESSION_COOKIE -year 2015 -day 6 -output aoc-input.txt -force