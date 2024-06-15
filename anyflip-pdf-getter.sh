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
# Requires: ocemypdf
#  Use: brew install ocrmypdf
#
#

URL=$1

TMPDIR=$(mktemp -d)
cd $TMPDIR
echo -n "Downloading jpg's to -> "
pwd

function usage() {
	echo   USAGE:
	echo     $0 https://online.anyflip.com/jbwjh/mals/
	exit;
}

if [[ $URL == "" ]] ; then
  usage ;
fi

require_string='online.anyflip.com'
if [[ $URL == *"$require_string"* ]]; then
  true
else
  echo "Please change the hostname to include --- > $require_string"
  usage ;
fi


for i in {1..10000}; do 
	#################
	# Handle leading 0's for order
	#################
	if [[ "$i" -lt "10" ]]; then
   		j=000$i
	elif [[ "$i" -lt "100" ]]; then
   		j=00$i
	elif [[ "$i" -lt "1000" ]]; then
   		j=0$i
	else
   		j=$i
	fi

	echo curl -s ${URL}files/mobile/$i.jpg -o $j.jpg; 
	curl -s ${URL}files/mobile/$i.jpg -o $j.jpg; 
	file $j.jpg |grep JPEG > /dev/null 
	if [[ "$?" -gt "0" ]]; then
		echo breaking at $j.jpg
		rm $j.jpg
		break
        fi
done

convert *.jpg -auto-orient combined.pdf
ocrmypdf combined.pdf FINAL-ocr.pdf

echo "------------------------"
echo -n "Final OCR'ed pdf file at ->"
echo "$TMPDIR/FINAL-ocr.pdf"
