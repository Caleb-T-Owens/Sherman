# Advent of Code

All my solutions can be run with `./setup.sh && ./run.sh` (in theory). `./run-fast.sh` will exclude any solutions that take a long time to run.

Advent of Code problems are designed to be solvable in under 15 seconds on what would now be 16 year old hardware. I try to make reasonable solutions that finish in under a second, but I'm also not opposed to making use of high-end hardware to brute force my way through a puzzle that doesn't capture my interest in the moment.

A big thanks to Eric and the other kind folks who make Advent of Code happen. I love high quality puzzles like this, and the story that complements them is just fantastic.

## Slow entries

-   year2024/day09
-   year2024/day18
-   year2024/day22

## Incomplete solutions

-   year2024/day24 part 2 was solved via manual inspection

## Inputs

My solutions typically expect to find the puzzle input under a gitignored `aoc-input.txt`. I've set up [GreenLightning's Advent of Code downloader](https://github.com/GreenLightning/advent-of-code-downloader), which will download all of your inputs automagically.

It requires a `.env` folder which looks like:

```sh
export SESSION_COOKIE=xxxx
```

You can find the right cookie using the instructions provided by GreenLightning.

## Large Language Models

In general I have a fairly dim view of LLMs when it comes to software development. I would much rather think about a problem and then write code, rather than having an LLM generate some code-like output which I then have to validate and debug. Smashing an intelligent monkey into a typewriter is still a monkey and a typewriter.

The whole point of solving coding puzzles is the problem-solving and learning that comes from completing it. Using an LLM would make it an unintelligent game of cat and mouse.
