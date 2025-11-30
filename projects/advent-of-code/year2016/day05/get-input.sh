#!/bin/zsh

source ../../.env

aocdl -session-cookie $SESSION_COOKIE -year 2016 -day 5 -output aoc-input.txt -force