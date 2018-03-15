#!/usr/bin/env bash

# Name without extensions. The final artifact include PDF.
BOOKNAME=docbook

if [[ ! $(command -v xmllint) ]]
then
    echo "xmllint is not installed. Skipping validation."
    echo "  You can install libxml2-util for the program."
fi 

if [[ ! $(command -v xsltproc) ]]
then
    echo "xsltproc is not installed. Exiting."
    echo "  You must install libxml2-util for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi 

if [[ ! $(command -v fop) ]]
then
    echo "fop is not installed. Exiting."
    echo " You must install fop for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi 

if [[ $(command -v xmllint) ]]
then

    echo "Validating book..."
    if ! xmllint --xinclude --noout --postvalid book.xml
    then
        echo "Validation failed. Exiting."
        [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
    fi

    echo "Foramtting source code..."
    for file in *.xml
    do
	if xmllint --format "$file" --output "$file.format"
        then
            mv "$file.format" "$file"
        fi
    done
fi

XSL=/usr/share/xml/docbook/stylesheet/docbook-xsl/fo/docbook.xsl
if [[ ! -e "$XSL" ]]
then
    echo "Stylesheet is missing. Exiting."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

echo "Translating document..."
if ! xsltproc --xinclude "$XSL" book.xml > "$BOOKNAME.fo"
then
    echo "Failed to create Formatted Object."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

echo "Creating PDF..."
if ! fop -fo "$BOOKNAME.fo" -pdf "$BOOKNAME.pdf"
then
    echo "Failed to create PDF."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
else
    rm "$BOOKNAME.fo" &>/dev/null
fi

echo "Created PDF $BOOKNAME.pdf."
cp "$BOOKNAME.pdf" ../

[[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 0 || return 0

