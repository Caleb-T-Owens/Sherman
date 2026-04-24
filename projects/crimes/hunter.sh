#!/bin/zsh

script_dir=${0:A:h}

command_script="$script_dir/commands/$1.sh"

if [[ -e $command_script ]]
then
    echo "found script"
    . $command_script $@[@]:2
else
    echo "Subcommand $1 does not exist."
    exit 1
fi


