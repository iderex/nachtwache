#!/bin/sh
# Refuse the deterministic hygiene faults in a pull request. Nothing here judges
# meaning: every rule is a comparison a machine makes the same way twice, and
# whether a message says something useful is a review question this check does
# not pretend to answer.
#
# The rules, by the id each one reports under:
#
#   body-names-an-issue        the body is not empty and names at least one issue
#   commit-message-not-generated
#                              no commit subject is one a tool wrote by default
#   change-inside-scope        every changed path is under the Scope: an issue
#                              named in the body declares
#   added-file-inside-scope    the same for added paths, and it fails closed
#                              where change-inside-scope fails open
#   no-local-artefacts         no editor, operating system or local tool leftover
#                              is committed
#
# Sign-off is deliberately not among them. `DCO sign-off` already refuses a
# commit whose `Signed-off-by:` trailer does not match its author, and it
# carries a carve-out for the identities that cannot sign for themselves. A
# second implementation here would be a second answer to one question with a
# second carve-out, so this check reports sign-off as not evaluated and names
# where it is. That is a departure from what issue #35 asks for and it is stated
# in the run's own output rather than left to be noticed.
#
# What it does not refuse, which is larger than what it does:
#
#   - whether the body argues the change, or whether the issue it names is the
#     issue the change belongs to,
#   - a body that names many issues, which widens the scope to the union of all
#     of their Scope: lines. The rule is a floor: it catches a change that
#     escapes every scope anybody named, not one that escapes its own,
#   - a Scope: entry containing a space, which the split below cannot represent,
#   - a commit subject that says nothing but was typed rather than generated,
#   - a leftover from a local tool that is neither a dot-path at the root nor
#     one of the named editor and operating system files.
#
# Usage:
#   check-pr-hygiene.sh --body FILE --base REF --head REF [--issues DIR]
#
# --issues is a directory holding one file per issue, named for the issue
# number and containing that issue's body. It is how the two scope rules get
# the `Scope:` lines without this script needing an account or a network, which
# is also what makes them testable against a fixture.
#
# Exit status: 0 nothing refused, 1 refused, 2 the check could not judge. The
# third is separate from the second so a run that examined nothing cannot be
# read as a run that examined everything and found it clean. A rule that could
# not be evaluated is reported as skipped with its reason, and a skipped rule
# never contributes to a status of 0 being read as coverage.

set -eu

me=check-pr-hygiene

usage() {
	printf '%s: usage: %s --body FILE --base REF --head REF [--issues DIR]\n' \
		"$me" "$me" >&2
}

body=
base=
head=
issues=

while [ $# -gt 0 ]; do
	case $1 in
	--body) [ $# -ge 2 ] || { usage; exit 2; }; body=$2; shift 2 ;;
	--base) [ $# -ge 2 ] || { usage; exit 2; }; base=$2; shift 2 ;;
	--head) [ $# -ge 2 ] || { usage; exit 2; }; head=$2; shift 2 ;;
	--issues) [ $# -ge 2 ] || { usage; exit 2; }; issues=$2; shift 2 ;;
	*) usage; exit 2 ;;
	esac
done

if [ -z "$body" ] || [ -z "$base" ] || [ -z "$head" ]; then
	usage
	exit 2
fi

if [ ! -f "$body" ]; then
	printf '%s: no such body file: %s\n' "$me" "$body" >&2
	exit 2
fi

# Each walk is guarded rather than left to set -e, because a failed command
# substitution inside a word list does not trip it, and the result would be a
# rule that examined an empty set and passed.
if ! changed=$(git diff --name-only "$base...$head"); then
	printf '%s: could not diff %s...%s\n' "$me" "$base" "$head" >&2
	exit 2
fi
if ! added=$(git diff --name-only --diff-filter=A "$base...$head"); then
	printf '%s: could not diff %s...%s for added paths\n' "$me" "$base" "$head" >&2
	exit 2
fi
if ! commits=$(git rev-list --no-merges "$base".."$head"); then
	printf '%s: could not walk %s..%s\n' "$me" "$base" "$head" >&2
	exit 2
fi

status=0
register=

refuse() {
	printf '%s: %s: %s\n' "$me" "$1" "$2" >&2
	status=1
}

evaluated() {
	register="$register$1 evaluated
"
}

skipped() {
	register="$register$1 skipped: $2
"
}

# ---------------------------------------------------------------- rule 1

numbers=$(grep -oE '#[0-9]+' "$body" | tr -d '#' | sort -un || true)

if [ -z "$(tr -d '[:space:]' < "$body")" ]; then
	refuse body-names-an-issue "the body is empty"
elif [ -z "$numbers" ]; then
	refuse body-names-an-issue "the body names no issue"
fi
evaluated body-names-an-issue

# ---------------------------------------------------------------- rule 2

# Subjects a tool writes when nobody chose one. The whole subject is matched,
# never a prefix, so "Update the pinned linter version, which had drifted" is
# untouched and "Update README.md" is not. That is the near-miss this rule is
# aimed at: the two differ by whether anything was said.
for sha in $commits; do
	subject=$(git show -s --format='%s' "$sha")
	generated=no
	case $subject in
	"" | "Initial commit" | "Add files via upload" | "WIP" | "wip")
		generated=yes
		;;
	"fixup! "* | "squash! "* | "amend! "*)
		generated=yes
		;;
	esac
	if [ "$generated" = no ] && printf '%s' "$subject" |
		grep -Eq '^(Update|Create|Delete) [^ ]+$|^Rename [^ ]+ to [^ ]+$'; then
		generated=yes
	fi
	if [ "$generated" = yes ]; then
		refuse commit-message-not-generated \
			"$(printf '%s carries a subject a tool writes by default: "%s"' \
				"$sha" "$subject")"
	fi
done
evaluated commit-message-not-generated

# ---------------------------------------------------------------- the scopes

# The Scope: line is split on whitespace, which is what the issues in this
# repository are written with. A scope entry containing a space is therefore not
# representable, and this is the bound rather than a defect that was missed: the
# same shape refused valid work elsewhere by word-splitting silently, so it is
# said out loud here instead.
scope=
missing=
if [ -n "$issues" ] && [ -d "$issues" ]; then
	for n in $numbers; do
		if [ -f "$issues/$n" ]; then
			line=$(grep -m1 '^Scope:' "$issues/$n" || true)
			if [ -n "$line" ]; then
				scope="$scope $(printf '%s' "$line" | sed 's/^Scope:[ 	]*//')"
			fi
		else
			missing="$missing $n"
		fi
	done
fi

inside_scope() {
	for entry in $scope; do
		case $entry in
		*/)
			case $1 in "$entry"*) return 0 ;; esac
			;;
		*)
			if [ "$1" = "$entry" ]; then
				return 0
			fi
			case $1 in "$entry"/*) return 0 ;; esac
			;;
		esac
	done
	return 1
}

# ---------------------------------------------------------------- rule 3

if [ -z "$issues" ] || [ ! -d "$issues" ]; then
	skipped change-inside-scope "no issue bodies were supplied to read a Scope: line from"
elif [ -z "$scope" ]; then
	skipped change-inside-scope "no issue named in the body declares a Scope: line"
else
	for path in $changed; do
		inside_scope "$path" || refuse change-inside-scope \
			"$(printf '%s is outside every declared scope:%s' "$path" "$scope")"
	done
	evaluated change-inside-scope
fi

# ---------------------------------------------------------------- rule 4

# This is where the two scope rules part. change-inside-scope fails open when
# there is no scope to compare against, because a change that only edits files
# is visible in a diff a reader is already looking at. An added file is not: it
# is the way a change most often escapes the issue it belongs to, and a new path
# nobody declared is exactly the collision a scope line exists to prevent. So
# this rule refuses rather than skipping.
if [ -z "$added" ]; then
	evaluated added-file-inside-scope
elif [ -z "$scope" ]; then
	for path in $added; do
		refuse added-file-inside-scope \
			"$path is added and no issue named in the body declares a scope for it"
	done
	evaluated added-file-inside-scope
else
	for path in $added; do
		inside_scope "$path" || refuse added-file-inside-scope \
			"$(printf '%s is added outside every declared scope:%s' "$path" "$scope")"
	done
	evaluated added-file-inside-scope
fi

# ---------------------------------------------------------------- rule 5

# The dot-path half names no tool on purpose. A list of tool directories is a
# list that goes stale the day somebody uses a different one, and writing those
# names into a tracked file is its own defect. So a dot-path at the root is
# refused unless the tree already carries one with that name, or it is ordinary
# repository configuration. What is new and hidden is what gets refused, which
# is the property, and the cost is that a genuinely new dot-directory needs a
# line here.
is_artefact() {
	case ${1##*/} in
	.DS_Store | Thumbs.db | desktop.ini) return 0 ;;
	*~ | *.swp | *.swo | *.orig | *.rej | *.bak) return 0 ;;
	esac
	case $1 in
	.*)
		first=${1%%/*}
		case $first in
		.github | .gitignore | .gitattributes | .gitmodules | .editorconfig | .mailmap)
			return 1
			;;
		esac
		git cat-file -e "$base:$first" 2>/dev/null || return 0
		;;
	esac
	return 1
}

for path in $changed; do
	if is_artefact "$path"; then
		refuse no-local-artefacts "$path is an editor, system or local tool leftover"
	fi
done
evaluated no-local-artefacts

# ---------------------------------------------------------------- the register

printf '%s: examined %s commit(s) and %s changed path(s) between %s and %s\n' \
	"$me" "$(printf '%s' "$commits" | grep -c . || true)" \
	"$(printf '%s' "$changed" | grep -c . || true)" "$base" "$head"

printf '%s' "$register" | while IFS= read -r line; do
	if [ -n "$line" ]; then
		printf '%s: %s\n' "$me" "$line"
	fi
done

printf '%s: commits-signed-off not evaluated here: one implementation, in the DCO sign-off check\n' "$me"

if [ -n "$missing" ]; then
	printf '%s: no body was supplied for issue(s):%s, so their scopes were not read\n' \
		"$me" "$missing"
fi

if [ "$status" -ne 0 ]; then
	printf '%s: refused\n' "$me" >&2
fi

exit "$status"
