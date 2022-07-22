#!/usr/bin/env bash

# Run the Spell Checker with make-spell.sh

# Name without extensions. The final artifact includes the PDF extension.
BOOKNAME=docbook-install

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
    exit 1
fi

# Find docbook.xsl if it is not specified
if [[ -z "${DOCBOOK_XSL}" ]]
then
    DOCBOOK_XSL="$(find /usr/share -name 'docbook.xsl' 2>/dev/null | grep -E '/fo/docbook.xsl$' | head -n 1)"
fi

if [[ ! -e "${DOCBOOK_XSL}" ]]
then
    echo "docbook.xsl was not found. Exiting."
    echo " You must install stylesheets for the program."
    exit 1
fi

# This magic allows us to build the DocBook on Ubuntu and Fedora.
# Ubuntu and Fedora use different paths to docbook.xsl.
sed "s|!!DOCBOOK_XSL_FILE!!|${DOCBOOK_XSL}|g" custom.xsl.in > custom.xsl

if [[ ! "$(command -v fop)" ]]
then
    echo "fop is not installed. Exiting."
    echo " You must install fop for the program."
    exit 1
fi

if [[ ! "$(command -v gs)" ]]
then
    echo "GhostScript is not installed. Exiting."
    echo " You must install GhostScript for the program."
    exit 1
fi

if [[ "$(command -v xmllint)" ]]
then

    echo "Validating book..."
    if ! xmllint --xinclude --noout --postvalid book.xml
    then
        echo "Validation failed. Exiting."
        exit 1
    fi

    echo "Formatting source code..."
    for file in *.xml
    do
        if xmllint --format "${file}" --output "${file}.format"
        then
            mv "${file}.format" "${file}"
        fi
    done
fi

echo "Creating formatted object..."
if ! xsltproc --xinclude custom.xsl book.xml > "${BOOKNAME}.fo"
then
    echo "Failed to create Formatted Object."
    exit 1
fi

echo "Creating PDF..."
if ! fop -fo "${BOOKNAME}.fo" -c fonts.xml -dpi 75 -pdf "${BOOKNAME}.pdf"
then
    echo "Failed to create PDF."
    exit 1
else
    rm -f "${BOOKNAME}.fo" &>/dev/null
fi

echo "Optimizing PDF..."
# https://stackoverflow.com/q/10450120
if ! gs -q -o "${BOOKNAME}.pdf.opt" -sDEVICE=pdfwrite -dPDFSETTINGS=/screen -dCompatibilityLevel=1.4 "${BOOKNAME}.pdf"
then
    echo "Failed to optimize PDF."
    # Not a hard failure. The unoptimized PDF is available.
else
    mv "${BOOKNAME}.pdf.opt" "${BOOKNAME}.pdf"
fi

if [[ -f custom.xsl ]]; then
    rm -f custom.xsl
fi

echo "Created PDF ${BOOKNAME}.pdf."
mv "${BOOKNAME}.pdf" ../

exit 0
