#!/bin/bash

while true
do
	a=$(shuf -i 0-1 -n 1)
	b=$(shuf -i 0-1 -n 1)
	c=$(shuf -i 0-1 -n 1)
	d=$(shuf -i 0-1 -n 1)

	if [[ $a+$b+$c+$d -eq 3 ]]; then
		echo "# "$a $b $c $d
	else
		echo "Texto de prueba!!"
	fi

	sleep 1
done
