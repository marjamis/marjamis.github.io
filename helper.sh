#!/bin/bash -e

COMMAND_LINE_OPTIONS_HELP="Astro Post Helper"
NEW_POST="New Post"

function help {
    echo "Usage: helper -h for help";
    echo "$COMMAND_LINE_OPTIONS_HELP"
}

function error {
    printf "Error: $1\n"

    if [ ! "$3" == "no" ] ; then
        printf "Printing help...\n\n"
        help
    fi

    exit $2
}

function action_new_post {
    date=$(date "+%Y-%m-%d %H:%M:%S %z")
    title=$(gum input --prompt "Title of post? ")
    # Deletes special characters as lychee doesn't like bash expandandable values in URLs
    title=$(echo $title | tr -d '{}()')

    gum style "Select one or more categories that you would like the post to be apart of: "
    selected_categories=$(gum choose --no-limit $(ls -1 ./category | sed 's:.md::g'))
    formatted_categories=$(for i in $selected_categories; do echo "  - $i"; done)

    filename_title=$(gum confirm "Use the title as the filename?" && echo "$title" || gum input --prompt "What should the file name be? ")
    filename="$(echo $date | cut -f1 -d\ )-$(echo $filename_title | sed 's: :\_:g' | tr 'A-Z' 'a-z')"

    printf "\nCreating new post...\n"
    echo "---
title: $title
date: $date
categories:
$formatted_categories
---
" > ./src/content/posts/$filename.md
}

# Start of script execution

# Check if gum is installed and if not exit with details on how to install
if [ ! $(command -v gum) ] ; then
    error "Gum is not installed. Please refer to the documentation: https://github.com/charmbracelet/gum" 1 "no"
fi

LIST="$NEW_POST"

ACTION=$(echo -e "$LIST" | gum choose)

case "$ACTION" in
    "$NEW_POST") action_new_post ;;
    \?) error "E_OPTERROR_UNKNOWNOPTION" 2 ;;
    *) error "E_OPTERROR_NOOPTION" 3 ;;
esac
