# 0001. How a decision is recorded here

## What was decided

One file per decision, `docs/decisions/NNNN-short-name.md`, written before the
code that depends on it.

The number is four digits, zero padded. It is the highest number already in this
directory plus one, it is never reused and it is never renumbered, so a
reference to a decision made a year ago still resolves. The number in the file
name is the number on the title line, which reads `# NNNN. What the decision is
about`.

This file is decision 0001. It is called `README.md` rather than
`0001-how-a-decision-is-recorded.md` because the form of a register belongs
where somebody opening the directory will see it without being told to look. In
every other respect it is an ordinary decision file, including the four
sections, and the check below reads it exactly like the rest.

### The four sections

Every file in this directory carries these four headings, at level two, spelled
exactly like this, each exactly once:

    ## What was decided
    ## Why
    ## Alternatives rejected, and why
    ## What it costs

Nothing else is required, and headings at level three inside a section are free.

What was decided is the present-tense statement of the thing, written so that
somebody can act on it without reading the rest of the file.

Why is the argument. It is what a reader disagrees with, so it carries the
reasoning rather than the conclusion.

Alternatives rejected, and why is the part that makes a decision arguable a year
later. An alternative listed without the reason it lost is not a rejected
alternative, it is a decoration.

What it costs is not optional politeness. A decision with no stated cost is one
where the alternatives were never really examined, and it is the section a later
reader needs most, because the cost is what they are living with and it is the
thing least likely to be written down anywhere else.

### Superseding

A decision that turns out to be wrong is not edited. A new file supersedes it,
by number, and says so on a line at column zero:

    Supersedes: 0004-alert-decoding-and-schema-versions.md

The superseded file stays in the tree, and gains one line, also at column zero:

    Superseded by: 0021-alert-decoding-second-attempt.md

Adding that one line is the only edit a landed decision takes. Everything else
about it stays as it was written, including the parts that turned out to be
wrong, because the reason a decision was wrong is worth as much later as the
reason its replacement is right.

Both lines name a file in this directory by its file name and nothing else, so
that resolving one is a lookup rather than a search.

### What the check refuses

`.github/scripts/check-decisions.sh` reads this directory, and the workflow
`decision-records` runs it on every pull request. It can be run on any machine
with a shell and awk:

    .github/scripts/check-decisions.sh

It exits 0 when the register is in form, 1 when it refuses something, and 2 when
it could not judge, which is a directory that is not there or one holding no
files at all. The third status is separate from the second so that a run which
examined nothing cannot be read as a run that examined the register and found it
good.

It refuses four things. A file that does not carry one of the four sections. A
file that carries one of them twice. A supersede line naming a file that is not
in this directory. A supersede line naming nothing at all.

It does not refuse the rest, and the rest is larger:

- whether the number on the title line matches the number in the file name,
- two files that claim the same number,
- a file whose name does not follow `NNNN-short-name.md` at all,
- a superseded file that never gained its `Superseded by:` line, so a supersede
  recorded on one side only passes,
- whether anything at all is written under a heading, so four headings and no
  prose passes,
- whether the prose under a heading is about what the heading says,
- whether a decision that was made has a file here in the first place.

The last two cannot be read out of the tree by anything, and the ones above them
could be and are not. Nothing requires this check on the protected branch
either: the ruleset carries no required status check, which is issue #36, so a
pull request can be merged while this check is red or while it never ran.

This document does not list the decisions. The directory is the list, and a list
here would drift against it.

The four section names above exist in two places, this file and the operator
that refuses a departure from them, and the second was written by hand from the
first. What the check actually applies is printed by the code rather than
restated here:

    git grep -n 'line == "## ' -- .github/scripts/check-decisions.sh

## Why

A decision that lives in a commit message, a pull request thread or somebody's
memory cannot be argued with a year later. The first sign that it was never
really made is a change that quietly assumes the opposite, and by then the
argument has to be had again from nothing, usually by somebody who was not there
the first time.

Numbering rather than naming is what makes a reference stable. A file renamed
for clarity breaks every link to it, and a decision is referred to from issues,
from commit messages and from other decisions, none of which this repository can
rewrite.

Superseding rather than editing is the same property applied to time. An edited
decision file reads as though it was always right, which is the single most
misleading artefact a register can produce: the reader cannot tell that the
project changed its mind, and cannot see what it changed its mind about. Keeping
the old file with a line pointing forward costs one file and preserves the whole
history of the argument.

The four sections are a floor rather than a template. They are the smallest set
that makes a decision arguable: what, why, what else was considered, and what it
costs. Anything less and a reader has to guess at one of the four; anything more
and the sections become boxes to fill in, which produces a paragraph under a
heading because the heading was there.

A machine reads the form because a form that only people check is a form that
holds until somebody is in a hurry. What a machine can read here is narrow, and
the list of what it cannot is above so that the check is not mistaken for a
guarantee about the content.

## Alternatives rejected, and why

- One file holding every decision, appended to. It is easier to read end to end
  and it makes every change to any decision a change to one file, which is a
  conflict every time two efforts touch the register, and it removes the stable
  reference that a numbered file gives.
- Dated file names, `2026-08-08-short-name.md`. The date answers a question
  nobody asks and the number answers the one they do, which is which decision
  came first. Git already holds the date, and a decision written on one day and
  landed on another has two of them.
- Editing a decision in place and keeping the history in git. The history is
  there and nobody reads it. A reader opening the file sees a document that
  claims to have always said this, and the fact that it once said something else
  is a `git log` away, which is a distance nobody travels while reading.
- More sections, for example status, deciders, consequences and context as
  separate headings. Every additional heading is one more box that gets filled
  because it is there. Status in particular is a field that goes stale silently,
  and the supersede line above carries the same information in the one place a
  reader is already looking.
- Structured metadata in a front matter block instead of prose headings. It is
  easier to parse and it moves the decision into fields, which is exactly the
  shape that produces a register nobody reads. The check is not hard enough to
  justify it.
- Putting the form in `CONTRIBUTING.md` instead of here. That document already
  says why not: two statements of one rule drift apart, and the one in the wrong
  place is the one somebody follows. It points here rather than restating.

## What it costs

A numbered file for every decision means the register grows and nothing is ever
removed from it, so a reader eventually meets superseded files that are still
present and still confident in their own text. The forward line is the whole of
the mitigation and it is only on the file somebody happened to open.

Never renumbering means the numbers go out of order relative to when things were
decided, because a number is taken when the file is written and the files land
in whatever order they land in. The numbers are identifiers, not a sequence, and
this file is the only place that says so.

Superseding costs a whole file for what is sometimes a small correction, and the
temptation to fix the sentence instead will be strongest exactly when the
correction is small.

The check reads the shape and not the content, which is stated above at some
length because a green check on a register of empty sections is the failure mode
this form is most exposed to. A reader is still what stands behind every decision
in this directory.
