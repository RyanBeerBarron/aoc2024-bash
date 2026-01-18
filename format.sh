#!/bin/sh

# tabs for indent
# Dont ident case statement in switch
# Put opening braces of function on its own line
format()
{
	shfmt -i 0 --func-next-line -bn "$@"
}

case "$1" in
all)
	shfmt --find . | while read file; do
		format -w "$file"
	done
	;;
*) format ;;
esac
