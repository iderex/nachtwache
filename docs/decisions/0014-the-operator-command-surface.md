# 0014. The operator command surface

## What was decided

One binary, with six verbs at the first release and no others.

| Verb | What it does | Network | Credential |
| --- | --- | --- | --- |
| `run` | consumes, evaluates and delivers | yes | yes |
| `check` | validates the configuration and every filter file | no | no |
| `replay` | runs a recording through the filter set, delivering nothing | no | no |
| `explain` | prints condition by condition why one alert matched or did not | no | no |
| `record` | subscribes and writes raw messages to a file | yes | yes |
| `version` | prints the version, the build and the compiled-in schema versions | no | no |

Four of the six need neither the network nor a credential, and that is the
property being decided rather than an observation about the table. An operator
debugging a filter at eleven at night is not also debugging their connection to
an upstream, and a contributor reproducing a reported problem needs a recording
and nothing else.

`run` is the container's default command. It is the only verb the shipped image
runs without being told to, and the compose file in issue #72 does not override
it.

`check` validates the configuration file and the whole filter directory with the
same code path the daemon runs at start, prints the effective configuration with
every secret redacted, and exits with a status that says whether the daemon
would have started. [0013](0013-configuration-and-secrets.md) fixes that
behaviour and defers the name to this file, where it is called `check` rather
than `config check`, because it validates the filter directory as well as the
configuration and a name mentioning only one of the two would be read as
covering only that one. The illustration in that file is the placeholder it says
it is.

`replay` takes a recording and the current filter set and prints what would have
been delivered. It delivers nothing, it opens no route, and it needs no
credential for a route it is not going to contact. Its clock is the timestamp of
the message being replayed rather than the wall clock, which is the injected
instant [0007](0007-what-a-filter-can-see.md) fixes and is what makes the output
mean the same thing tomorrow.

`explain` takes one alert out of a recording and one filter and prints the
condition tree with the verdict at every node. It is the verb the declarative
filter format in [0006](0006-how-a-filter-is-written.md) exists to make
possible.

`record` subscribes and writes raw messages to a file, bounded by a count or by
a duration given on the command line, and it refuses to run unbounded. It is the
only verb besides `run` that touches an upstream, and the recordings it produces
are what the other two debugging verbs and the default suite consume.

`version` prints the version, the build identity, and the schema versions
compiled into the binary, which is the set
[0004](0004-alert-decoding-and-schema-versions.md) makes the decoder refuse
outside of. It is how an operator answers a question about a refused message
without reading a release note.

No verb prompts. Nothing in this program reads from a terminal, asks a yes or no
question, or blocks waiting for a person, in any verb and under any error. A
verb that lacks something it needs says what is missing and exits non-zero.

The output of every verb goes to standard output, diagnostics to standard error,
and every verb exits zero only when it did what it was asked. Beyond that, the
shape of the output is not fixed here.

None of this exists yet. Issue #60 builds `explain`, issue #61 builds `replay`,
and the rest arrive with the components they drive.

## Why

Whatever else this program is, it is a command an operator runs. The set of
verbs it answers to is small and it is fixed before any of them is written,
because a command surface that accumulates one verb at a time ends up with three
ways to do one thing and no way to do another.

The rule that shapes the set is that everything needed to understand a filter
works without the stream. That rule produces the table above rather than being
checked against it afterwards. It is what makes a filter debuggable by somebody
who is not connected, it is what lets the default suite run with no network at
all, and it is what lets a contributor reproduce a problem from a recording
somebody sent them.

Separating `record` from `replay` is the mechanism that makes the rule true.
Once the bytes are in a file, every question about what a filter would have done
is a question about that file, and the upstream is out of the path. That is also
why `record` exists at all: it is a debugging aid and it is the source of the
fixtures the suite in M2 runs on.

Fixing the container's default command here rather than in the deployment work
keeps one answer in one place. An image whose default command is a shell, or
whose entrypoint is a script that decides which verb to run, is an image where
the question of what happens when it starts has two answers.

The prohibition on prompts is not a style preference. This runs as a service in
a container with no terminal attached, so a verb that can block on a prompt is a
verb that will one day block forever on a machine nobody is looking at, and the
symptom will be a program that is running and doing nothing.

## Alternatives rejected, and why

- A web interface for editing filters. It is what the existing platforms have
  and it is what the kickoff says this project is not. A read-only status page
  is a different thing, it does not edit anything, and it belongs to the M8
  status work rather than to this surface.
- A second binary for the tooling, so that the daemon image carries only `run`.
  It doubles the release artefacts and the signing and provenance obligations in
  M10 to save nothing, because the code behind the debugging verbs is the same
  code the daemon runs and shipping it twice is what a second binary means.
- Interactive prompts, for example a setup wizard that asks for the site
  coordinates. Covered above. The quickstart in M10 pays for their absence by
  showing a complete configuration file rather than a conversation.
- A verb that edits or generates a filter file. It sounds helpful and it makes
  this program a writer of the files it is also the reader of, which is how a
  format acquires two definitions. Example filters that work unedited, issue
  #62, are the answer to the same want and they can be read before they are
  trusted.
- A verb that tests a notification route by sending to it. It is a real want and
  it is deliberately not in the first release, because it is the one debugging
  action that needs a credential and a network call, and adding it would put a
  fifth row in the network column of the table above for a convenience. The
  operator can send a test through their route's own tooling.
- Subcommands grouped under nouns, for example `filter check` and `filter
  explain`. It reads well in a document and it makes every command longer for a
  surface with six entries in it.
- Leaving the set open and adding verbs as components land. The set would then
  be a consequence of the build order rather than a decision, and the property
  in the table, that four verbs need no network, would be true by accident and
  would stop being true without anybody noticing.

## What it costs

`record` and `replay` are real features, with tests, documentation and their own
file format for the recording, and they exist mostly to serve the suite and the
operator's confidence rather than the running system. That cost is paid
deliberately and it buys two things at once: they are also the mechanism the
default suite uses instead of a network, which is what makes the suite headless.

Six verbs is six surfaces to document, and the documentation has to say for each
one what it needs, which is exactly the table above and is exactly the thing
that drifts. The M10 operator reference, issue #87, is generated from the same
source the binary uses so the two cannot disagree, and that generator is work
this decision creates.

Fixing the set at six means the seventh want is a decision rather than a commit.
The route test rejected above is the most likely candidate and somebody will
have a good reason for it, and the answer is a file superseding this one rather
than an addition nobody argued.

`record` writes raw upstream messages to a file that an operator may well send to
somebody else when reporting a problem. Those bytes are the alert stream rather
than anything about the operator, and the transport headers that would carry
their subscription identity are the ones
[0004](0004-alert-decoding-and-schema-versions.md) strips from the diagnostic
sample. Whether `record` strips the same headers is not settled here and is
issue #83's neighbour rather than this file's; it is named so it is not
discovered later.

Nothing refuses any of this. There is no binary, so a seventh verb, a prompt, or
a `replay` that quietly opened a route would be refused by nothing in this tree
today. The property that four verbs reach no network is the kind a check can
hold once there is code to hold, and issue #34 is where rules of that shape are
built.
