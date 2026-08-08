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
low severity or worse. It is green, and its own output says three findings were
suppressed:

    No findings to report. Good job! (3 suppressed)

Read from the run on the head of pull request #102 on 2026-08-08, which is the
run of that job rather than the code-scanning upload beside it. Seven workflow
files were audited, which is every file in the directory.

Nothing suppresses those three inline. The tree carries no ignore comment at all:

    $ git grep -nE 'zizmor: *ignore' -- .github/ ; echo "exit=$?"
    exit=1

Exit status 1 from `git grep` is the clean result, so nothing here is silenced by
hand.

### What the three are

Read on 2026-08-08 against the workflow directory as it stands at
`a47cce933977518fa0a0ab0c9f473f6e46b6af57`, with the persona widened and nothing
else changed. Line numbers move when a workflow does, so run the command rather
than trusting the three below:

    $ zizmor --strict-collection --persona=pedantic --format=plain .
    3 findings: 1 informational, 2 low, 0 medium, 0 high

- `anonymous-definition`, informational, `.github/workflows/dependency-review.yml`
  line 20. The job carries no `name:`.
- `undocumented-permissions`, low, `.github/workflows/pr-hygiene.yml` line 15, on
  `issues: read`.
- `undocumented-permissions`, low, `.github/workflows/scorecard.yml` lines 63 and
  65, on `security-events: write` and `id-token: write`.

The first is not repaired and must not be. A required status check matches the
literal check-run name, which defaults to the job id where no `name:` is set, so
naming that job renames the check run. The comment directly above the job already
says this, and issue #36 is where the name is required on the protected branch.
Satisfying the audit here would break the gate the audit is run to protect, which
makes this a finding that stays for as long as the requirement does.

The other two are accepted rather than repaired, and the accepted thing is
narrow. Each flagged line has its reason written in the line above it, and what
the audit asks for is a comment the flagged line itself carries. What is being
accepted is the position that a permission documented one line up is documented,
not the position that a permission needs no explanation. The state of those
permission blocks on the mainline is printed under `## The permissions` below
rather than described here.

### Why the gate does not see them, which is not the severity

Recorded here before was that the three sit below the severity floor the workflow
sets. That is wrong, and two of the three are the counter-example: they are
`low`, which is that floor rather than below it. Lowering the floor surfaces
nothing, and the audit says why:

    $ zizmor --strict-collection --min-severity=unknown --format=plain .
     WARN zizmor: `unknown` is a deprecated minimum severity that has no effect
     WARN zizmor: future versions of zizmor will reject this value
    No findings to report. Good job! (3 suppressed)

What excludes them is the persona. The workflow passes none, so the run takes the
default one, and all three audits above belong to `pedantic`:

    $ git grep -n -- '--persona' origin/main -- .github/workflows/zizmor.yml ; echo "exit=$?"
    exit=1

Widening the persona while holding the floor exactly where the gate holds it
leaves the two low findings standing and drops only the informational one:

    $ zizmor --strict-collection --persona=pedantic --min-severity=low --format=plain .
    3 findings (1 ignored): 0 informational, 2 low, 0 medium, 0 high

So the green tick beside the audit is a persona choice and not a statement that
the tree is clean at the severity the job names. Nothing refuses a fourth: an
undocumented permission added tomorrow is suppressed the same way and this file
does not learn about it. Gating on `pedantic` is what would change that, and it
reds today on the two findings above until each flagged line carries its own
comment, so it is a change to the workflow rather than to this file.

### The route these three came from

These runs came from an installation of `zizmor` 1.26.1 beside the tree rather
than from the workflow, which installs the same version through `uv`. The version
is quoted from `.github/workflows/zizmor.yml`, which is the authority for it.
What ties the two routes together is that the local run reproduces the gating
run's output before the persona is widened, count included:

    $ zizmor --strict-collection --min-severity=low --format=plain .
    No findings to report. Good job! (3 suppressed)

Nothing compares the two routes, so a divergence between them shows up only when
somebody runs both.

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

The three findings the audit suppresses are enumerated above, and the run that
enumerated them was made beside the tree rather than by the workflow. Nothing
compares those two routes, and nothing refuses a fourth suppressed finding
arriving without an entry here.
