#!/usr/bin/env bash

if [[ ! "$(command -v hunspell)" ]]
then
    echo "hunspell is not installed. Exiting."
    echo "  You can install hunspell for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

IFS="" find "$PWD" -name '*.xml' -print | while read -r file
do
    echo "***************************************"
    echo "Spell checking $(basename $file)"

    grep -o '<para>.*</para>' "$file" | \
        hunspell -d en_US -p book.dict -l -X | grep -v 0x | sort | uniq -i
    grep -o '<title>.*</title>' "$file" | \
        hunspell -d en_US -p book.dict -l -X | grep -v 0x | sort | uniq -i
done

[[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 0 || return 0
