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
low severity or worse. It runs under the `pedantic` persona, and the reason it
has to is the finding this section carries. Seven workflow files are audited,
which is every file in the directory.

Nothing suppresses a finding inline. The tree carries no ignore comment at all:

    $ git grep -nE 'zizmor: *ignore' -- .github/ ; echo "exit=$?"
    exit=1

Exit status 1 from `git grep` is the clean result, so nothing here is silenced by
hand.

### What the persona was hiding

Before `--persona=pedantic` was on the two invocations in
`.github/workflows/zizmor.yml`, the job passed no persona, so it took the default
one and reported clean while holding three findings back:

    $ zizmor --strict-collection --min-severity=low --format=plain .
    No findings to report. Good job! (3 suppressed)

Read on 2026-08-09 against `18b5a5b8ec23e5728f0166ad65d56c461578a0bd`, which is
the mainline the change branched from.

Severity was not what excluded them. Two of the three are `low`, which is the
floor the job names rather than below it, and lowering the floor surfaces
nothing, because the value that would lower it is deprecated and has no effect.
Read on 2026-08-08:

    $ zizmor --strict-collection --min-severity=unknown --format=plain .
     WARN zizmor: `unknown` is a deprecated minimum severity that has no effect
     WARN zizmor: future versions of zizmor will reject this value
    No findings to report. Good job! (3 suppressed)

Widening the persona while holding the floor exactly where the job holds it left
the two low findings standing and dropped only the informational one. Read on
2026-08-09 against the same commit:

    $ zizmor --strict-collection --persona=pedantic --min-severity=low --format=plain .
    3 findings (1 ignored): 0 informational, 2 low, 0 medium, 0 high

- `anonymous-definition`, informational, `.github/workflows/dependency-review.yml`
  line 19, on the job `dependency-review`, which carries no `name:`.
- `undocumented-permissions`, low, `.github/workflows/pr-hygiene.yml` line 31, on
  `issues: read`.
- `undocumented-permissions`, low, `.github/workflows/scorecard.yml` lines 63 and
  65, on `security-events: write` and `id-token: write`.

Line numbers move when a workflow does, so run the command rather than trusting
the three above.

### The two that are repaired

Both `undocumented-permissions` findings asked for a comment the flagged line
itself carries. Each of those lines had its reason written on the line above
instead, which reads the same way to a person and not at all to the audit. The
comments are now on the lines, in the form `zizmor.yml` was already using for its
own block, and the audit at the persona and the floor the job runs has nothing
left to report:

    $ zizmor --strict-collection --persona=pedantic --min-severity=low --format=plain .
    No findings to report. Good job! (1 ignored)

Read on 2026-08-09 against the change that made it true. The one still ignored is
the informational finding below.

### The one that stays

`anonymous-definition` is not repaired and must not be. A required status check
matches the literal check-run name, which defaults to the job id where no `name:`
is set, so naming that job renames the check run. The comment directly above the
job already says this, and issue #36 is where the name is required on the
protected branch. Satisfying the audit here would break the gate the audit is run
to protect, which makes this a finding that stays for as long as the requirement
does.

It is informational, which is below the floor the job fails on, so it does not
red the gate and it is the finding the count above calls ignored:

    $ zizmor --strict-collection --persona=pedantic --format=plain .
    1 finding: 1 informational, 0 low, 0 medium, 0 high

### What the gate refuses now

An undocumented permission added to any workflow in this directory fails
`Audit workflows (zizmor)` rather than being dropped before the floor is applied.
That was shown by deleting one of the two comments and running the command the
gate runs, on 2026-08-09:

    $ zizmor --strict-collection --persona=pedantic --min-severity=low --format=plain .
    help[undocumented-permissions]: permissions without explanatory comments
      --> .github/workflows/scorecard.yml:63:7
       |
    63 |       id-token: write
       |       ^^^^^^^^^^^^^^^ needs an explanatory comment
       |
       = note: audit confidence → High
       = help: audit documentation → https://docs.zizmor.sh/audits/#undocumented-permissions

    2 findings (1 ignored): 0 informational, 1 low, 0 medium, 0 high
    $ echo "exit=$?"
    exit=12

The comment was restored and the command returned to the clean output above. The
near-miss is the state this change replaced: the same explanation one line higher
is not a comment the flagged line carries, and it is what the three-finding run
was reporting.

What this does not reach is a finding somebody silences by hand. An ignore
comment added to a workflow would suppress an audit again, and the first entry of
issue #41 asks for a check that refuses one without an entry in this file.
Nothing compares the two, and #34 is where that rule lands.

### The route these runs came from

These runs came from an installation of `zizmor` 1.26.1 beside the tree rather
than from the workflow, which installs the same version through `uv`. The version
is quoted from `.github/workflows/zizmor.yml`, which is the authority for it.
What ties the two routes together is that the local run reproduced the gating
run's output before the persona was widened, count included, which is the first
command in this section.

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

No changeset in the window the scorecard samples carried an approving review,
which is what the paragraph above describes rather than a separate finding. How
many changesets that window holds moves as changes land, so the listing above
carries the number for the day it was read and this sentence does not restate
it. It is listed separately because the scorecard scores it separately, and a
reader comparing this file against the alert list should find both.

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
because a sentence here drifts against the directory it describes:

    $ git grep -n 'permissions:' origin/main -- .github/workflows/
    origin/main:.github/workflows/dco.yml:15:permissions: {}
    origin/main:.github/workflows/dco.yml:28:    permissions:
    origin/main:.github/workflows/decision-records.yml:13:permissions: {}
    origin/main:.github/workflows/decision-records.yml:28:    permissions:
    origin/main:.github/workflows/dependency-review.yml:8:permissions: {}
    origin/main:.github/workflows/dependency-review.yml:25:    permissions:
    origin/main:.github/workflows/pr-hygiene.yml:13:permissions: {}
    origin/main:.github/workflows/pr-hygiene.yml:29:    permissions:
    origin/main:.github/workflows/scorecard.yml:39:permissions:
    origin/main:.github/workflows/scorecard.yml:57:    permissions:
    origin/main:.github/workflows/unicode-guard.yml:13:permissions: {}
    origin/main:.github/workflows/unicode-guard.yml:28:    permissions:
    origin/main:.github/workflows/zizmor.yml:30:permissions: {}
    origin/main:.github/workflows/zizmor.yml:44:    permissions:

A declaration at column zero is a top-level grant and an indented one is on a
job. Run that command rather than reading the output above, which was taken on
2026-08-09. Seven files, seven job blocks, and six of the seven grant nothing at
the top. `scorecard.yml` is the one that keeps `contents: read` there, and the
comment above it in that file gives the reason, which is that a read-only
top-level declaration is itself one of the things the scorecard reads.

Every write scope in the directory is on a job, and there are three of them:

    $ git grep -nE '^ +[a-z-]+: write' origin/main -- .github/workflows/
    origin/main:.github/workflows/scorecard.yml:62:      security-events: write # upload the SARIF result to the code-scanning dashboard
    origin/main:.github/workflows/scorecard.yml:63:      id-token: write # publish results to the OpenSSF API (badge and public score) via OIDC
    origin/main:.github/workflows/zizmor.yml:45:      security-events: write # upload the SARIF into the code-scanning tab

So no job here can write to the repository, its contents, its pull requests or
its packages. That is a measurement of the directory on the day it was taken and
not a property anything holds in place. A top-level grant added tomorrow is
refused by nothing, which is the same gap as the pin rule above and lands in the
same place.

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
