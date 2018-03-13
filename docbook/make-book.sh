#!/usr/bin/env bash

if [[ ! $(command -v xmllint) ]]
then
    echo "xmllint is not installed. Skipping validation."
    echo "  You can install libxml2-util for the program."
fi 

if [[ ! $(command -v xsltproc) ]]
then
    echo "xsltproc is not installed. Exiting."
    echo "  You must install xsltproc for the program."
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
    echo "Foramtting source code..."
    for file in *.xml
    do
	if xmllint --format "$file" --output "$file.format"
        then
            mv "$file.format" "$file"
        fi
    done

    echo "Validating book..."
    xmllint --xinclude --noout --postvalid book.xml 
fi

XSL=/usr/share/xml/docbook/stylesheet/docbook-xsl/fo/docbook.xsl
if [[ ! -e "$XSL" ]]
then
    echo "Stylesheet is missing. Exiting."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

echo "Translating document..."
if ! xsltproc --xinclude "$XSL" book.xml > docbook.fo
then
    echo "Failed to create PDF."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
fi

echo "Creating PDF..."
if ! fop -fo docbook.fo -pdf docbook.pdf
then
    echo "Failed to create PDF."
    [[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 1 || return 1
else
    rm docbook.fo &>/dev/null
fi

echo "Created PDF docbook.pdf."

[[ "$0" = "${BASH_SOURCE[0]}" ]] && exit 0 || return 0

