#!/bin/sh
# Refuse a decision record that departs from the form docs/decisions/README.md
# sets out. Two refusals and no others:
#
#   1. a file in the register that does not carry each of the four required
#      sections exactly once,
#   2. a "Supersedes:" or "Superseded by:" line that names a file which is not
#      in the register.
#
# What it does not refuse is written in README.md under the heading that says
# so, and is not restated here.
#
# Usage: check-decisions.sh [directory]        (default: docs/decisions)
#
# Exit status: 0 the register is in form, 1 it is refused, 2 the check could not
# judge. The third is separate from the second on purpose, so a run that never
# examined anything cannot be read as one that examined the register and found
# it good.
#
# It takes a directory rather than assuming one, so that it can be run against a
# copy of the register with a deliberate fault in it. That is how the guard is
# shown to bite without the fault ever being in the tree.
#
# One awk pass does the reading, and the shell only resolves the references it
# reports. Process startup dominates the runtime of the obvious shape, which is
# a grep per file per section.

set -eu

dir=${1:-docs/decisions}

if [ ! -d "$dir" ]; then
	printf 'check-decisions: no such directory: %s\n' "$dir" >&2
	exit 2
fi

set -- "$dir"/*.md
if [ ! -f "$1" ]; then
	printf 'check-decisions: no decision files in %s\n' "$dir" >&2
	exit 2
fi

# The fields are separated by "|", which appears in no section heading and in no
# file name here. awk reports; it decides nothing that needs the filesystem.
report=$(awk '
	FNR == 1 { order[++files] = FILENAME }
	{
		line = $0
		sub(/\r$/, "", line)		# a CRLF checkout is judged on its text
		if (line == "## What was decided")		a[FILENAME]++
		else if (line == "## Why")			b[FILENAME]++
		else if (line == "## Alternatives rejected, and why")	c[FILENAME]++
		else if (line == "## What it costs")		d[FILENAME]++
		else if (line ~ /^(Supersedes|Superseded by):/) {
			ref = line
			sub(/^[^:]*:[ \t]*/, "", ref)
			if (ref == "")
				print "emptyref|" FILENAME
			else
				print "ref|" FILENAME "|" ref
		}
	}
	END {
		for (i = 1; i <= files; i++) {
			f = order[i]
			print "file|" f
			if (a[f] != 1) print "section|" f "|## What was decided|" a[f] + 0
			if (b[f] != 1) print "section|" f "|## Why|" b[f] + 0
			if (c[f] != 1) print "section|" f "|## Alternatives rejected, and why|" c[f] + 0
			if (d[f] != 1) print "section|" f "|## What it costs|" d[f] + 0
		}
	}
' "$@")

status=0
count=0

oldifs=$IFS
IFS='
'
for line in $report; do
	kind=${line%%|*}
	rest=${line#*|}
	case $kind in
	file)
		count=$((count + 1))
		;;
	section)
		file=${rest%%|*}
		tail=${rest#*|}
		section=${tail%|*}
		found=${tail##*|}
		printf 'check-decisions: %s: expected one line reading "%s", found %s\n' \
			"$file" "$section" "$found" >&2
		status=1
		;;
	emptyref)
		printf 'check-decisions: %s: supersede line names no file\n' "$rest" >&2
		status=1
		;;
	ref)
		file=${rest%%|*}
		target=${rest#*|}
		if [ ! -f "$dir/$target" ]; then
			printf 'check-decisions: %s: names "%s", which is not in %s\n' \
				"$file" "$target" "$dir" >&2
			status=1
		fi
		;;
	esac
done
IFS=$oldifs

printf 'check-decisions: examined %s file(s) in %s for the four sections and for supersede references\n' \
	"$count" "$dir"

if [ "$status" -ne 0 ]; then
	printf 'check-decisions: refused\n' >&2
fi

exit "$status"
