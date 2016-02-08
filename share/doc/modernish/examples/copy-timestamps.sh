#! /usr/bin/env modernish
use safe
use sys/dirutils

# this script searches a tree in directory PATH_SRC for files with
# extension EXT_SRC and copies their timestamps to the already-existing
# corresponding files with extension EXT_DEST in an identical tree in
# directory EXT_DEST. (customize extensions above.)
#
# i have used this, after converting a bunch of Micro$oft Office documents
# to OpenOffice.org format (with the latter's built-in batch converter), to
# restore the original timestamps in the newly converted copies.
#
# if 'getfacl' and 'setfacl' are available, POSIX ACLs are transferred as well.
#
# by martijn@inlv.demon.nl 12 March 2005 - public domain
# 22 Dec 2015: over a decade later: conversion to modernish, just for the hell of it
# 06,07 Feb 2016: tweaks; inclusion in share/doc/modernish/examples

harden touch
harden sed
if command -v getfacl && command -v setfacl; then
	harden getfacl
	harden setfacl
	unexport POSIXLY_CORRECT # for getfacl/setfacl to work properly
	do_facl=1
else
	unset do_facl
fi >/dev/null

# comment out next line if no debug messages wanted
debug=1

# defaults:
ext_src=.doc
ext_dest=.odt
path_src=.
path_dest=.

showusage() {
	echo "Usage: $ME [ --ext-src=<ext> ] [ --ext-dest=<ext> ] [ --path-src=<path> ] [ --path-dest=<path> ]"
	echo "       $ME [ -es <ext> ] [ -ed <ext> ] [ -ps <path> ] [ -pd <path> ]"
}

# eval params:
while gt $# 0
do
	case $1 in
		( --ext-src=*	) ext_src=${1#--ext-src=}	;;
		( --ext-dest=*	) ext_dest=${1#--ext-dest=}	;;
		( --path-src=*	) path_src=${1#--path-src=}	;;
		( --path-dest=*	) path_dest=${1#--path-dest=}	;;
		( -es		) shift; ext_src=$1		;;
		( -ed		) shift; ext_dest=$1		;;
		( -ps		) shift; path_src=$1		;;
		( -pd		) shift; path_dest=$1		;;
		( *		) exit -u 2			;;
	esac
	shift
done	

# report params if debug mode on:
isset debug && for n in ext_src ext_dest path_src path_dest
do
	eval "echo $n = \$$n"
done

# the meat of the matter:

# Here is a typical use of "traverse" as a replacement for "find". It works
# by defining a handler function. The 'traverse' function passes the path of
# every file to the function as $1, so the handler function handles one file
# at a time. Unlike the usual methods with 'find', this is completely safe
# even for weird filenames containing whitespace, newlines or other control
# characters (provided you either 'use safe' or quote your variables).
total=0 processed=0
handler_copy_timestamp() {
	inc total
	if isreg $1 && endswith $1 $ext_src
	then
		dest=$path_dest${1#"$path_src"}
		dest=${dest%"$ext_src"}$ext_dest
		if isreg $dest; then
			isset debug && echo "Setting timestamp of '$dest' to those of '$1'"
			touch -m -r $1 $dest
			if isset do_facl; then
				isset debug && echo "Setting ACLs of '$dest' to those of '$1'"
				getfacl -- $1 \
				| sed "s?^# file: ${path_src#/}\(.*\)${ext_src}\$?# file: ${path_dest#/}\1${ext_dest}?" \
				| setfacl --restore=/dev/stdin
			fi
			inc processed
		else
			echo "$ME: '$dest' doesn\'t exist. Cannot set timestamp." 1>&2
		fi
	
	fi
}
traverse $path_src handler_copy_timestamp

print "$processed of $total files processed"