#!/bin/bash

while true
do
	a=$(shuf -i 0-1 -n 1)
	b=$(shuf -i 0-1 -n 1)
	c=$(shuf -i 0-1 -n 1)
	d=$(shuf -i 0-1 -n 1)

	echo $a $b $c $d
	sleep 2
done
