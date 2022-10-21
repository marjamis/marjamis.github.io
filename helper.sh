#!/bin/bash -e

COMMAND_LINE_OPTIONS_HELP="Jekyll Post Helper"

function help {
    echo "Usage: helper n -h for help";
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
" > ./_posts/$filename.md
}

function action_new_category {
    category_name=$(gum input --prompt "New category name? ")
    printf "$category_name\n"

    printf "Creating category for $category_name...\n"
    echo "---
layout: category_index
category-name: $category_name
permalink: \"/category/$category_name\"
---

" > ./category/$category_name.md
}

# Start of script execution

# Check if gum is installed and if not exit with details on how to install
if [ ! $(command -v gum) ] ; then
    error "Gum is not installed. Please refer to the documentation: https://github.com/charmbracelet/gum" 1 "no"
fi

LIST="New Post
New Category"

ACTION=$(echo -e "$LIST" | gum choose)

case "$ACTION" in
    "New Post") action_new_post ;;
    "New Category") action_new_category ;;
    \?) error "E_OPTERROR_UNKNOWNOPTION" 2 ;;
    *) error "E_OPTERROR_NOOPTION" 3 ;;
esac