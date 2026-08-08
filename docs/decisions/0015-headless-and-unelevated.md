# 0015. Headless and unelevated, as a birth requirement

## What was decided

Every test in the default suite runs with no display attached, with no elevated
privileges, without binding a listening socket, without reaching the network,
and without writing outside a temporary directory it created. The default suite
is what `go test ./...` runs with no build tag given, and the five constraints
hold on Linux, on macOS and on Windows alike.

They are stated here, before the suite exists, because a constraint written
after the fact is a caveat, and a caveat is refused by nothing.

### The five constraints

- No display. No test requires a display variable to be set, opens a window, or
  drives anything that needs a session a person is logged into. A run under an
  account with no desktop is an ordinary run.
- No elevated privileges. No test needs administrator or root, and none invokes
  a privilege helper, a firewall or network configuration tool, a service or
  scheduled task registration, an installer, or a certificate trust operation.
  Anything that would raise a consent dialog on the machine running the suite is
  out, whether or not the account could answer it.
- No listening socket. No test binds a port, on any interface, including
  loopback, and no test starts something that binds one on its behalf.
- No network. No test makes an outbound connection. Every byte the pipeline
  reads in the default suite comes from a recording in the tree or from an
  in-process source.
- No writing outside a temporary directory it created. A test writes under the
  directory the test runner gave it and nowhere else. Not the working tree, not
  the user profile, not a fixed path under the system temporary directory, and
  not a state directory at the path a running program would use.

### Why the listener is called out separately

The listener constraint is the one that looks like a detail and is not. Binding
a port is the constraint most often broken by accident, because the ordinary way
to test a consumer is to stand something up on a port and talk to it, and it is
the one whose failure is worst on one of the three platforms.

On Windows a bind can produce a firewall consent dialog. A dialog is not a test
failure. It is a question asked of a person, and on a machine running unattended
there is nobody to answer it, so the run stops and waits instead of going red.
That is worse than a failure, because a failure is reported and a wait is not.
Where somebody is at the machine, the dialog needs an administrator, and the
answer is recorded against the binary that asked, so it settles nothing for the
next build directory.

That behaviour is the reason recorded in issue #19 and it is a claim rather than
a measurement. Nothing in this tree has produced it, and this file does not
assert it as measured. The constraint would be worth having if the dialog never
appeared at all, for a reason that is measurable: a port is shared state on the
machine, so a suite that binds one cannot run twice at the same time, which is
what the three-operating-system matrix in issue #24 and any parallel run do.

So the consumer is tested against recorded messages and against an in-process
source that misbehaves on demand, never against a broker on a port. Issue #20
records the traffic once, issue #52 builds the in-process source, and the
decoder in issue #47 and the filter engine in M6 are the consumers held to this.

### No environmental skips

Nothing in the default suite is skipped for an environmental reason. A test that
cannot meet a constraint on one platform is rewritten until it can, or it moves
out of the default suite under the rule below. It does not stay in and report
itself as skipped.

A skip is how a gap becomes invisible. A suite reporting two hundred passes and
eleven quiet skips is one nobody audits, and the skips accumulate on the
platform that is least often looked at, which is the platform where they matter.

This is narrower than a ban on skipping. A test that skips because the input it
is parameterised over does not apply to the case in hand is stating something
about the data. A test that skips because of what the machine is or is not is
stating that the suite does not cover this here, and that is the one refused.

### Where an exempt path goes

A path that genuinely cannot meet the five constraints goes to
`test/integration/`, behind a build tag named for what it needs rather than for
being optional. There are three, and each is named for its requirement:

| Tag | What it needs | Where it is built |
| --- | --- | --- |
| `requires_container_runtime` | a container runtime on the machine | issue #78 |
| `requires_live_upstream` | a credential and a live upstream | issue #51 |
| `requires_notification_endpoint` | an endpoint the operator owns | issue #69 |

Each carries a short document beside it saying what to provide, roughly what it
costs to run, and what it proves that the default suite cannot. The third of
those is the one that keeps a harness honest, because a harness whose value is
not written down is one nobody can decide to delete.

None of the three gates a change, and the parity table in issue #37 says so with
the reason rather than leaving the absence to be noticed. A check an outside
contributor cannot run is a check that blocks them, and a gate only the
maintainer can turn green is a gate that stops being read.

### What refuses a violation

Two things, and they cover different halves.

`internal/testsupport/environment_test.go` asserts properties of the run itself:
that no display variable was required, that no test in the default run
registered a skip whose reason is environmental, and that the process opened no
listening socket while the run was in progress. That catches a violation that
actually happened.

The greppable invariant set in issue #34 refuses the spellings, outside
`test/integration/`: a socket bind, a listener type, a privilege or firewall
helper, a container client, and an outbound call that does not go through the
transport layer. That catches a violation before it runs, including one on a
path no test reached.

The network constraint is also a gate of its own, issue #29, which is where the
refusal is required by name on every change. This file fixes the property and
issue #29 requires it. The two are one rule in two places rather than two rules.

None of this exists. There is no module, no suite and no check in this tree on
the day this file lands, so nothing refuses any of the five constraints yet.
Issue #16 adds the module, issue #18 lays out the harness, and issue #19 is
where the assertions and the pattern set are built and where the pattern set is
shown to bite.

## Why

A suite that needs a display, a raised privilege, a firewall answer or a
container runtime is a suite that runs on one machine. Everywhere else it is
skipped, and a skipped check is worse than an absent one, because it reports in
the same column as a check that ran.

The constraints are decided before the first test rather than after the
hundredth because of what happens in between. Each is cheap to hold from the
start and expensive to recover afterwards. By the time a suite has a broker on a
port, the tests that use it are the tests that describe the behaviour, and
taking the port away means rewriting the part of the suite somebody trusts most.
Written now, the in-process source is simply how the consumer is tested and
there is nothing to undo.

The unattended case is what shapes the elevation constraint, rather than
politeness toward whoever is at the keyboard. This program is a daemon and its
suite will be run by a machine, in a container, on three operating systems, with
nobody watching. All four of the things that constraint names fail the same way
there: they do not fail, they ask. A run that asks is a run that hangs, and a
hang is reported by nothing until somebody notices that a result never arrived.

Determinism is the other half of the argument, and it is the half that survives
even if every machine were attended. Two green runs should mean the same thing.
A suite that reaches the network is green when a third party is up and red when
it is down, and neither verdict is about the change. A suite that writes outside
its temporary directory is green the first time and red the second, or worse,
green the second time for a reason that came from the first. A suite that binds
a port is green alone and red beside itself.

The recordings pay for all of this at once. Once the bytes are in a file, the
question of what the pipeline does with them has an answer that does not depend
on the network, the hour or the upstream. That is the same argument
[0014](0014-the-operator-command-surface.md) makes for `record` and `replay`
being verbs an operator has.

## Alternatives rejected, and why

- Allowing a loopback listener, because it is local. It is local and it is still
  a bind, and both costs above are real: the dialog on one of the three
  platforms, and the shared port on all three. The in-process source has to
  exist anyway for the misbehaviour cases in issue #52, so the exception would
  buy nothing and cost the constraint.
- Writing the constraints into the contributor guide instead of deciding them.
  That is the version of this that exists in most projects and it is a list of
  caveats. A caveat is refused by nothing, it is read once, and the first test
  that breaks it is merged by somebody who never read it.
- Skipping the tests that cannot meet a constraint on a platform. It is the
  smallest change at the moment it is needed, and it removes the thing the
  three-platform matrix in issue #24 was built for. The skip lands on the
  platform where the difference is, which is the platform it was hiding.
- Build tags named `integration`, `slow` or `optional`. A tag that sounds
  optional is treated as optional and never runs. A tag that says what it needs
  tells a reader why it did not run and what to provide, and it keeps the three
  harnesses independent of each other.
- One tag for all three harnesses. It forces somebody with a container runtime
  and no upstream credential to run neither, so the harness they could have run
  stays unrun, for a reason that has nothing to do with it.
- Testing the consumer against a broker in a container in the default run. It
  needs a container runtime, which is one of the four things this decision keeps
  off the default path, and it turns a contributor's first suite run into an
  infrastructure problem rather than a check on their change.
- Detecting the environment and adapting, for example binding a port only where
  one is already permitted. It makes what the suite covered a property of the
  machine that ran it. Two green runs then mean different things and neither
  says which, which is the failure the whole decision is against.
- Making the constraints a property of the gate rather than of the suite. A rule
  only the gate holds is a rule a contributor meets after pushing, and the
  constraint most worth having locally is the one about consent dialogs, because
  that one is about the machine somebody is sitting at.

## What it costs

The pattern set is a floor rather than a guarantee. It refuses the spellings
somebody has written down, so a bind reached through a helper package, a
dependency that dials on its own, or a listener obtained from a library the set
does not name walks through it. The assertions in
`internal/testsupport/environment_test.go` are what stand behind the cases the
patterns miss, and they catch only what a run actually did. Neither half is
complete, and the two are kept because they fail in different directions.

The in-process source is a model of an upstream rather than an upstream. It
proves the pipeline against the behaviour somebody wrote into the model,
including the misbehaviour, and it cannot prove the pipeline against the
behaviour nobody thought of. That gap is what issue #51 exists for, and issue
#51 does not gate, so the gap is accepted knowingly rather than closed.

Three integration harnesses that most people never run are three things that
rot. They will be written once, pass once, and then sit while the code under
them moves, and the first person to run one will meet a failure that is about
the harness rather than about the program. The short document beside each is the
whole of the mitigation, and it is a small one.

Refusing environmental skips means a genuine platform difference is handled
rather than noted. The temporary directory behaves differently across the three,
path handling differs, and a filter file that carries a path is read on all of
them. Each of those is more work than a skip, and it is the work the constraint
buys rather than an unintended consequence of it.

The five constraints also bound what the default suite can ever say. It cannot
say that this program talks to a real broker correctly, that a notification
arrives at a real endpoint, or that the image runs. Those are the three
harnesses, none of them gates, so the honest statement about a green default run
is that the pipeline is correct against recorded bytes and not that the program
works end to end. That sentence belongs in the parity table in issue #37, next
to the deviation it explains.

Nothing above is refused today. This file is a position a reader can hold the
suite to from the moment the suite exists, and until issue #19 lands its
assertions and its pattern set, it is a position and not a mechanism.
