#!/usr/bin/env bash

# Run the Spell Checker with make-spell.sh

# Name without extensions. The final artifact includes the PDF extension.
BOOKNAME=power8-crypto

# This works around a bug in FOP. fonts.xml says the fonts base
# directory is ../, but FOP can only consume ./.
if [[ ! -d ./fonts/ ]]; then
    echo "Copying fonts..."
    cp -r ../fonts ./
fi

if [[ ! "$(command -v xmllint 2>/dev/null)" ]]
then
    echo "xmllint is not installed. Skipping validation."
    echo "  You can install libxml2-utils for the program."
fi

if [[ ! "$(command -v xsltproc 2>/dev/null)" ]]
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
    echo "  You must install stylesheets for the program."
    exit 1
fi

# This magic allows us to build the DocBook on Ubuntu and Fedora.
# Ubuntu and Fedora use different paths to docbook.xsl.
sed "s|!!DOCBOOK_XSL_FILE!!|$DOCBOOK_XSL|g" custom.xsl.in > custom.xsl

if [[ ! "$(command -v fop 2>/dev/null)" ]]
then
    echo "fop is not installed. Exiting."
    echo "  You must install fop for the program."
    exit 1
fi

if [[ ! "$(command -v gs 2>/dev/null)" ]]
then
    echo "GhostScript is not installed. Exiting."
    echo "  You must install GhostScript for the program."
    exit 1
fi

# Delete trailing whitespace in sources
if [[ $(uname -s | grep -c -q 'Darwin') -eq 0 ]]
then
    sed -i -E 's/[ '$'\t'']+$//' ./*.xml
else
    sed -i '' -E 's/[ '$'\t'']+$//' ./*.xml
fi

if [[ "$(command -v xmllint 2>/dev/null)" ]]
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
        if xmllint --format "$file" --output "$file.format"
        then
            mv "$file.format" "$file"
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
if ! fop -fo "${BOOKNAME}.fo" -c fonts.xml -dpi 75 -pdf "$BOOKNAME.pdf"
then
    echo "Failed to create PDF."
    exit 1
else
    rm -f "${BOOKNAME}.fo" &>/dev/null
fi

echo "Optimizing PDF..."
# https://stackoverflow.com/q/10450120
if ! gs -q -o "${BOOKNAME}.opt.pdf" -sDEVICE=pdfwrite -dPDFSETTINGS=/screen -dCompatibilityLevel=1.4 "${BOOKNAME}.pdf"
then
    echo "Failed to optimize PDF."
    # Not a hard failure. The unoptimized PDF is available.
fi

# Calculate savings and print the message
old_file_size=$(wc -c "${BOOKNAME}.pdf" | awk '{print $1}')
new_file_size=$(wc -c "${BOOKNAME}.opt.pdf" | awk '{print $1}')
diff_size="$((${old_file_size}-${new_file_size}))"
echo "PDF file size is ${new_file_size}, trimmed ${diff_size} bytes."

if [[ -e "${BOOKNAME}.opt.pdf" ]]; then
    mv "${BOOKNAME}.opt.pdf" "${BOOKNAME}.pdf"
fi

if [[ "$(command -v qpdf 2>/dev/null)" ]]
then
    echo "Performing qa check..."
    if qpdf --check "${BOOKNAME}.pdf" 1>/dev/null
    then
        echo "Book is well formed."
    else
        echo "Book is damaged or corrupt."
    fi
else
    echo "Skipping qa check..."
    echo "  You can install qpdf for the program."
fi

if [[ -f custom.xsl ]]; then
    rm -f custom.xsl
fi

# Move book to top level directory
echo "Created PDF ${BOOKNAME}.pdf."
mv "${BOOKNAME}.pdf" ../

exit 0
