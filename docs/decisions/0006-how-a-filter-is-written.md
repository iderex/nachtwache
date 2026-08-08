# 0006. How a filter is written, and why it is data rather than a program

## What was decided

A filter is a declarative file. One filter per file, in the filter directory
[0013](0013-configuration-and-secrets.md) sets aside for exactly that, and it
holds four things:

- a name, which is what appears in a notification and what the deduplication key
  in [0009](0009-the-notification-contract.md) is built from,
- a format version,
- a set of conditions over named fields of the evaluation context fixed by
  [0007](0007-what-a-filter-can-see.md), combined with `and`, `or` and `not`,
- the routes to notify when it matches.

There is no embedded scripting language, no expression to be evaluated, no
callout of any kind, and no way for a filter to name anything the context does
not already carry. A filter is read into a tree of conditions and that tree is
the whole of it.

The serialisation is YAML, restricted to its plain subset: no anchors, no
aliases, no tags, no multiple documents in one file, and a single mapping at the
top. That is the shape the configuration example in
[0013](0013-configuration-and-secrets.md) is already written in, and the
restriction is the part being decided here. The features left out are the ones
that turn a data format back into something with behaviour, and a filter file is
the one file in this project that is expected to arrive from a stranger.

The format version is checked before the rest of the file is looked at. A
version the build does not know is refused, with the version named and the file
named, and it is never assumed compatible and never treated as the newest known
one. This is the same rule the decoder applies to a schema identifier in
[0004](0004-alert-decoding-and-schema-versions.md), for the same reason, and a
filter file is the case where the operator can actually fix it.

A filter is validated before it is ever run, by a verb the operator runs
themselves, which is `check` in
[0014](0014-the-operator-command-surface.md). Validation is fail-closed and it
is the whole directory: an invalid filter refuses to load, and per
[0013](0013-configuration-and-secrets.md) the daemon refuses to start rather
than skipping it with a warning. A skipped filter is a question the operator
believes they are asking and are not.

The set of available fields, operators and route names is documented in one
place and generated from the same source the engine reads, so the documentation
cannot drift away from what is actually accepted. Which source that is and how
it is generated is issue #87 in M10, and the property being fixed here is that
there is one source and not two.

None of this exists yet. Issue #53 builds the format and its refusals, issue #54
fixes the condition set, and issue #62 ships the example filters that prove the
format is writable by somebody who has not read this file.

## Why

The kickoff promises filters as versioned configuration files rather than a
click interface. That is half a design. What may be inside such a file is the
other half, and it is the half the project is judged on, because the filter is
the part an operator actually writes.

Four things are cheap over a declarative set and expensive over arbitrary code.

A filter can be validated before it runs, so a mistake is caught at eleven at
night while somebody is looking at the output, rather than at two in the morning
by not being woken.

A match can be explained condition by condition. That is the feature that makes
a filter debuggable by the person who wrote it, and it is what the `explain`
verb is. Explaining why a condition tree did not match is reading which node
returned false. Explaining why arbitrary code did not match is tracing it.

A filter can be replayed against a recording, which is the only way anybody
gains confidence in one before trusting it with their sleep. Replay is only
honest if the same file and the same recording give the same verdict every time,
which is the purity [0007](0007-what-a-filter-can-see.md) fixes and which
arbitrary code would remove.

And a filter cannot reach the network, the disk or the clock. Filters will be
shared, on forums and in repositories and in messages between two people who
have met once. That is a good thing and it is how the useful ones spread. It is
only safe if a filter file is data, because the alternative is that an operator
who copies a filter is running somebody else's program on their own machine,
against a credential-bearing daemon, unattended, for months.

The last of those is the real argument. The other three are why this is
pleasant. That one is why it is not negotiable.

The restriction on the serialisation follows from the same sentence. An
unrestricted YAML document is not only data in every parser: tags can name types
to construct, and anchors and aliases can expand a small file into a large one
during parsing, before any of this project's own validation has seen it. Both
are behaviour, and both would be reached by a file that arrived from a stranger.

## Alternatives rejected, and why

- An embedded sandboxed language, for example one of the small deterministic
  dialects designed for configuration. This is the serious alternative and it
  was rejected on the explain feature and on reviewability rather than on
  safety, because the good dialects are genuinely safe. A shared filter written
  in one is still something a recipient has to read as a program to know what it
  does, and the per-condition explanation, which is the feature operators will
  use most, degrades into a trace.
- A general expression language over the alert fields. Closer to what is chosen
  here than to a scripting language, and it is the recorded fallback rather than
  a rejection on principle. It is not taken now because it makes every field of
  the context part of the public interface from the first release, and it moves
  the validation an operator gets from "this condition names a field that does
  not exist" to "this expression is syntactically valid". The condition that
  would justify moving to it is written below rather than left to a later
  argument.
- A click interface for building filters. That is what the existing platforms
  have, it is the gap this project exists to fill, and it cannot be put in
  version control or sent to somebody else.
- A filter as a compiled plugin. It is the fastest thing to execute and it makes
  a shared filter a binary, which is the worst version of the sharing problem
  above.
- JSON as the serialisation. It carries no comments, and a filter set nobody can
  annotate is one whose author cannot say why a condition is there. TOML was
  the other candidate and loses only on consistency: the configuration example
  already committed in this tree is in the mapping style YAML reads, and two
  formats in one program is a thing an operator has to learn twice.
- Leaving the serialisation open and deciding it when the parser is written. The
  restriction above is the decision, and a parser chosen without it is a parser
  that accepts tags because its defaults do.

### The fallback, and what would trigger it

The fallback is a general expression language over the same context, and it is
recorded here so that the move is a decision rather than a drift.

What triggers it is a documented case an operator actually wants that cannot be
written with the condition set at all, as opposed to one that is awkward or
verbose. Awkward is answered by adding a condition to the set, which costs a
release and no decision. The trigger is reached when the shape of the want is
the problem rather than the vocabulary, and the honest test for that is whether
adding one more condition would fix it or whether the operator needs to relate
two fields to each other in a way no fixed set of conditions anticipates.

If it is reached, it supersedes this file rather than being added beside it, and
it inherits everything [0007](0007-what-a-filter-can-see.md) fixes: the context
stays closed, and an expression that could reach the network, the disk or the
clock is not the fallback being described here.

## What it costs

Some filters cannot be expressed, and some operators will be annoyed by that.
The escape hatch is deliberate and it is the webhook route: an operator whose
logic does not fit writes a filter that is deliberately wide, receives the
matches at their own program on their own machine, and does whatever they like
there. That keeps this project out of the business of running other people's
logic while leaving the person with an unusual want a path that works today. It
costs them a program to run and a machine to run it on, which is a real cost and
is why the condition set in issue #54 is worth arguing over.

The generated documentation is real work. A hand-written field list is the
cheapest thing to produce and it drifts within two releases, at which point the
documentation is worse than none because it is believed. Paying for the
generator once is the alternative, and it is a dependency between M6 and M10
rather than a free property.

The version rule means an operator who upgrades their filter files before their
binary gets a refusal rather than a best effort. That is the same trade as the
decoder's, made in the one place where the person who can fix it is the person
reading the message.

The restricted YAML subset will surprise somebody. Anchors are a reasonable
thing to reach for in a large filter set, and the answer here is that they are
not available and that repetition across filter files is accepted instead.

Nothing refuses any of this today. There is no parser, no validator and no
suite in this tree, so a filter file with a tag in it would be refused by
nothing, and the restriction above is a position issue #53 is held to rather
than a property this repository has.
