#!/bin/sh
while read line; do
	printf '32'\''b'
	echo "obase=2; ibase=16; ${line}" | bc | awk '{printf "%32s", $0}' | sed -e 's/ /0/g'
	echo ','
done < $1