#!/usr/bin/env bash

# Run the Spell Checker with make-spell.sh

# Name without extensions. The final artifact includes the PDF extension.
BOOKNAME=docbook

# This works around a bug in FOP. fonts.xml says the fonts base
# directory is ../, but FOP can only consume ./.
if [[ ! -d ./fonts/ ]]; then
    echo "Copying fonts..."
    cp -r ../fonts ./
fi

if [[ ! "$(command -v xmllint)" ]]
then
    echo "xmllint is not installed. Skipping validation."
    echo "  You can install libxml2-utils for the program."
fi

if [[ ! "$(command -v xsltproc)" ]]
then
    echo "xsltproc is not installed. Exiting."
    echo "  You must install xsltproc for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# Find docbook.xsl if it is not specified
if [[ -z "$DOCBOOK_XSL" ]]
then
    DOCBOOK_XSL="$(find /usr/share -name 'docbook.xsl' 2>/dev/null | grep '/fo/' | head -n 1)"
fi

if [[ ! -e "$DOCBOOK_XSL" ]]
then
    echo "docbook.xsl was not found. Exiting."
    echo " You must install stylesheets for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

# This magic allows us to build the DocBook on Ubuntu and Fedora.
# Ubuntu and Fedora use different paths to docbook.xsl.
sed "s|!!DOCBOOK_XSL_FILE!!|$DOCBOOK_XSL|g" custom.xsl.in > custom.xsl

if [[ ! "$(command -v fop)" ]]
then
    echo "fop is not installed. Exiting."
    echo " You must install fop for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

if [[ ! "$(command -v gs)" ]]
then
    echo "GhostScript is not installed. Exiting."
    echo " You must install GhostScript for the program."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

if [[ "$(command -v xmllint)" ]]
then

    echo "Validating book..."
    if ! xmllint --xinclude --noout --postvalid book.xml
    then
        echo "Validation failed. Exiting."
        [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
    fi

    echo "Formatting source code..."
    for file in *.xml
    do
        if xmllint --format "$file" --output "$file.format"
        then
            mv "$file.format" "$file"
        fi
    done
fi

echo "Creating formatted object..."
if ! xsltproc --xinclude custom.xsl book.xml > "$BOOKNAME.fo"
then
    echo "Failed to create Formatted Object."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

echo "Creating PDF..."
if ! fop -fo "$BOOKNAME.fo" -c fonts.xml -dpi 75 -pdf "$BOOKNAME-pre.pdf"
then
    echo "Failed to create PDF."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
else
    rm -f "$BOOKNAME.fo" &>/dev/null
fi

echo "Optimizing PDF..."
if ! gs -q -o "$BOOKNAME.pdf" -sDEVICE=pdfwrite -dPDFSETTINGS=/prepress "$BOOKNAME-pre.pdf"
then
    echo "Failed to optimize PDF."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
else
    mv "$BOOKNAME-pre.pdf" "$BOOKNAME.pdf"
fi

if [[ -f custom.xsl ]]; then
    rm -f custom.xsl
fi

echo "Created PDF $BOOKNAME.pdf."
mv "$BOOKNAME.pdf" ../

[[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 0 || return 0
