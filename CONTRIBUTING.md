# Contributing

## What is in this repository today

There is no build here, and there is no test suite. The tree is documents and
workflow files:

    $ git ls-tree -r --name-only HEAD
    .github/workflows/dco.yml
    .github/workflows/dependency-review.yml
    .github/workflows/scorecard.yml
    .github/workflows/unicode-guard.yml
    .github/workflows/zizmor.yml
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    GOVERNANCE.md
    NOTICE.md
    README.md
    SECURITY.md
    docs/decisions/0003-upstream-and-adapters.md
    docs/decisions/0005-what-is-kept-on-disk.md
    docs/decisions/0007-what-a-filter-can-see.md
    docs/decisions/0009-the-notification-contract.md
    docs/decisions/0011-process-shape-and-queues.md
    docs/decisions/0013-configuration-and-secrets.md
    docs/what-this-is-not.md

The language and the toolchain are not chosen yet, which is issue #3, and the
first code lands under issue #16 once that decision has a file. So this document
describes what a contribution is checked against now, and it will grow a build
section and a test section when there is a build and a suite to describe. It does
not describe either of them in advance, because a document that explains how to
run a suite that does not exist is read as evidence that one does.

## Every change starts as an issue and lands as a pull request

Direct pushes to `main` are refused. The ruleset on the default branch is the
authority for that, and it is worth reading rather than trusting:

    $ gh api repos/iderex/nachtwache/rulesets --jq '.[] | select(.name == "gate") | .id'
    20520184
    $ gh api repos/iderex/nachtwache/rulesets/20520184 --jq '{enforcement, bypass: .bypass_actors, rules: [.rules[].type], approvals: [.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count][0], required_status_checks: [.rules[] | select(.type == "required_status_checks")]}'
    {"approvals":0,"bypass":[],"enforcement":"active","required_status_checks":[],"rules":["deletion","non_fast_forward","pull_request"]}

Read that output for what it says and for what it does not. A pull request is
required, force-pushes and deletions of the branch are refused, and the bypass
list is empty, so the rule holds for everybody including the maintainer. No
approving review is required, and no status check is required, which is the
subject of the section on what is asked for rather than enforced.

An issue says what is wrong, what the evidence is, and what done means. Where the
evidence is a number, it carries the command that produced it, run against the
reference a reader will have rather than against a working tree. A claim made
from a working checkout and reported as the mainline is the most common way a
true-sounding sentence turns out to be false.

## Sign your work

Every commit needs a Developer Certificate of Origin sign-off. The check refuses
a pull request in which any non-merge commit lacks one, with one carve-out that
the section below states rather than leaves to be found.

    git commit -s

adds the trailer from your configured name and address. The check compares the
trailer to the commit author exactly, so `Signed-off-by: A Name <a@example.com>`
matches a commit authored by `A Name <a@example.com>` and nothing else. If you
have already committed, `git rebase --signoff <base>` adds the trailer to a
range.

The carve-out is for commits that automation writes, which cannot sign for
themselves. Those author addresses are skipped rather than checked:

    $ git grep -n 'bot\]@users.noreply.github.com' -- .github/workflows/dco.yml
    .github/workflows/dco.yml:62:              *"+dependabot[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:63:              | "dependabot[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:64:              | *"+github-actions[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:65:              | "github-actions[bot]@users.noreply.github.com")

Two of those four entries are exact and two carry a leading wildcard. The comment
above them in that file says the list is not a glob and that a contributor
therefore cannot exempt themselves by choosing a bot-shaped author address. That
is narrower than a glob over every `[bot]` address and it is still a glob, and
the check reads the address a commit claims rather than an identity anybody
verified, so a local `user.email` ending in one of the two wildcard forms is
enough to have a commit skipped. Issue #36 carries that measurement with the
proof.

Read the sign-off as something a contributor asserts rather than as something
this repository establishes. That is what the certificate is in the first place,
and it is worth knowing before anybody requires the check by name.

One thing that check's failure message says is not true of this repository. It
points a contributor at a file `DCO` in the root, and there is no such file:

    $ git ls-tree HEAD DCO ; echo "exit=$?"
    exit=0

The output above is empty and the exit status is zero, which is `git ls-tree`
reporting that it matched nothing rather than that it failed. The text a
sign-off asserts is the Developer Certificate of Origin version 1.1, published at
https://developercertificate.org/, and until that text is in the tree this
paragraph is where a contributor finds out where to read it. No open issue
carries that file, which was found by searching the tracker for it and getting
two unrelated results:

    $ gh api "search/issues?q=repo:iderex/nachtwache+DCO+in:body+state:open" --jq '.total_count, (.items[] | "#\(.number) \(.title)")'
    2
    #36 Require the named checks on the protected branch, so a run that never happened is refused
    #37 Reach the gate the sso board runs, and write down every deviation with its reason

## The checks that exist

Derived from the workflow files rather than remembered, because a list in a
document drifts against the thing it describes:

    $ git grep -nE '^name:|^    name:' -- .github/workflows/
    .github/workflows/dco.yml:7:name: DCO
    .github/workflows/dco.yml:24:    name: DCO sign-off
    .github/workflows/dependency-review.yml:1:name: Dependency review
    .github/workflows/scorecard.yml:24:name: Scorecard supply-chain security
    .github/workflows/scorecard.yml:50:    name: Scorecard analysis
    .github/workflows/unicode-guard.yml:1:name: unicode-guard
    .github/workflows/unicode-guard.yml:23:    name: Reject Trojan Source Unicode
    .github/workflows/zizmor.yml:21:name: Workflow Security Analysis
    .github/workflows/zizmor.yml:41:    name: Audit workflows (zizmor)

Read that output as the workflow name and the job name, and not yet as the names
a reader sees. Where a job sets `name:`, the check run takes it, which is where
`DCO sign-off`, `Reject Trojan Source Unicode`, `Audit workflows (zizmor)` and
`Scorecard analysis` come from. Where a job sets none, the check run takes the
job id instead, and `dependency-review` is that case, so the name a protection
rule would have to use is in the file and not in the output above:

    $ git show origin/main:.github/workflows/dependency-review.yml | sed -n '15,20p'
    jobs:
      # No `name:` on this job: the "Protect main" ruleset's required status check
      # matches the literal check-run name, which defaults to the job id
      # ("dependency-review") when no `name:` is set. Overriding it here would
      # rename the check run and silently break the required-status-check gate.
      dependency-review:

The names a reader actually sees are on a pull request head rather than in the
tree, so that is where they are read from. Taken from the head of pull request
#94, which is the most recently merged one:

    $ gh api repos/iderex/nachtwache/commits/54ded4e2bc66911b2d8768eb7a4e843b20bfe02f/check-runs --jq '[.check_runs[] | {name, app: .app.slug}]'
    [{"app":"github-advanced-security","name":"zizmor"},{"app":"github-actions","name":"Audit workflows (zizmor)"},{"app":"github-actions","name":"dependency-review"},{"app":"github-actions","name":"Reject Trojan Source Unicode"},{"app":"github-actions","name":"DCO sign-off"},{"app":"github-actions","name":"Reject Trojan Source Unicode"}]

Run the same command against your own head to see what your change produced.

Two things in that output are in no workflow file. `zizmor` is not a job in
`.github/workflows/zizmor.yml`. It comes from another application, the code
scanning ingest, and is named by the `category:` on the step that uploads the
audit result. That step carries `continue-on-error: true`, so it can report
success while the audit that fails the build has failed, and the name that means
the audit is the job rather than this one. `Reject Trojan Source Unicode`
appears twice, because `.github/workflows/unicode-guard.yml` declares both a
`push` and a `pull_request` trigger over every branch, so a branch that is
pushed and then opened runs the same job twice against one head, and a name that
two runs produce is a name whose verdict depends on which run is read.

Issue #36 is where these names are required by the branch protection, and it
carries both measurements with the working they came from.

Four of the five workflows produce a run on a pull request. `Scorecard analysis`
does not: it is triggered by a push to the default branch, by a weekly schedule
and by a change to the branch protection, so it audits what has already landed
and never gates a change.

`DCO sign-off` is the sign-off check above.

`Reject Trojan Source Unicode` refuses bidirectional and invisible Unicode
control characters in tracked text. Those are the characters that make a file
render to a human differently from how it is read by a machine, so the guard
protects the review rather than the program.

`Audit workflows (zizmor)` is static analysis of these workflow files
themselves, failing on any finding of low severity or worse.

`dependency-review` compares the dependencies a pull request adds or upgrades
against the advisory database and fails on any known vulnerability. It has
nothing to review here yet, because the tree carries no dependency manifest:

    $ git ls-files -- go.mod go.sum package.json 'requirements*.txt' pyproject.toml Cargo.toml pom.xml Gemfile ; echo "exit=$?"
    exit=0

Again the listing is empty and the exit status is zero. A green
`dependency-review` on this repository today therefore means that nothing was
examined, not that something was examined and found clean. That changes when
issue #16 adds the module and issue #17 pins the graph.

## Running the checks here

Two of the four reproduce on an ordinary machine with no account and no network.

The Unicode guard is one command, and the pattern is the one the workflow uses:

    $ git grep -nIP '(*UTF)[\x{202A}-\x{202E}\x{2066}-\x{2069}\x{200E}\x{200F}\x{061C}\x{200B}-\x{200D}\x{2060}]' -- . ; echo "exit=$?"
    exit=1

Exit status 1 from `git grep` is the clean result, meaning nothing matched. Exit
status 0 means a match was found and the check will fail. Any status above 1 is a
broken scanner, and the workflow treats that as a failure rather than as a clean
tree.

The sign-off check reproduces against your own branch:

    $ git log --no-merges --format='%H %an <%ae>%n%(trailers:key=Signed-off-by,valueonly)' origin/main..HEAD

Every commit in that output should be followed by a line identical to the name
and address on the same line.

The workflow audit needs `uv` on the machine, which this document does not assume
you have. The pinned version and both invocations are in the workflow file, and
that file rather than this one is the authority for them:

    $ git grep -n 'ZIZMOR_VERSION' -- .github/workflows/zizmor.yml
    .github/workflows/zizmor.yml:48:      ZIZMOR_VERSION: "1.26.1"
    .github/workflows/zizmor.yml:63:        run: uvx --no-build "zizmor@${ZIZMOR_VERSION}" --strict-collection --min-severity=low --format=sarif . > results.sarif
    .github/workflows/zizmor.yml:82:        run: uvx --no-build "zizmor@${ZIZMOR_VERSION}" --strict-collection --min-severity=low --format=plain .

The second of those two is the one that fails the build. `dependency-review` runs
only on GitHub and has no local form.

## What is asked for rather than enforced

The rules below are requests. Nothing in this repository refuses a change that
breaks one, and each entry names the issue that owes a mechanism, so that a
reader can tell a rule from an explanation of one.

No check is required by the branch protection. The ruleset output above shows
`required_status_checks` as an empty list, so a pull request can be merged while a
check is red, or while a check never ran at all. Issue #36 is where the checks
that exist are required by name once each has produced a run.

Nothing judges a commit message. The request is that a message states what
changed and what failure the change prevents, and where it corrects something,
what was wrong and how it was found. Issue #35 is where a machine reads the
mechanical part of that.

Nothing judges whether a change is one topic. The request is one topic per commit
and per pull request, because a commit carrying two unrelated changes has a
message describing one of them. Issue #35 again.

Nothing refuses a pull request body that carries no evidence. The request is the
section below, and issue #35 covers the deterministic half of it, which is that
the body is not empty and names an issue.

Nothing refuses a decision file that is missing one of its four sections, and
nothing refuses one that names a superseded file which does not exist. Issue #1
owes that check along with `docs/decisions/README.md`, which is where the form
of a decision file is set. This document does not restate the form, because two
statements of one rule drift apart and the one in the wrong place is the one
somebody follows.

Nothing runs a build or a suite, because there is neither. Issue #3 chooses the
language and the toolchain, issue #16 adds the module, and issue #18 lays out the
test harness. The milestone after those is where the gate is built, and every
check in it is required by issue #36 rather than by this sentence.

## What a change carries

The pull request body is where a change is argued, and it is the only place. A
comment underneath a pull request is not the place, including for a refusal: if
the body is wrong or incomplete, the body is edited.

A body says what changed and what failure it prevents, names the issue it closes
or moves, and carries the commands that back every claim it makes, with their
output. Where a claim cannot be backed by a command, it is written as a claim
rather than as a measurement. The words matter here: verified, not measured and
not evaluated on this route are three different statements and are not
interchangeable.

Before pushing, check what the change actually touches:

    git diff --name-only origin/main...HEAD

A change that reaches a path its issue does not name is a change that will
conflict with somebody else, and the cheap fix is to notice before pushing.

## Choosing what a thing is made of

Before an artefact is built, whether the chosen means fits this project is
argued in the issue or in the pull request body. The means is the language, the
format, the tool or the runtime. It is decided every time and never carried over
from habit, because a means that was right for the last artefact is an assumption
about this one.

What the question asks. Can the means carry a claim with the command that
produced it, and a guard with proof that it bites. Is anything outside this
repository forcing a different means, and is that force real and held to its
smallest surface. Does it add a language, a runtime or a dependency the tree does
not already carry, and is that cost paid knowingly.

What can be checked is that the question was asked, and only because the answer
is written down. Whether the answer was right is a judgement, no check makes it,
and the review is where a wrong one is caught.

## Decisions

Every decision that shapes the architecture is a numbered file under
`docs/decisions/`, written before the code that depends on it. A decision that
turns out wrong is not edited; a new file supersedes it by number and names the
file it replaces, and the old file stays in the tree saying what superseded it.

Issue #1 is where the form of those files and their own README land, and issue #2
collects the decisions that belong to the maintainer rather than to whoever
reaches them first. Work that depends on an unanswered entry in #2 is blocked by
it and says so in its own body.

## Conduct, security and who decides

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) is how people are expected to treat each
other here and where a report goes.

[SECURITY.md](SECURITY.md) is how a vulnerability is reported, and it is a
private route rather than an issue. Nothing about a suspected vulnerability
belongs in a public issue or a pull request.

[GOVERNANCE.md](GOVERNANCE.md) says who holds access, how a decision is made and
what happens to this project if the maintainer stops.
