#! /usr/bin/env modernish

let x=0
while lt x 1000000; do
	x=$((x+1))
done
echo $x