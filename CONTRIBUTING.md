# Contributing

## What is in this repository today

There is no build here, and there is no test suite. The tree is documents,
workflow files, and the two shell scripts that two of those workflows run:

    $ git ls-tree -r --name-only HEAD
    .editorconfig
    .gitattributes
    .github/ISSUE_TEMPLATE/broken.md
    .github/ISSUE_TEMPLATE/change.md
    .github/ISSUE_TEMPLATE/config.yml
    .github/pull_request_template.md
    .github/scripts/check-decisions.sh
    .github/scripts/check-pr-hygiene.sh
    .github/workflows/dco.yml
    .github/workflows/decision-records.yml
    .github/workflows/dependency-review.yml
    .github/workflows/pr-hygiene.yml
    .github/workflows/scorecard.yml
    .github/workflows/unicode-guard.yml
    .github/workflows/zizmor.yml
    CODE_OF_CONDUCT.md
    CONTRIBUTING.md
    GOVERNANCE.md
    NOTICE.md
    README.md
    SECURITY.md
    docs/data-boundary.md
    docs/decisions/0002-language-and-toolchain.md
    docs/decisions/0003-upstream-and-adapters.md
    docs/decisions/0004-alert-decoding-and-schema-versions.md
    docs/decisions/0005-what-is-kept-on-disk.md
    docs/decisions/0006-how-a-filter-is-written.md
    docs/decisions/0007-what-a-filter-can-see.md
    docs/decisions/0008-the-sky-is-computed-on-the-host.md
    docs/decisions/0009-the-notification-contract.md
    docs/decisions/0011-process-shape-and-queues.md
    docs/decisions/0012-falling-behind.md
    docs/decisions/0013-configuration-and-secrets.md
    docs/decisions/0014-the-operator-command-surface.md
    docs/decisions/0015-headless-and-unelevated.md
    docs/decisions/README.md
    docs/parity.md
    docs/supply-chain.md
    docs/upstream-terms.md
    docs/what-this-is-not.md

The language and the toolchain are chosen, in
[docs/decisions/0002-language-and-toolchain.md](docs/decisions/0002-language-and-toolchain.md),
and the module that file describes is not in the listing above, because issue
#16 is where it is created. So this document describes what a contribution is
checked against now, and it will grow a build section and a test section when
there is a build and a suite to describe. It does not describe either of them in
advance, because a document that explains how to run a suite that does not exist
is read as evidence that one does.

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

There are two issue forms, `.github/ISSUE_TEMPLATE/broken.md` for a report that
the program did the wrong thing and `.github/ISSUE_TEMPLATE/change.md` for a
change with a scope, its evidence and its done-when. The blank form is off, so
those two and the link to the private security route are what the new issue page
offers. A suspected vulnerability has no form on purpose, and
[SECURITY.md](SECURITY.md) is the whole procedure for it.

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
    .github/workflows/dco.yml:65:              *"+dependabot[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:66:              | "dependabot[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:67:              | *"+github-actions[bot]@users.noreply.github.com" \
    .github/workflows/dco.yml:68:              | "github-actions[bot]@users.noreply.github.com")

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
    .github/workflows/decision-records.yml:1:name: decision-records
    .github/workflows/decision-records.yml:23:    name: Decision records
    .github/workflows/dependency-review.yml:1:name: Dependency review
    .github/workflows/pr-hygiene.yml:1:name: pr-hygiene
    .github/workflows/pr-hygiene.yml:23:    name: Deterministic PR-hygiene checks
    .github/workflows/scorecard.yml:24:name: Scorecard supply-chain security
    .github/workflows/scorecard.yml:50:    name: Scorecard analysis
    .github/workflows/unicode-guard.yml:1:name: unicode-guard
    .github/workflows/unicode-guard.yml:23:    name: Reject Trojan Source Unicode
    .github/workflows/zizmor.yml:21:name: Workflow Security Analysis
    .github/workflows/zizmor.yml:41:    name: Audit workflows (zizmor)

Read that output as the workflow name and the job name, and not yet as the names
a reader sees. Where a job sets `name:`, the check run takes it, which is where
`DCO sign-off`, `Decision records`, `Deterministic PR-hygiene checks`, `Reject
Trojan Source Unicode`, `Audit workflows (zizmor)` and `Scorecard analysis` come
from. Where a job sets none, the check run takes the job id instead, and
`dependency-review` is that case, so the name a protection rule would have to
use is in the file and not in the output above:

    $ git show origin/main:.github/workflows/dependency-review.yml | sed -n '14,19p'
    jobs:
      # No `name:` on this job: the "Protect main" ruleset's required status check
      # matches the literal check-run name, which defaults to the job id
      # ("dependency-review") when no `name:` is set. Overriding it here would
      # rename the check run and silently break the required-status-check gate.
      dependency-review:

The names a reader actually sees are on a pull request head rather than in the
tree, so that is where they are read from. Taken from the head of pull request
#106:

    $ gh api repos/iderex/nachtwache/commits/2bd4f072588a1e56306a4c616fb19a8dbd59c0d5/check-runs --jq '[.check_runs[] | {name, app: .app.slug}]'
    [{"app":"github-advanced-security","name":"zizmor"},{"app":"github-actions","name":"DCO sign-off"},{"app":"github-actions","name":"dependency-review"},{"app":"github-actions","name":"Deterministic PR-hygiene checks"},{"app":"github-actions","name":"Audit workflows (zizmor)"},{"app":"github-actions","name":"Reject Trojan Source Unicode"},{"app":"github-actions","name":"Decision records"},{"app":"github-actions","name":"Reject Trojan Source Unicode"}]

A head is the only place these names are facts, so run the same command against
your own rather than trusting the paste above to still describe the set.

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

Six of the seven workflows produce a run on a pull request. `Scorecard analysis`
does not: it is triggered by a push to the default branch, by a weekly schedule
and by a change to the branch protection, so it audits what has already landed
and never gates a change.

`DCO sign-off` is the sign-off check above.

`Decision records` refuses a file under `docs/decisions/` that departs from the
form the register sets. It runs `.github/scripts/check-decisions.sh`, and what
it refuses, together with the longer list of what it does not, is in
[docs/decisions/README.md](docs/decisions/README.md) rather than here.

`Deterministic PR-hygiene checks` refuses the faults in a pull request that a
machine can decide the same way twice: an empty body, a body naming no issue, a
commit subject a tool wrote by default, a changed or added path outside the
`Scope:` line of every issue the body names, and a committed editor or system
leftover. It reports sign-off as not evaluated, because `DCO sign-off` already
answers that question and a second implementation would be a second answer with
a second carve-out. The rule ids and the bound on each one are in the header of
`.github/scripts/check-pr-hygiene.sh`, which is the authority for them.

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

Four of the six reproduce on an ordinary machine with no account and no network,
and the fourth of those only in part.

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

The decision register check is the same script the workflow runs, and it needs a
shell and awk:

    $ .github/scripts/check-decisions.sh docs/decisions
    check-decisions: examined 14 file(s) in docs/decisions for the four sections and for supersede references

Exit status 0 is the clean result, 1 means it refused something, and 2 means it
could not judge, which is a directory that is not there or one holding no files.
The third is separate from the second so a run that examined nothing cannot be
read as one that examined the register and found it good. Point it at a copy of
the register with a deliberate fault in it to watch it bite.

The hygiene check is the same script too, and this is the part that reproduces
only in part:

    $ .github/scripts/check-pr-hygiene.sh --body body.md --base origin/main --head HEAD

with your pull request body in `body.md`. Two of its five rules compare changed
paths against the `Scope:` line of every issue your body names, and those bodies
come from the tracker rather than from the tree, so without `--issues DIR` the
run reports one of the two as skipped and refuses every added path under the
other. A skipped rule is printed as skipped, which is what keeps a local run
that covered less than the whole set from reading like one that covered it all.

The workflow audit needs `uv` on the machine, which this document does not assume
you have. The pinned version and both invocations are in the workflow file, and
that file rather than this one is the authority for them:

    $ git grep -n 'ZIZMOR_VERSION' origin/main -- .github/workflows/zizmor.yml
    origin/main:.github/workflows/zizmor.yml:48:      ZIZMOR_VERSION: "1.26.1"
    origin/main:.github/workflows/zizmor.yml:67:        run: uvx --no-build "zizmor@${ZIZMOR_VERSION}" --strict-collection --persona=pedantic --min-severity=low --format=sarif . > results.sarif
    origin/main:.github/workflows/zizmor.yml:86:        run: uvx --no-build "zizmor@${ZIZMOR_VERSION}" --strict-collection --persona=pedantic --min-severity=low --format=plain .

The second of those two is the one that fails the build. Run the invocation whole
rather than assembling one from the flags you recognise: a run without
`--persona=pedantic` reports a narrower set than the gate does, and
[docs/supply-chain.md](docs/supply-chain.md) is where that flag is argued.
`dependency-review` runs only on GitHub and has no local form.

## What is asked for rather than enforced

The rules below are requests. Nothing in this repository refuses a change that
breaks one, and each entry names the issue that owes a mechanism, so that a
reader can tell a rule from an explanation of one.

No check is required by the branch protection. The ruleset output above shows
`required_status_checks` as an empty list, so a pull request can be merged while a
check is red, or while a check never ran at all. Issue #36 is where the checks
that exist are required by name once each has produced a run.

Nothing judges what a commit message says. `Deterministic PR-hygiene checks`
refuses a subject a tool wrote by default, and matches the whole subject rather
than a prefix, so it separates `Update README.md` from `Update the pinned linter
version, which had drifted`. Whether the second one states what changed and what
failure the change prevents is the request, and nothing reads it. Issue #35 is
where the mechanical half of it is carried, and its own check says which half
that is.

Nothing judges whether a change is one topic. `change-inside-scope` refuses a
path outside the `Scope:` of every issue the body names, which catches a second
topic that lands in somebody else's paths and does not catch one inside the same
scope. The request is one topic per commit and per pull request, because a commit
carrying two unrelated changes has a message describing one of them. Issue #35
again.

Nothing refuses a pull request body that carries no evidence. The half of it a
machine can decide is refused today: `body-names-an-issue` refuses an empty body
and one that names no issue. Whether what is in the body argues the change is
the request, and the section below is what it asks for.

A decision file missing one of its four sections is refused, and so is one whose
supersede line names a file that is not in the register. What stays a request is
everything else about the form: the number on the title line matching the number
in the file name, two files claiming one number, a file name that does not follow
the pattern, and a supersede recorded on one side only. That list belongs to
`docs/decisions/README.md`, which is where the form is set, and this document
does not restate it, because two statements of one rule drift apart and the one
in the wrong place is the one somebody follows. Issue #1 is where the rest of
that form gains a mechanism.

Nothing runs a build or a suite, because there is neither. Issue #16 adds the
module the language decision describes and issue #18 lays out the test harness.
The milestone after those is where the gate is built, and every check in it is
required by issue #36 rather than by this sentence.

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

The form itself is in
[docs/decisions/README.md](docs/decisions/README.md), which is decision 0001 and
is read by the `Decision records` check like every other file in that directory.
Issue #1 is where the rest of that form gains a mechanism. Issue #2 collects the
decisions that belong to the maintainer rather than to whoever reaches them
first, and work that depends on an unanswered entry there is blocked by it and
says so in its own body.

## Conduct, security and who decides

[CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) is how people are expected to treat each
other here and where a report goes.

[SECURITY.md](SECURITY.md) is how a vulnerability is reported, and it is a
private route rather than an issue. Nothing about a suspected vulnerability
belongs in a public issue or a pull request.

[GOVERNANCE.md](GOVERNANCE.md) says who holds access, how a decision is made and
what happens to this project if the maintainer stops.
