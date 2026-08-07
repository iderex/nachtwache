# 0007. What a filter can see when it is evaluated

## What was decided

A filter is evaluated against one context and against nothing outside it. The
context carries four things:

- the decoded alert, as the decoder produced it,
- the history the upstream attached to that same alert, which is the previous
  detections and non-detections that arrive inside the packet rather than
  anything fetched separately,
- the observer's site as configured, which is the position on the Earth, the
  elevation, and the horizon obstructions where an operator has given them,
- one instant.

Nothing else is reachable from inside an evaluation. Not the network, not the
filesystem, not the state directory fixed by
[0005](0005-what-is-kept-on-disk.md), not another alert, and not the ambient
wall clock.

The instant is injected rather than read. The evaluation package is given a
clock at construction, an interface named `Clock` with one operation that
returns the current instant, and the ambient clock is reachable from nowhere
inside that package. Under test the clock is a fixed value. Under a replay it is
the timestamp of the message being replayed. In the daemon it is the real one,
supplied at the edge, once.

Those four are enough to answer the questions this project promises a filter can
ask. Whether the object is above the operator's horizon needs the alert's
position, the site and the instant, and all three are in the list. Whether the
sky is dark and where the moon is needs the site and the instant. Nothing in the
promised condition set needs a fifth thing, and a condition that would is a
condition that costs a decision superseding this one rather than a quiet extra
field on the context.

A filter is therefore a function from that context to a verdict and a reason.
The same context produces the same verdict and the same reason on any machine,
at any hour, in any order relative to other alerts.

Everything that is not a property of the one alert sits after the match and is
decided by the engine rather than by a filter. Deduplication and the retry
behaviour are fixed by [0009](0009-the-notification-contract.md); the stages
they run in and the queues between them are fixed by
[0011](0011-process-shape-and-queues.md). Rate limits and quiet hours are
engine behaviour for the same reason.

None of this is refused by anything today. Issue #34 carries the rules that
refuse a network call, a filesystem write and a read of the ambient clock from
the packages that may not make them, and issue #8 is what that work is held to.

## Why

A filter is only testable if what it is allowed to look at is fixed. An open
context, where a filter may reach whatever the engine happens to have to hand,
makes the set of things a filter depends on unknowable, and once it is unknowable
no check can refuse a new dependency and no test can be trusted to have exercised
the real one.

The closed list is what lets the default suite need a CPU and a temporary
directory and nothing more. A suite that has to stand up a network route or wait
on somebody else's server to evaluate one filter is a suite that is slow, flaky
and eventually not run.

The injected instant is the same argument applied to time. A test that asks
whether an object was above the horizon at a given moment passes at three in the
afternoon and at three in the morning, on a machine in any time zone. An operator
replaying last week's recording sees what they would have seen last week rather
than what the sky looks like while they are reading. A filter that read the
ambient clock would be the same function with a hidden argument, and the hidden
argument is the one nobody writes a test for.

A pure function is also what makes the two debugging verbs honest. A command
that prints condition by condition why one alert matched can only be believed if
running it twice gives the same answer, and a recording replayed through the
filter set can only show what would have been sent if nothing outside the
recording reached the evaluation.

## Alternatives rejected, and why

- Letting a filter query the state directory, for example to ask whether this
  object has been seen before. It is a real want and it is the fastest way to
  make every filter time-dependent and untestable, because the answer then
  depends on what the program did on previous nights. The engine answers that
  question itself in the deduplication stage, where it is reasoned about once
  instead of once per filter.
- Letting a filter reach a catalogue over the network for a cross-match. It
  converts an evaluation that waits on nothing into one that waits on somebody
  else's server, at the rate the stream arrives, and it makes an outage at that
  server look like a filter that stopped matching. The second effect is the
  worse one: a filter that silently stops matching is the failure this whole
  project is written against.
- Letting a filter see the other alerts in the same batch. It reads as harmless
  and it makes the verdict depend on how the upstream happened to group
  messages, which is not a property of the alert and is not stable across
  upstreams or across a restart.
- Reading the wall clock inside the evaluation instead of injecting it. Covered
  above. It is cheaper by one constructor argument and it costs the replay verb
  its meaning.
- An open context carrying whatever is available, with the discipline left to
  the filter author. It is cheap now and it removes the ability to refuse the
  violation later, which is the property this file exists to create.

## What it costs

Filters cannot enrich. Anything a filter needs to know has to arrive inside the
alert or be configured on the site, and an operator who genuinely needs an
outside lookup takes the alert through the webhook route and does the lookup in
their own program. That is a real limit and it is the one most likely to be met
by somebody doing serious work.

Cross-alert questions cannot be asked by a filter at all. A condition of the
shape "only if this is the third detection tonight" is either engine behaviour
somebody has decided on, or it is not available. It cannot be written by an
operator in a filter file.

The site is part of the context rather than part of the filter, so a filter file
copied between two operators answers differently at the two sites. That is
correct rather than a defect, since the horizon is a property of where somebody
stands, and it means a shared filter file cannot be read as a promise about what
it will match until the reader knows the site it will run at.

The closed list means a want that arrives later costs a decision that supersedes
this one, not a field added to the context. That is deliberate and it is the
same trade as the fixed notification field set in
[0009](0009-the-notification-contract.md). It will feel expensive the first time
somebody has a good reason.

The purity is asserted here and refused nowhere. Until the rules in issue #34
exist, a change that reaches the clock, the network or the disk from inside the
evaluation package passes every route this repository has, and the only thing
standing against it is a reader.
