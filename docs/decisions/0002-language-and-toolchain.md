# 0002. The implementation language and the toolchain

## What was decided

Go, with the toolchain that ships with it.

The module graph is pinned by `go.mod` and `go.sum`. `gofmt` decides
formatting, so there is no formatting discussion and no formatting
configuration. `golangci-lint` carries the lint rules, pinned by version rather
than taken from whatever is newest. The suite is the standard test runner with
no assertion framework, because a failing comparison printed by the standard
runner is already readable and an assertion library is a dependency in the path
that decides whether a change is correct.

The version floor is the older of the two Go releases upstream currently
supports, written into `go.mod` as an exact version. Moving it is a deliberate
edit with the date and the reason, never a side effect of somebody's local
toolchain.

Which two those are is a fact about the Go project on the day it is read, and
the release feed is the authority for it rather than this file:

    $ curl -s 'https://go.dev/dl/?mode=json' | grep '^  "version"'
      "version": "go1.26.5",
      "version": "go1.25.12",

That feed lists the releases the Go project currently publishes as stable, and
the policy that decides how long a release stays on it is one sentence:

    $ curl -s https://go.dev/doc/devel/release | tr '<' '\n' | grep -i 'two newer'
    Each major Go release is supported until there are two newer major releases.

So on the day this file was written the floor is 1.25, and the line in `go.mod`
is `go 1.25.0`. Both outputs above are what those two commands returned that
day, and a reader running them later will see the feed that has moved rather
than the one quoted here, which is the point of quoting the command instead of
only the number. The module they describe does not exist yet: issue #16 creates
it, and this file is what that work is held to.

Two things are deliberately not chosen here. The client library for the stream
transport and the decoder for the alert format are chosen in M5, against the
same standpoint and in their own issues, because a library that decodes the
alert format is a longer commitment than the language and deserves an argument
of its own. The shape they have to satisfy is fixed by
[0003](0003-upstream-and-adapters.md) and
[0004](0004-alert-decoding-and-schema-versions.md), not here.

## Why

The artefact is a daemon that runs unattended for months in a container on a
small machine, possibly in a shed at the end of a garden, and it is judged by
whether it is still delivering notifications in March without anybody having
touched it. It is not a library somebody imports into a notebook, and that
difference decides most of this.

A statically linked binary with no interpreter and no runtime alongside it gives
an image measured in tens of megabytes, a memory floor a single-board computer
can hold while doing something else, and a cross-compile to a 64-bit ARM board
without a cross toolchain on the machine that builds it. Those three are the
properties the deployment in M8 is built out of.

The hot path is a socket, a decode and a predicate evaluation, at a sustained
rate the upstream decision puts in the low hundreds of packets a second per
subscribed channel. In Go that path is bytes into a struct with nothing
interpreting anything in between, and the profiler that would prove it is part
of the toolchain rather than an add-on. The rate is the figure
[0003](0003-upstream-and-adapters.md) carries with its source, and it is a claim
taken from the survey project's published estimates rather than something this
repository has measured.

The three rules this project is built on all survive in this means, which is the
test the choice actually has to pass. A property can be refused, because a
failing test fails a build and a build is what a release is made from. A guard
can be proven to bite, because a fixture can be constructed that trips it and a
neighbour can be constructed that does not. A claim can carry the command that
produced it, because every command in this toolchain is one a reader can run on
their own machine with nothing installed but the language.

The last of those is why the toolchain is named here and not left open. `gofmt`,
`go test`, `go vet`, `go build` and the module verification are one download and
no configuration, so the distance between a claim in a pull request body and a
reader checking it is one command.

## Alternatives rejected, and why

- Python. The scientific stack is the reason anybody would look at it, and this
  project uses almost none of it: no image processing, no fitting, no catalogue
  cross-match, and no plotting anywhere in the delivered path. What it would add
  is an interpreter, a dependency tree that moves weekly underneath an appliance
  meant to be left alone for months, and an image several times the size on a
  machine chosen for being small.
- Rust. The closest call, and it loses on two narrow lines rather than on merit.
  The mature client for the transport this stream is published over is a binding
  to a C library, which puts back the C toolchain that a static binary was
  chosen to remove, and cross-compiling to the small board stops being the free
  thing it is in Go. The part outsiders are most likely to extend is the filter
  engine and the routes, and there the shorter learning curve is worth more here
  than the stronger guarantees, because the failure this project is most exposed
  to is a wrong field in a notification rather than a memory error.
- A shell script wrapped around an existing broker client. There is nowhere in
  it to put a refusable property or an executed proof, the credential handling
  would be argument strings in a process list, which
  [0013](0013-configuration-and-secrets.md) refuses by name, and the error
  handling on a long-running consumer would be exit statuses nobody reads.
- A plugin inside one of the existing broker platforms. That is the thing this
  project exists as an alternative to. It needs an account and a browser, and it
  puts the operator's filters on somebody else's machine, which is the opposite
  of the position the whole plan is built on.
- Leaving the choice open until the first code is written. A repository layout
  is already an answer to this question, so the choice would be made by whoever
  created the first directory and it would never be argued.

## What it costs

There is no astronomy library, which is the largest single cost and the one
that lands on somebody. The one piece of astronomy this program needs is
topocentric horizon coordinates for a fixed site, which is a bounded computation
with published reference values, so it becomes a module with a validation issue
behind it instead of an import. That is written down as its own decision in
[0008](0008-the-sky-is-computed-on-the-host.md), and issue #56 is the validation
that holds the implementation to a stated accuracy. A scientific stack would
have given this away.

Decoding an alert format that moves upstream is handwritten work for the same
reason, and it is why the decoder gets its own decision in
[0004](0004-alert-decoding-and-schema-versions.md) and its own fuzzing in M4
rather than being treated as a library call.

The lint rules are a cost paid every time one is added. `golangci-lint` carries
many linters and enabling a set because it is the popular set produces a gate
whose failures nobody can explain, so each rule is chosen deliberately with its
reason, which is issue #26 and is slower than a copied configuration.

The floor moves. Two Go releases a year means the older of the two supported
ones changes roughly every six months, and holding a floor at an unsupported
release is how a project ends up building with a toolchain that no longer
receives security fixes. The obligation to move it deliberately is real work on
a schedule this project does not control.

None of this is refused by anything today. There is no module, no build and no
suite in this tree, so the sentence about a failing test failing a build
describes what this decision makes possible rather than what exists:

    $ git log --oneline -- cmd internal ; echo "exit=$?"
    exit=0

The listing is empty and the exit status is zero, which is `git log` reporting
that nothing under either path has ever been committed. Issue #16 adds the
module and issue #18 lays out the suite, and until both land this file is a
position rather than a property.
