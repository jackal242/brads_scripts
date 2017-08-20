#!/bin/bash
cleanup() {
    rm -f $TMPFILE
    exit 0
}
trap cleanup  EXIT INT QUIT TERM


if [ "$#" -ge 1 ]; then
    SQLFILE="$1"
else
    if tty -s; then
    # SQLFILE=$(ls -t ~/.mozilla/firefox/*/cookies.sqlite | head -1)
    # I changed it - brad
    SQLFILE=$(find ~ -type f -name cookies.sqlite -exec wc -l {} \+ | sort -rn |grep -v total| head -1 |egrep -o "/.*")
    else
    SQLFILE="-"     # Will use 'cat' below to read stdin
    fi
fi

if [ "$SQLFILE" != "-" -a ! -r "$SQLFILE" ]; then
    echo "Error. File $SQLFILE is not readable." >&2
    exit 1
fi

echo "COOKIE FILE FOUND = $SQLFILE"

# We have to copy cookies.sqlite, because FireFox has a lock on it
TMPFILE=`mktemp /tmp/cookies.sqlite.XXXXXXXXXX`
echo "TEMPFILE=$TMPFILE"
ls $TMPFILE
cat "$SQLFILE" >> $TMPFILE
ls $TMPFILE

# This is the format of the sqlite database:
# CREATE TABLE moz_cookies (id INTEGER PRIMARY KEY, name TEXT, value TEXT, host TEXT, path TEXT,expiry INTEGER, lastAccessed INTEGER, isSecure INTEGER, isHttpOnly INTEGER);

echo "# Netscape HTTP Cookie File"
sqlite3 -separator $'\t' $TMPFILE <<- EOF
	.mode tabs
	.header off
	select host,
	case substr(host,1,1)='.' when 0 then 'FALSE' else 'TRUE' end,
	path,
	case isSecure when 0 then 'FALSE' else 'TRUE' end,
	expiry,
	name,
	value
	from moz_cookies;
EOF

cleanup
