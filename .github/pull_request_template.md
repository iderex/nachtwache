[This body is where the change is argued, and it is the only place. A comment
underneath is not the place, including for a refusal: if the body is wrong or
incomplete, the body is edited. Delete each bracketed line as you replace it, so
a leftover bracket is a visible defect rather than a hidden one.]

## What changed, and what failure it prevents

[Both halves. The second is the one that is usually missing, and it is the one a
reader needs to judge whether the first is enough. Where this corrects
something, say what was wrong and how it was found.]

## Which issue, and which decision

[The issue this closes or moves. Where the change depends on a decision file
under `docs/decisions/`, name the file rather than restating what it says.]

## The means

[What this is made of, and why that fits: the language, the format, the tool,
the runtime. Every time, never carried over from habit, because a means that was
right for the last artefact is an assumption about this one. What can be checked
is that the question was asked, and only because the answer is written here.]

## Evidence

[Every claim with the command that produced it and its output, run at the commit
being pushed and against the reference a reader will have. Where a claim cannot
be backed by a command, write it as a claim. Verified, not measured and not
evaluated on this route are three different statements.

Two that belong in almost every body:

    git diff --name-only origin/main...HEAD

so the paths this reaches can be compared against the scope its issue declares,
and the reproduction of any check this change makes or breaks.]

## Proof that the guard bites

[Only where this adds or changes a guard. Delete this heading otherwise rather
than writing "not applicable" under it.

A guard ships with the demonstration that it refuses what it names: what was
broken deliberately, the run that went red, and the run that went green once it
was restored. Spend the effort on the near-miss. A guard proven against an
obvious break proves less than one proven against the one-character mistake
somebody will actually make.]

## What this does not cover

[The residual, stated rather than left out. What was not measured, what was
skipped and why, which conditions of the issue are still open, and which parts
of the change nothing refuses. A negative disclosure here never becomes a
positive assurance in a later edit.]

## Reading

[Whether anybody other than the author has read this, and if not, say so plainly
and let the evidence above stand in place of one.]
