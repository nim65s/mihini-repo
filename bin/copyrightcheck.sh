#!/bin/bash
for F in $(find . -type f); do
	if [ "$(basename $F)" == "README.CQ" ] ; then
		true # pass, this file isn't supposed to have a copyright notice
	elif grep -qP '^ +\* +Sierra Wireless - initial' $F; then
		echo "    Missing author in $F"
	elif grep -q "Copyright" $F; then
		echo "        Author found in $F"
	else
		echo "No copyright in $F"
	fi
done

