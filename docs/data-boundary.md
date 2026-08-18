# The data boundary

This program knows where its operator lives to within a few metres, what they
are interested in, and when they are awake. That is a more intimate set of facts
than most software holds, and it is held on a machine in their house. The
position of this project is that it stays there.

## The statement

Nothing about the operator, their site, their filters, their notification
endpoints or the alerts they received leaves their host, unless the operator
deliberately configures a destination that receives it. There is no telemetry,
no crash reporting, no update check, no analytics and no default endpoint owned
by this project.

That paragraph is repeated word for word in `README.md`, because somebody
deciding whether to install this should be able to read the position in thirty
seconds without opening a second file. Two copies of one sentence drift, and
nothing in this repository refuses that drift today. Issue #34 is where a rule
that compares the two would go, and until it exists a reader is what stands
behind them being identical.

## The three things that leave, and what each other party learns

All three are configured by the operator. None of them happens by default.

**The subscription to the upstream.** The adapter connects to the upstream the
operator configured, with the credential they obtained, and subscribes to the
channels they chose. That upstream learns which channels this subscriber reads,
when the client is connected and when it is not, and the network address it
connects from. On the shape that serves a per-user filtered stream, described in
[0003](decisions/0003-upstream-and-adapters.md), it also learns the filter
itself, because that selection happens on the far side. That is the one shape
where the operator's question leaves the house, and it is a reason to prefer the
pre-split shape rather than a detail of it.

**The notifications.** They go to the routes the operator configured, which is
their own ntfy server, their own Matrix homeserver or their own webhook
endpoint. Each of those learns the six fields the notification contract fixes in
[0009](decisions/0009-the-notification-contract.md), and it learns them at the
moment the operator was woken, which is itself a fact about the operator. The
position in those six fields is the object's, not the site's, but the altitude
and azimuth are computed for the configured site, so a party holding several
notifications can recover roughly where that site is. An operator sending
notifications to a service somebody else runs is telling that service where they
observe from, and that is stated here rather than left to be worked out.

**The optional schema lookup.** If the operator switched on the runtime schema
fetch, which is off by default in
[0004](decisions/0004-alert-decoding-and-schema-versions.md), the host serving
that registry learns which schema identifiers this installation encountered and
when it encountered them. Nothing else is sent, and with the fetch off, which is
how it ships, nothing is.

## What does not leave, and why it is worth naming

The site coordinates never leave. The sky is computed on the host,
[0008](decisions/0008-the-sky-is-computed-on-the-host.md), so there is no
horizon service to ask and no request carrying a position and a time.

The filter set never leaves, except on the per-user filtered upstream above,
where it is the mechanism rather than a leak.

The state directory never leaves. What it holds and what bounds it are
[0005](decisions/0005-what-is-kept-on-disk.md), and every one of the four kinds
is a fact about the operator: which channels they read, what they were told
about, what they were told twice, and which alerts they kept.

Four of the six verbs in
[0014](decisions/0014-the-operator-command-surface.md) reach neither the network
nor a credential, so an operator debugging a filter is not contacting anybody
while they do it.

## What stands behind this today

A document and a reader. Nothing in this tree refuses a violation of the
position above, because there is nothing in this tree to refuse it in:

    $ git ls-tree -r --name-only origin/main -- cmd internal go.mod ; echo "exit=$?"
    exit=0

The listing is empty and the exit status is zero, which is git reporting that it
matched nothing rather than that it failed.

What is owed, in the order it can arrive:

- The outbound allowlist in the transport layer, issue #48. A destination that
  is not one of the three above cannot be contacted, and the refusal is
  demonstrated against a fixture rather than described.
- A rule in the greppable invariants set, issue #34, refusing an outbound call
  that does not go through the transport layer, so the allowlist cannot be
  walked around by a package that dials for itself.
- A test in the gating suite that replays a recording with every feature on
  except the configured destinations and asserts that the process made no
  outbound connection at all. That needs the module in issue #16 and the harness
  in issue #18, and it is where the position stops being prose.
- The verb in issue #83 that prints every address a given configuration will
  contact, so an operator checks their own installation rather than trusting
  this file.

Until those exist, read this document as a position the project holds rather
than as a property the tree enforces.

## The open entry this position rests on

Whether a hosted or federated mode is ever intended is entry 3 of issue #2, and
it has no answer. That entry takes the statement at the top of this document as
its own subject. It repeats the sentence and says the sentence stays true only
once the answer is known.

    $ gh issue view 2 --json body --jq '.body' | grep -c '^## 3\. Whether a hosted or federated mode is ever intended'
    1
    $ gh issue view 2 --json body --jq '.body' | grep -c 'Options: never, in which case the outbound surface can be an allowlist'
    1
    $ gh issue view 2 --json comments --jq '.comments | length'
    0

The entry is still written as two options with their costs, and the issue
carries no comment, so neither option has been taken. The first is never, and
under it the outbound surface can be an allowlist holding the upstream and the
operator's own endpoints and nothing else, which is the mechanism named above.
The second is possibly later, and under it the boundary still has to be drawn
now, which is a line this file does not draw.

Everything below assumes the first option was taken, because that is what the
plan assumes throughout. Read that as an assumption; no decision recorded
elsewhere stands behind it. If the answer is never, the document stands as
written. If it is not, what moves is the shape of the allowlist in issue #48 and
what the verb in issue #83 has to print, and both are already named above as
owed rather than built.

## What this document does not claim

It does not claim that the parties named above behave. An upstream, a
homeserver or a push service can log what it receives, and this project has no
view into that. What is bounded here is what is sent, not what is kept.

It does not claim that the network is quiet in every other respect. A container
image is pulled from somewhere, and a machine that runs this program has an
operating system doing its own things. The statement is about this program.

It does not claim that the three exceptions are unavoidable. Two of them are the
point of the program. The third, the schema lookup, is off by default precisely
because it is not.
