# 0004. Decoding an alert, and what happens to a schema the build does not know

## What was decided

An alert is decoded against the published schema that the message itself
identifies, and never against a schema the program assumed.

Every message carries the identifier of the schema it was written with, and that
identifier is read before anything else in the message is interpreted. The
identifier decides which schema is used. Nothing about the channel, the upstream
or the order of arrival is allowed to decide it.

The schemas the build knows are compiled into the binary. A decode therefore
needs no network call, works on a machine that cannot reach a registry at all,
and produces the same result on every machine running the same build. Which
schema versions a build carries is printed by the version verb fixed in
[0014](0014-the-operator-command-surface.md), so an operator can answer the
question without reading a release note.

A message whose schema identifier is not in that set is refused. It is not
decoded partially, not decoded with the nearest schema, and not passed to the
filter engine in any form. A refusal is counted in a counter an operator can
see, and logged once with the identifier that was not recognised, the channel it
arrived on and the message identifier. The counter is what makes the condition
visible on the morning after an upstream bump, and the log line is what names
the version to look for.

A bounded sample of refused and otherwise undecodable messages is kept in the
state directory, under the path and inside the bound that
[0005](0005-what-is-kept-on-disk.md) fixes, so that a decode defect is diagnosed
from the thing that actually arrived rather than from a description of it. That
file fixes the bound because it decides what sits on the disk. This file fixes
what is eligible and what is stripped, because that is a property of the message
rather than of the directory:

- Eligible: a message that failed to decode, for any reason. That is a message
  whose schema identifier is unknown, one whose bytes do not parse against the
  schema they name, and one that parses but fails the field-level validation
  below. A message that decoded successfully is never written there, whether or
  not a filter matched it.
- Stripped before the bytes are written: the image stamps, which are the largest
  part of a packet and are of no use in reproducing a decode failure, and any
  header the transport added that carries the operator's credential or their
  subscription identity. What is kept is the alert body and the message
  identifier, which is what a decoder defect is reproduced from. Whether stamps
  are carried at all on the ordinary path is issue #11, which is blocked on
  entry 5 of the maintainer question issue #2. This rule is narrower than that
  one and does not depend on how it is answered: whatever the ordinary path
  does, the diagnostic sample does not keep them.
- One sample per distinct schema identifier and failure kind, rather than the
  first however-many messages. A single bad night otherwise fills the whole
  bound with copies of one failure and hides the second one.

No field is renamed, remapped, defaulted or
inferred inside the decoder. Where a field genuinely moved or changed meaning
between two schema versions, the mapping is written once, in one table that
names both versions explicitly, and it is tested with a recorded message from
each of the two. A mapping with a recorded message from only one side of it is
a mapping nobody has checked.

Field-level validation is part of decoding rather than a stage after it. A
message that parses against its schema but carries a value the rest of the
program cannot mean anything by,
a position outside its valid range being the ordinary case, is treated as a
decode failure rather than being passed on. The filter engine's context in
[0007](0007-what-a-filter-can-see.md) is the decoded alert, so a value that got
past the decoder is a value every filter and every notification downstream will
treat as true.

Fetching an unknown schema from a registry at runtime is available and is off by
default. It is a network call to a host the operator did not necessarily
intend to talk to, so it is switched on knowingly, in the configuration, and it
is subject to the outbound allowlist in issue #48 like every other outbound
address. With it on, a fetched schema is used for that decode and the refusal
counter still records that the build did not know it.

None of this is built. Issue #47 is where the decoder is implemented and issue
#40 is where it is fuzzed, and both are held to this file.

## Why

The schema this stream publishes is versioned and it changes on a schedule
nobody in this repository controls. There are only two things a client can do
about a version it has not seen, and the choice between them is the whole of
this decision: stop and say so, or carry on and be quietly wrong.

Quietly wrong is not a small failure here. A misread field is a plausible number
in the wrong place, and the program's entire output is a notification that sends
somebody outside at two in the morning to point a telescope. A client that
refuses is a client that costs an operator one night and a release. A client
that guesses is one whose notifications cannot be trusted afterwards, including
the ones it got right, because nobody can tell which were which.

Compiling the known schemas into the binary is what makes the refusal
trustworthy. If the schema set could change underneath a running program, the
same bytes could decode differently on two machines and neither would be wrong,
and the question of which schema a notification was produced under would have no
answer. It also keeps the default path free of a network dependency at the hour
it is least wanted, which is the same argument
[0008](0008-the-sky-is-computed-on-the-host.md) makes about the sky.

Keeping the offending bytes is what turns a report into evidence. The difference
between "the decoder broke last Tuesday" and a file holding the message that
broke it is the difference between a guess and a regression test, and issue #40
turns each kept sample into exactly that.

## Alternatives rejected, and why

- Decoding with a single hardcoded schema and ignoring the identifier. It is the
  shortest implementation and it works until the morning after an upstream bump.
  The failure mode is not an error, it is a plausible number in the wrong field,
  which is the worst failure available to a program of this kind.
- Best-effort decoding that fills missing or unparseable fields with zero
  values. A magnitude of zero is a very bright object. A default here is not a
  gap in the data, it is an alert that wakes somebody up for nothing, and it
  arrives looking exactly like a real one.
- Requiring a registry at runtime. It adds a third party that has to be
  reachable at three in the morning for the program to work at all, it tells
  that party which schemas this operator is asking for and therefore roughly
  what they are running, and it makes an outage there indistinguishable from a
  quiet night. Available and off by default is the version of this that an
  operator can accept for their own installation.
- Refusing a message but not keeping any of it. It is cheaper and it costs the
  next person the ability to reproduce the failure. The bound in
  [0005](0005-what-is-kept-on-disk.md) is what makes keeping it safe on a small
  disk.
- Refusing the whole subscription on the first unknown identifier, rather than
  the message. One channel republishing an experimental version would take the
  program down for the channels that were fine, which is a larger failure than
  the one being prevented.
- Treating a field-range violation as a warning and passing the alert on. It
  moves a decision about whether a value is meaningful out of the one place that
  knows what the schema promised and into every filter an operator writes.

## What it costs

An upstream schema bump stops the client until a release carries the new schema.
That is the deliberate trade, and it is the cost of the whole decision rather
than a detail of it. It is bounded in three ways and none of them removes it:
the refusal is loud and names the identifier, the bytes are kept so the fix can
be written and tested immediately, and an operator who accepts the exchange can
switch the registry fetch on for their own installation.

The compiled-in schema set has to be kept current, which is a release
obligation rather than a code one. It is named in M10 with the rest of what a
release owes, and it is the kind of obligation that is met for two releases and
then forgotten, which is why the version verb prints the set rather than leaving
it in a changelog.

One mapping table between two versions is honest work that a scientific stack
would have supplied. Every entry needs a recorded message from both versions to
be tested at all, and those recordings have to come from a live stream, which is
issue #51 and is the one part of this that cannot be done offline.

The refusal counter is only useful to somebody who looks at it. An operator who
never reads a counter and never reads a log learns about a schema bump by
noticing that nothing has arrived, which is the failure this project is written
against, and the answer to it is the status surface in M8 rather than anything
in this file.

Nothing refuses any of this today. There is no decoder, no counter and no state
directory in this tree, and the rules that would refuse a partial decode or a
silent default do not exist yet either. Until issue #47 lands, this file is a
position a reader can hold the implementation to and nothing is holding it.
