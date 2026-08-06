# 0003. The upstream shape the client is built around

## What was decided

The client reaches the alert stream through one adapter interface, and the shape
it is built around is the pre-split one: an upstream that publishes disjoint
thematic channels, where subscribing means choosing a few channels rather than
taking everything. The operator's filters then run over a stream that is one or
two orders of magnitude smaller than the whole, on a machine that can afford it.

The interface carries four things and nothing more:

- a subscription, expressed as a set of channel names,
- a stream of raw messages, each with an identifier and a timestamp,
- an acknowledgement position, so a restart can continue where the last one
  stopped,
- an error channel, with errors sorted into the two categories the consumer acts
  on differently, one worth retrying and one not.

Everything upstream-specific stays inside its adapter. That includes the channel
naming scheme, the credential shape, the wire encoding of a message and any
enrichment the upstream adds on top of the published alert.

The same interface admits two other shapes. An upstream that serves a per-user
filtered stream, where the selection happens on the far side and the client
receives what is left. And the unsplit full-rate feed, for an operator with the
connection and the disk to take it. Neither is the default, and the
documentation states the arithmetic below before it offers either.

Which named upstream ships as the configured default is not settled here. It is
entry 4 of the maintainer question issue, #2. This file fixes the shape and the
interface, which is what the code depends on, and it stays true whichever
upstream is chosen.

## Why

The published key numbers for this stream are about ten million alerts a night
and an alert packet of at most roughly eighty kilobytes with its image stamps
included. Ten million times eighty kilobytes is around eight hundred gigabytes
in one night, arriving at a sustained rate in the low hundreds of packets a
second.

Those two input numbers are taken from the survey project's own published
estimates. They are a claim here and not a measurement, and nothing in this
repository has measured them. Issue #51, which builds the live upstream
harness, is where they stop being a claim.

Eight hundred gigabytes a night does not fit through a domestic connection and
does not fit on the machine this program is written for. Any design that starts
by consuming everything and filtering afterwards has already failed for the
person with a telescope in the garden, however good the filter engine is.

### The upstreams considered

Seven brokers process the full stream. The observatory's own page describes what
each of them offers a subscriber:

- ALeRCE. Web interfaces for object exploration, early supernova
  identification and a watchlist system, reachable by web portal, a Python
  client, APIs or direct database queries.
- AMPEL. The observatory's page carries no description of what it offers, so
  nothing is stated here about it.
- ANTARES. A web portal, an API, or substreams of alerts produced by filters
  the user writes in Python, with watch lists for direct notification.
- Babamul. Channels organised by the properties of the event, where a
  subscriber takes only the channels relevant to their work and filters further
  from there.
- Fink. A web portal, an API, or a Kafka stream.
- Lasair. Filters written in SQL that run in real time as alerts arrive,
  driven from a web page or an API.
- Pitt-Google. A Python library over a cloud platform.

Two further brokers, SNAPS and POI Broker, take a subset of alerts from one of
the seven rather than the whole stream. They are not candidates here because an
upstream that is itself downstream of another adds a second party's availability
and a second party's selection to the path without adding a shape this client
does not already have.

Beyond those, the stream can be taken unsplit and direct.

Sorting those into the three shapes above is a reading of the descriptions the
observatory publishes, not a measurement. Channels organised by event property
is the pre-split shape. A per-user filter that produces a substream is the
filtered shape. Everything else on that list is a web platform or a query
interface rather than a stream a daemon subscribes to, and a web platform is not
an upstream for this program. Issue #51 is where each candidate is exercised
against the interface and the reading is either confirmed or corrected.

What every one of them requires of a subscriber is an account. None of the seven
is anonymous, and the project README states the same thing from the other side:
all seven are web platforms with an account and a browser interface. The
registration procedure, the credential shape and the channel naming differ
between them, and none of that is established in this repository. Each one is
held inside its own adapter for exactly that reason, and #51 is where the detail
is measured rather than assumed. This project distributes no credential of its
own under any of these options.

## Alternatives rejected, and why

- Building against one broker's client library directly. It is the fastest path
  to something that works, and it makes the project a dependent of one broker's
  availability, naming and terms. The interface is small. The coupling would not
  be.
- Taking the full stream and filtering locally as the primary mode. The
  arithmetic above is the reason. It stays supported for the operator who
  genuinely has the bandwidth, because refusing to support it would be a
  different kind of dishonesty, and it is not what the client is built around.
- Consuming a web API by polling instead of subscribing to a stream. It puts the
  latency this project exists to remove back into the path, and the interesting
  alert at eleven at night is the one that is still overhead.
- Treating a downstream broker as an upstream. Covered above: it lengthens the
  chain without shortening the stream in a way the pre-split shape does not
  already.

## What it costs

An adapter interface has to be right before there are two implementations to
check it against, which is the ordinary way to get an abstraction wrong. The
mitigation is that the interface carries only what every upstream genuinely has,
which is the four items listed above and nothing else. A field that exists on
one upstream and not another belongs inside that adapter.

A change of upstream costs one adapter. The decoder, the filter engine and the
notification routes do not change, because none of them sees an upstream. If a
change of upstream did reach further than the adapter, that is the interface
having leaked and it is a defect in this decision rather than in the new
upstream.

Two things are not paid for by this decision and are worth naming. The pre-split
shape means the operator's reach is bounded by what channels the upstream chose
to publish, so a question nobody at the upstream anticipated cannot be asked
without moving to the filtered shape or to the full feed. And the access route
for the unsplit feed is not verified in this repository: the README states the
stream can be subscribed to directly by a registered user, this file does not
re-derive that, and #51 is where it is established.
