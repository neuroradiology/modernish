#! /usr/bin/env modernish
use loop/with

with x=2000000 to 1 step -2; do
	:
done
echo $x