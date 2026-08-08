# Parity with the gate the sso board runs

The target for this repository's gate is the one `iderex/jellyfin-plugin-sso`
already runs. That board's protected branch requires thirteen named checks. This
document says, for each one, whether the control is kept here, kept with a
different implementation, or dropped, and it names the counterpart and where the
counterpart is.

The list is read from the ruleset rather than remembered:

    $ gh api repos/iderex/jellyfin-plugin-sso/rulesets --jq '.[] | select(.name == "Protect main and 5.0") | .id'
    18802863
    $ gh api repos/iderex/jellyfin-plugin-sso/rulesets/18802863 --jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context'
    build
    ABI floor build
    Package (JPRM) / Build package
    Package (JPRM) / Generate SBOM
    CodeQL
    Analyze (csharp)
    DCO sign-off
    Deterministic PR-hygiene checks
    Enforce greppable invariants
    Reject Trojan Source Unicode
    Audit workflows (zizmor)
    prettier
    dependency-review

Read on 2026-08-08. A ruleset moves, so run those two commands before trusting
the thirteen rows below to still be the whole of it. Where they disagree, the
ruleset is right and this file is stale.

## How to read this

Parity means the same coverage, not the same file names. A check copied without
its reason is a check nobody maintains, so every row below keeps a control,
replaces it with a named counterpart, or drops it, and every replacement and
every drop carries a line of reasoning. A line saying only that something does
not apply is not a reason and none is written that way here.

The right-hand column says where the counterpart is today, and it holds two
different kinds of answer. A check-run name means this repository produces a run
under that name now. An issue number means it does not, and that issue is where
it is built. Read the second kind as a plan rather than as coverage.

Nothing in this document is required by the protection on `main`. The ruleset
here carries an empty required-status-check list, so a pull request can merge
with a check red or with a check that never ran:

    $ gh api repos/iderex/nachtwache/rulesets --jq '.[] | select(.name == "gate") | .id'
    20520184
    $ gh api repos/iderex/nachtwache/rulesets/20520184 --jq '[.rules[] | select(.type == "required_status_checks")]'
    []

Issue #36 is where the checks that exist are required by name. Until it lands,
every green run named below is evidence about one change rather than a gate.

The check runs this repository produces today are read from a pull request head
rather than from the tree, because a check-run name is a thing a run creates and
a workflow file only proposes. Taken from the head of pull request #100:

    $ gh api repos/iderex/nachtwache/commits/d53a7e77670bdebd4e2ae8b21e17bdd35883fca0/check-runs --jq '[.check_runs[].name] | sort | unique'
    ["Audit workflows (zizmor)","DCO sign-off","Decision records","Deterministic PR-hygiene checks","Reject Trojan Source Unicode","dependency-review","zizmor"]

Two names in that output belong to no row below. `Decision records` is this
repository's own check over `docs/decisions/`, which the sso board has no
counterpart for. `zizmor` is not a job in `.github/workflows/zizmor.yml`; it is
the code-scanning ingest, named by the category on the step that uploads the
audit result, and the name that means the audit is `Audit workflows (zizmor)`.

## The thirteen

| Required there | Disposition | Counterpart here | Where it is |
| --- | --- | --- | --- |
| `build` | kept, different implementation | `build` | issue #23 |
| `ABI floor build` | kept, different implementation | `oldest supported toolchain` | issue #31 |
| `Package (JPRM) / Build package` | kept, different implementation | `Image (container) / build` | issue #71 |
| `Package (JPRM) / Generate SBOM` | kept, different implementation | `Image (container) / SBOM` | issue #71 |
| `CodeQL` | kept, different implementation | `Analyze (go)` and `Analyze (actions)` | issue #33 |
| `Analyze (csharp)` | kept, different implementation | `Analyze (go)` | issue #33 |
| `DCO sign-off` | kept unchanged | `DCO sign-off` | check run |
| `Deterministic PR-hygiene checks` | kept unchanged | `Deterministic PR-hygiene checks` | check run, issue #35 open |
| `Enforce greppable invariants` | kept, different table | `Enforce greppable invariants` | issue #34 |
| `Reject Trojan Source Unicode` | kept unchanged | `Reject Trojan Source Unicode` | check run |
| `Audit workflows (zizmor)` | kept unchanged | `Audit workflows (zizmor)` | check run |
| `prettier` | dropped | none | this document |
| `dependency-review` | kept unchanged | `dependency-review` | check run |

Each context appears once. The two CodeQL rows are the two halves of one
scanner: the suite-level context and the per-language analysis, which is why
`Analyze (go)` is named in both and the actions analysis only in the first.

## Kept unchanged

`DCO sign-off`, `Reject Trojan Source Unicode`, `Audit workflows (zizmor)` and
`dependency-review` are the four this repository already runs unchanged. What
each of them refuses, and what a green run of it does and does not mean here, is
in `CONTRIBUTING.md` rather than restated in this file.

`Deterministic PR-hygiene checks` is kept unchanged in name and in five of its
six rules. The sign-off rule is reported by that check as not evaluated, with
the reason and with where sign-off is refused instead, and issue #35 is where
that departure is settled rather than left in a run's output.

None of the four is required by the protection here, which is the paragraph
about #36 above rather than a separate gap per row.

## Kept with a different implementation

`build` keeps its name and builds for the two target architectures rather than
for two framework targets, because what ships here is one binary that has to run
on a small board as well as on a desktop.

`ABI floor build` becomes `oldest supported toolchain`. There is no host
application whose interface has to hold, and the risk that check exists against
is the same one either way: a declared minimum that nothing ever executed is a
sentence rather than a minimum.

`CodeQL` and `Analyze (csharp)` become `Analyze (go)` and `Analyze (actions)`.
Different language, same scanner, and the workflow files are analysed for the
reason they are there at all, which is that they run with this repository's own
credentials. The overlap with `Audit workflows (zizmor)` over those same files
is real and is argued in issue #41 rather than resolved by silence here.

`Enforce greppable invariants` keeps its name and gets a different table. The
invariants there hold a login path in place; the ones here are about where a
network call, a disk write, a clock read and a secret may appear.

`Package (JPRM) / Build package` and `Package (JPRM) / Generate SBOM` become
`Image (container) / build` and `Image (container) / SBOM`, because the artefact
an operator installs is an image rather than a plugin package. Both sit in M8
with the rest of the container work.

The gating replay of a committed fuzz seed corpus is kept, over this project's
own decoder and filter parser rather than over an authentication callback. It
produces no context of its own on the board it comes from, so it is named here
rather than in the table, and issue #40 is where it lands.

## Dropped

`prettier`, with its reason. There is no JavaScript, no stylesheet and no web
asset in this tree for a formatter of that kind to keep consistent:

    $ git ls-files '*.js' '*.ts' '*.css' '*.scss' '*.html' ; echo "exit=$?"
    exit=0

The listing is empty and the exit status is zero, which is git reporting that it
matched nothing rather than that it failed. Formatting is covered instead by
`format and generated files are current`, issue #27, which reformats the tree
and fails if anything moved. The day this repository grows a web asset, the drop
stops being justified and this row is where that is noticed.

That is the only drop. Twelve of the thirteen contexts are kept in some form.

## Added, because this project carries risks the original does not

- `tests (race)`, issue #25. This is several concurrent stages passing messages
  through bounded queues, unattended for months, which the original is not.
- `no network in the gating suite`, issue #29. The whole design of the suite
  rests on it, so it is refused rather than requested.
- `coverage floor`, issue #28. A wrong comparison here does not crash, it fails
  to wake somebody up, so how much of the deciding code a test reaches is gated
  rather than reviewed.
- `dependencies are pinned and tidy`, issue #30. This runs unattended on
  somebody's home network, so every dependency is a party running code there and
  it is registered as one.
- `known vulnerable dependencies`, issue #32, as its own gate rather than a step
  inside the build, because `SECURITY.md` makes a promise about it that has to
  be visible as a verdict.
- `tests (ubuntu-latest)`, `tests (macos-latest)` and `tests (windows-latest)`,
  issue #24. The original ships to one runtime. Contributors here work on three
  operating systems, and the headless and unelevated rule in
  `docs/decisions/0015-headless-and-unelevated.md` is only proven on all three.
- `format and generated files are current`, issue #27, which is also where the
  dropped formatter's coverage goes.

## Deferred, each to the milestone that owns it

The image build and the SBOM to issue #71, and the footprint measurement to
issue #77, both in M8. The release workflow to issue #84 and the signing and
provenance to issue #85, both in M10.

The coverage-guided fuzzing run in issue #40 and the mutation run in issue #39
stay scheduled and non-blocking, for the same reason they are scheduled on the
board this table is measured against: a run whose cost is hours and whose result
is a number nobody has a defensible threshold for is a measurement, and turning
a measurement into a gate on the day it is first taken sets the threshold from
one sample.

## Not gating, with the reason

The three integration harnesses. One needs a container runtime, issue #78. One
needs a credential and a live upstream, issue #51. One needs a notification
endpoint somebody owns, issue #69. A required check an outside contributor
cannot run is a check that blocks them, so these run on a schedule and on
request, and their results are reported rather than required. The build tags
that keep them out of the default run are fixed in
`docs/decisions/0015-headless-and-unelevated.md` rather than here.

## What this document does not claim

It does not claim that the counterparts work. Seven of the thirteen rows point
at an open issue and nothing else, five name a check run this repository
produces today, and one is the drop. An issue is a plan rather than a control,
so more than half of this table is intention. What is measured here is that every
context on the other board has a named disposition and that nothing is quietly
missing, not that the coverage exists.

It does not claim that the two gates are equivalent in strength. The board this
is measured against requires its thirteen by name on its protected branch. This
one requires none, which is the ruleset output above and issue #36.

It does not claim that this list is what a gate should be. It is what one
working gate on a neighbouring project is, used as a floor so that a control is
dropped deliberately or not at all.
