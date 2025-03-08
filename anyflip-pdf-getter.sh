#!/bin/bash
# 
# Script to download pdf's from anyflip.com
#  -- downloads all jpg images
#  -- compiles them (the jpg images) together in order with imagemagick into a pdf file
#  -- then OCR's the pdf and creates a final pdf with OCR text overload (so you can search the pdf)
#
# Requires:  ImageMagik for the convert command
#  Use: brew install imagemagick
#
# Requires: ocrmypdf
#  Use: brew install ocrmypdf
#
#

URL=$1

function usage() {
	echo   USAGE:
	echo     $0 https://anyflip.com/jbwjh/mals/
	exit;
}

if [[ $URL == "" ]] ; then
  usage ;
fi

require_string='anyflip.com'
if [[ $URL == *"$require_string"* ]]; then
  true
else
  echo "Please change the hostname to include --- > $require_string"
  usage ;
fi

/Users/jackal/bin/anyflip/bin/anyflip-downloader  -title combined-pdf $URL
ocrmypdf combined-pdf.pdf /tmp/FINAL-ocr.pdf


echo "------------------------"
echo -n "Final OCR'ed pdf file at ->"
echo "/tmp/FINAL-ocr.pdf"

#clean up
rm combined-pdf.pdf
