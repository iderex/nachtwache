# Supply chain findings and what was done about them

The workflows are the part of a public repository that runs with the
repository's own credentials, and they are the part an outsider can most easily
influence. Two analysers already look at them here. This file is where what they
say is either fixed or written down with the reason it stands, so that a green
badge is not the whole of the answer.

Every entry carries the identifier the tool reports and the date it was read.
Where a finding is accepted, the reason is written out and the thing that would
retire it is named. Where a finding is not measured on the route available here,
it says so in those words rather than being left out.

## The workflow audit

`Audit workflows (zizmor)` runs on every pull request and fails on any finding of
low severity or worse. It is green, and no finding is being explained away,
because there is none at that threshold:

    No findings to report. Good job! (3 suppressed)

Read from the run on the head of pull request #102 on 2026-08-08, which is the
run of that job rather than the code-scanning upload beside it. Seven workflow
files were audited, which is every file in the directory.

Three findings are suppressed and this document does not say what they are.
Nothing suppresses them inline. The tree carries no ignore comment at all:

    $ git grep -nE 'zizmor: *ignore' -- .github/ ; echo "exit=$?"
    exit=1

Exit status 1 from `git grep` is the clean result. So the three are below the
severity threshold the workflow sets rather than silenced by anybody, and the
threshold is doing exactly what a threshold does. That is not the same as
knowing they are unimportant, and nobody here has read them.

NOT MEASURED ON THIS ROUTE. Enumerating them means running the audit with the
threshold lowered, which needs `uv` on the machine and is not something this
file's evidence was produced with:

    uvx --no-build "zizmor@1.26.1" --strict-collection --min-severity=unknown --format=plain .

The pinned version above is quoted from `.github/workflows/zizmor.yml`, which is
the authority for it. Until somebody runs that and writes the three down here,
the first condition of issue #41, that the audit produces no unexplained
finding, is met at the gating threshold and not below it.

## The scorecard findings

`Scorecard analysis` runs on a push to the default branch, on a weekly schedule
and when the branch protection changes. It never runs on a pull request, so it
audits what has already landed and gates nothing.

Its findings arrive as code-scanning alerts rather than as a failing job, which
is why a green run tells a reader nothing about them:

    $ gh api "repos/iderex/nachtwache/code-scanning/alerts?per_page=100&state=open" --jq '.[] | "\(.rule.id) \(.rule.security_severity_level) \(.most_recent_instance.message.text | split("\n")[0])"'
    CIIBestPracticesID low score is 0: no effort to earn an OpenSSF best practices badge detected
    MaintainedID high score is 0: project was created within the last 90 days. Please review its contents carefully:
    CodeReviewID high score is 0: Found 0/10 approved changesets -- score normalized to 0
    DependencyUpdateToolID high score is 0: no update tool detected:
    FuzzingID medium score is 0: project is not fuzzed:
    LicenseID low score is 0: license file not detected:
    BranchProtectionID high score is 3: branch protection is not maximal on development and all release branches:

Seven open alerts, all raised 2026-08-06, all read 2026-08-08. None is fixed by
this file and each one is placed below.

### Branch-Protection, score 3, accepted in part and owed in part

The check reports five things about `main`: stale review dismissal is disabled,
no approvers are required, codeowners review is not required, last push approval
is disabled, and no status checks are required to merge.

The last of the five is owed and has an owner. `required_status_checks` on the
`gate` ruleset is an empty list, so a pull request merges with a check red or
with a check that never ran, and issue #36 is where the checks that exist are
required by name.

The other four are the same fact seen four ways: one person holds this
repository, which [GOVERNANCE.md](../GOVERNANCE.md) states with the command that
produces it. A required approval on a project with one participant is a rule
that either blocks every change or is satisfied by the author approving their
own, and the second is worse than not having it. These four are accepted for as
long as that stays true, and what retires the acceptance is a second person with
write access rather than a change of mind.

What is not accepted is that the tree carries nothing saying a change was read.
The pull-request body is where that is argued, which
[CONTRIBUTING.md](../CONTRIBUTING.md) asks for and nothing enforces.

### Code-Review, score 0, accepted with the same reason

Zero of the last ten changesets carried an approving review, which is what the
paragraph above describes rather than a separate finding. It is listed
separately because the scorecard scores it separately, and a reader comparing
this file against the alert list should find both.

### Maintained, score 0, accepted and self-retiring

The repository was created inside the last ninety days. That is a fact about
the calendar rather than a defect, it is not fixable by any change to this tree,
and it stops being reported once the repository is old enough. Recorded so that
a reader does not go looking for the fix.

### Dependency-Update-Tool, score 0, accepted until there is a graph

No update tool configuration is present because there is no dependency graph for
one to update:

    $ git ls-tree -r --name-only origin/main -- go.mod go.sum ; echo "exit=$?"
    exit=0

The listing is empty and the exit status is zero, which is git reporting that it
matched nothing rather than that it failed. Configuring an updater now would be
a configuration that updates nothing, and a green score for it would be a green
score for an empty set. Issue #17 pins the graph once issue #16 adds it, and
issue #30 is the gate that keeps it pinned and tidy. This entry is revisited
there rather than here.

### Fuzzing, score 0, accepted until there is something to fuzz

No fuzzer integration is found because there is no decoder and no filter parser
yet. Issue #40 is where the decoder and the filter parser are fuzzed and where
every crash is kept as a regression case. The same order applies: issue #16
first.

### License, score 0, owed to a decision that has not been taken

There is no license file:

    $ git ls-tree --name-only origin/main | grep -icE '^licen[cs]e'
    0

The license is entry 1 of issue #2, which is where the decisions that belong to
the maintainer are collected, and issue #82 is where the decision is applied and
the notices ship with the image. Nothing here chooses it. This is the one
scorecard finding that is neither accepted nor scheduled behind other work: it
waits on an answer.

### CII-Best-Practices, score 0, accepted

The check looks for a badge from a separate programme with its own process and
its own registration. Earning it is not a change to this repository, and the
score measures participation in that programme rather than a property of the
tree. Accepted, with no work scheduled and no owner, which is a position rather
than an oversight.

## The action pins

Every action reference is a commit pin with the tag beside it as a comment, so a
reader can tell what the pin is meant to be:

    $ git grep -hE 'uses: ' origin/main -- .github/workflows/ | wc -l
    13
    $ git grep -hE 'uses: [^ ]+@' origin/main -- .github/workflows/ | grep -cE 'uses: [^ ]+@[0-9a-f]{40} +# '
    13

Thirteen references, thirteen commit pins with a tag comment. Nothing refuses a
tag reference added tomorrow. That rule belongs in the greppable invariants set,
issue #34, and it is the second condition of issue #41.

## The permissions

The shape asked for is that no workflow grants a scope at the top of the file,
where it reaches every job including one added later, and that each job states
the minimum it needs. What the mainline holds is printed rather than described,
because a change to this is in flight and a sentence here would be stale before
it is read:

    $ git grep -n 'permissions:' origin/main -- .github/workflows/
    origin/main:.github/workflows/dco.yml:14:permissions:
    origin/main:.github/workflows/decision-records.yml:12:permissions:
    origin/main:.github/workflows/dependency-review.yml:8:permissions:
    origin/main:.github/workflows/pr-hygiene.yml:13:permissions:
    origin/main:.github/workflows/scorecard.yml:39:permissions:
    origin/main:.github/workflows/scorecard.yml:57:    permissions:
    origin/main:.github/workflows/unicode-guard.yml:12:permissions:
    origin/main:.github/workflows/zizmor.yml:30:permissions: {}
    origin/main:.github/workflows/zizmor.yml:44:    permissions:

A declaration at column zero is a top-level grant and an indented one is on a
job. Run that command rather than reading the output above, which was taken on
2026-08-08. Pull request #101 is the change that moves the top-level grants down,
and this file is not the authority for the result.

## What this document does not cover

Nothing reads it. A finding suppressed inline without an entry here does not fail
the audit, because no check compares the two, and the rule that would is the same
invariants set as the pin rule above.

It covers two analysers and no others. There is no software bill of materials, no
provenance for a release artefact and no scan of a dependency graph, because
there is no artefact and no graph. Those are M8 and M10 rather than gaps in this
triage.

`dependency-review` is green on every change and that is not a measurement. It
compares what a change adds or upgrades against the advisory database, and with
no manifest in the tree it examines nothing. Its green is the absence of a
question rather than an answer to one.

The three findings the audit suppresses are not enumerated here, which is stated
above in the section that would hold them rather than only in this list.
