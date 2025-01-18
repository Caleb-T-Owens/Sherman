# Sherman the shell config

Warning: There is LOTS of shell scripting that may delete EVERYTHING.

## What is in sherman?

Sherman is a living mono-repo where I do my computing. Here is an overview of
what is inside.

- [projects](/projects): The main home of projects in Sherman.
  - [advent-of-code](/projects/advent-of-code):
    My 2024 [Advent of Code](https://adventofcode.com) solutions, along with
    new completions of previous years.
  - [daft-commit](/projects/daft-commit):
    A little WIP utility to allow you to make commits out of order.
  - [doodles/leftmost-smallest](/projects/doodles/leftmost-smallest):
    A small puzzle posted on linkedin.
  - [impossible-puzzle](/projects/impossible-puzzle):
    A puzzle that was posted on a puzzle solving Redit. The puzzle had some
    very ambigous instructions, so I encoded them and found all the solutions.
  - [microblog_api](/projects/microblog_api):
    The schemas for a little microblog project I started.
  - [pi-arm](/projects/pi-arm):
    My solutions to the [baking pi](https://www.cl.cam.ac.uk/projects/raspberrypi/tutorials/os/index.html)
    course from Cambridge university.
  - [project-cloner](/projects/project-cloner):
    A tool for cloning git repositories based on a configuration file.
  - [project-euler](/projects/project-euler):
    My solutions to the [project euler](https://projecteuler.net) problems.
  - [puzzle-planner](/projects/puzzle-planner):
    A private leaderboard for puzzle solving written with ruby on rails.
  - [website3](/projects/website3):
    The current version of my website, written in Angular.
- [configsets](/configsets): Contains configuration for most thinks on my macOs
  devices, including: Brew package management, NVM installation, Git configuration,
  Alacritty configuration, Emacs configuration, LinearMouse configuration,
  NeoVim configuration, SdkMan installation, WezTerm configuration, and ZSH
  configuration, Ghostty configuration & theme.
- [bin](/bin): Contains root scripts for controling Sherman.
  - [clone](/bin/clone): Runs [project cloner](/projects/project-cloner)
    inside my [projects](/projects) folder.
  - [deploy](/bin/deploy): A script ran exclusivly on my miniPC to deploy it.
  - [electron_deploy](/bin/electron_deploy): Ran on a computer with SSH access
    into my miniPC to redeploy all the services on my miniPC (With minimal
    downtime!).
  - [run](/bin/run): Re-applies the [configsets](/configsets) and makes sure
    that any projects managed via [project cloner](/projects/project-cloner/)
    are fetched. This is the main script I run after changing configs or when
    I want to sync my setup between different machines.
- [deploy](/deploy): Contains scripts related to deploying my
  - [electron](/deploy/electron): A little miniPC that runs some of the cto.je
    infastructure.
    - [services/maybe](/deploy/electron/services/maybe): The docker setup
      I run for [maybe](https://github.com/maybe-finance/maybe). I don't
      actually use this anymore in favor of gnucash, but it is a handy project
      that I recommend checking out.
    - [services/microblog_api](/deploy/electron/services/microblog_api):
      A pocketbase server for a microblog I was building, but have not yet
      finished.
    - [services/penpot](/deploy/electron/services/penpot):
      An open source clone to figma that is pretty cool.
    - [services/serverless](/deploy/electron/services/serverless):
      A second pocketbase server that doesn't have a fixed schema, that I use
      for quick experiments.
    - [services/website3](/deploy/electron/services/website3):
      The docker setup for deploying my core website at [cto.je](cto.je)
    - [services/whiteboard](/deploy/electron/services/whiteboard):
      A supporting service as part of my nextcloud setup, allowing me to have
      private cloud persisted excalidraw.
    - [services/wiki](/deploy/electron/services/wiki):
      A mediawiki instance I host for note taking and thinks like that.

## Why?

Sherman started out life as a simple dotfiles repo with a little bit of
automation to move config files into their respective homes. Through quite a
few iterations, it's turned into the mono-repo that it is today.

My initial motivation for using a mono-repo for computing was simply so that I
don't ever loose any code again. Previously, I might start a project or idea,
get something that half-way works, and then just leave it to rot. I never would
bother to create a git repository. As a result, when changing hardware, often
these "unimportant" experiments would get lost to time. By working in a
mono-repo, everything is in version control by default, and easily pushable to
any git server.

Is it a good idea? I think something interesting that has come out of computing
inside a mono-repo is the ease of starting a small experiment and having some
fun. I'm still expanding on the idea, but it feels like I'm following the unix
dream of having little programs that can be composed together.
