# 0009. The notification contract

## What was decided

Delivery is at least once.

A notification that a route accepted is recorded as delivered. A notification
whose route failed is retried with exponential backoff and jitter up to a bound
of six attempts or fifteen minutes of total elapsed time, whichever is reached
first. Past that bound it is counted as failed and logged with the route named
and the reason given. It is never dropped silently and it is never retried
forever. A route that reports a permanent failure, an address that does not
exist being the ordinary case, is not retried at all.

Duplicates are prevented before delivery, not after it. The key is the filter
and the object together, over a window the operator sets, `notify.dedup.window`,
default 24 hours. The same object matching two different filters produces two
notifications, because the operator asked two different questions and is owed
two answers.

Order is not promised. Two alerts that arrive in the same second may be
delivered in either order, and no route is expected to preserve an ordering it
does not have.

A notification carries six fields and nothing else by default:

- the object identifier,
- its position,
- the brightness measurement that triggered the match,
- the altitude and azimuth for the operator's configured site at the moment of
  the observation,
- the name of the filter that matched,
- the time of the observation.

A route may render those six differently, and a route may not add a seventh. A
field that appears in one route's output and not another's is a field the
operator cannot rely on, and a field invented by a route is a field nobody can
explain the meaning of at two in the morning. Where a route needs something this
list does not carry, the answer is the webhook route and the operator's own
program, not an extra field on one route.

The state this contract needs on disk, which is the delivery record and the
deduplication record, is fixed by
[0005](0005-what-is-kept-on-disk.md), including their bounds.

## Why

Three delivery routes are promised and more will be asked for. They are only
interchangeable if what delivery means is written down once, before any of them
exists, because otherwise each route's behaviour is whatever its author found
convenient and an operator who switches route finds out what changed by missing
something.

At least once rather than at most once is decided by what this program is for.
It is relied on to wake somebody up. A guarantee that occasionally drops a
notification is worse for that purpose than one that occasionally repeats,
because the repeat is visible and the drop is not.

The bound on retries exists for the same reason as the bound on the queues in
[0011](0011-process-shape-and-queues.md): a program that retries forever is one
whose memory grows until an outage becomes a kill, and the cause is no longer
visible by then.

The dedup key is the filter and the object rather than the object alone because
the filter is the question. Keying on the object alone would silently answer the
second question with the first question's notification.

## Alternatives rejected, and why

- Exactly once. It cannot be had across a third-party notification service.
  Pretending otherwise means writing a delivery record whose acknowledgement can
  be lost anyway, so the guarantee would be a word rather than a property. At
  least once with deduplication before delivery is the honest version of the
  same want.
- Deduplicating inside the notification service using its own identifiers. It
  works for one route and not for the others, and it makes a guarantee this
  project states depend on a service the operator can change without telling it.
- Silent discard when a route is down. A delivery that did not happen has to be
  visible the next morning, in a counter and in the log. This is the failure the
  whole contract exists to make impossible.
- Deduplicating after delivery, by suppressing the second copy at the route.
  Every route would need its own memory of what it had sent, which is three
  implementations of one property and three places for it to be wrong.
- Promising ordering. No route this project targets offers it, so the promise
  would be one this program could not keep even if it queued perfectly.

## What it costs

At least once means an operator will occasionally see the same object twice,
most often after a restart at a bad moment. That is what never losing one costs.
It is stated in the operator documentation rather than hidden, and
`notify.dedup.window` is the setting that trades between the two.

A fixed field set means a want that arrives later cannot be met by adding a
field to one route, which is the cheap thing to do and the thing that makes two
routes disagree. It has to be met by changing this decision, which supersedes
this file rather than editing it, and by changing every route at once.

No promised ordering means an operator reading two notifications cannot infer
which observation came first from the order they arrived in. The time of the
observation is one of the six fields for exactly that reason, and it is the
field to read instead.
