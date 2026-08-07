# What this project does not claim

## What it is

Packaging.

The alert stream is public and any registered user can subscribe to it. Seven
brokers already process it, and all seven are web platforms with an account and
a browser interface. This project makes that same stream usable on somebody's
own machine, in a container, with filters kept in files they can version and
share, so that the answer to "I want to be woken when this happens" is a file
rather than an account on somebody else's site.

That is a sufficient reason for this to exist. It is not a scientific
contribution and the five statements below are what keeps it from being read as
one.

## What it is not

**It is not a broker.** It processes nothing that the upstream did not already
process. There is no classification of its own, no cross-match against a
catalogue and no model. That is a property fixed by decision rather than an
accident of what has been built so far:
[0007](decisions/0007-what-a-filter-can-see.md) closes the evaluation context to
the decoded alert, the history the upstream attached to it, the configured site
and one instant, and rejects a network cross-match by name.
[0003](decisions/0003-upstream-and-adapters.md) keeps any enrichment an upstream
adds inside that upstream's adapter, so enrichment stays something the upstream
did and not something this program can be credited with.

**It is not a discovery pipeline.** A notification is a reason to look at
something. It is not a claim about what the thing is.
[0009](decisions/0009-the-notification-contract.md) fixes the six fields a
notification carries, and every one of them is either copied from the alert or
computed from the operator's own site. None of them is a judgement, and no route
may add a seventh field that would be.

**It is not faster than the upstream it reads.** Its latency is the upstream's
latency plus its own, and its own has not been measured. Nothing in this
repository has measured either number, and no document here states one. Issue
#50 is where the lag against the stream is measured and acted on, and issue #77
is where the footprint on a named machine is measured and published. Until one of
those has run, the correct reading of this project's speed is that it is unknown
and bounded below by whatever the upstream does.

**It is not a substitute for the platforms.** Somebody who wants a browser, a
community and other people's expertise should use one of the seven, and this
document says so without grudging it. What each of them offers a subscriber is
set out in [0003](decisions/0003-upstream-and-adapters.md), which was written to
choose an upstream shape rather than to argue that the platforms are inadequate.
They are not inadequate. They serve a different person from the one this is for.

**It is not validated for anything time-critical where a missed notification
matters.** Two things in the design already say why. A notification route that is
slower than the stream has its queue shed the newest notification and counted,
which [0011](decisions/0011-process-shape-and-queues.md) states along with the
residual risk that an operator who watches neither the counter nor the log will
not learn it happened. Delivery is at least once up to a bound of six attempts or
fifteen minutes, after which a notification is counted as failed rather than
retried forever, which is
[0009](decisions/0009-the-notification-contract.md).

What the client does when it falls behind the stream itself is a decision that
has not been written down yet. Issue #13 holds it, and until it lands there is no
recorded position on whether the client skips, waits or stops. Anybody whose use
depends on completeness should read that decision when it exists and should not
assume this document has answered it.

## What this document is for

Overclaiming is cheap at the moment it is written and expensive for as long as
anybody remembers it. A reputation for saying more than was measured is corrected
slowly and by other people.

So the five statements are here to be pointed at, including by somebody arguing
against a change to this project. A change that makes one of them false is a
change that supersedes this document rather than one that quietly outgrows it.
