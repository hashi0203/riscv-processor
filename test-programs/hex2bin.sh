#!/bin/sh
while read line; do
	printf '32'\''b'
	echo "obase=2; ibase=16; ${line}" | bc | printf "%32s" $(cat) | sed -e 's/ /0/g'
	echo ','
done < $1
