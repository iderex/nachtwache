# 0011. The process shape, and where work waits when a stage is slow

## What was decided

One process. Inside it, three kinds of stage:

- one consumer per subscribed channel, which reads from the upstream through the
  adapter interface fixed by [0003](0003-upstream-and-adapters.md) and does
  nothing else,
- one evaluation stage, which decodes a message and runs it against the filter
  set,
- one delivery worker per configured route.

Two queues connect them, and every queue has a capacity that is a setting with a
stated default and is never unlimited.

| Queue | Setting | Default | Policy when full |
| --- | --- | --- | --- |
| Consumers to the evaluator | `queues.evaluation.capacity` | 256 messages | the consumer stops reading |
| Evaluator to one route | `queues.delivery.capacity` | 64 notifications, per route | the newest notification is shed and counted |

The policy is chosen per queue rather than once for the whole program, because
the two positions want opposite things.

Between the consumers and the evaluator, a full queue means the consumer stops
reading. Pressure is pushed back to the stream, which is where it belongs and
where the upstream is built to hold it. Falling behind the stream is a real
consequence of that, and what happens then is the falling-behind decision's
answer rather than this one.

Between the evaluator and a route, a full queue means the notification is shed
and counted, and the count is a counter an operator can see rather than an
internal statistic. One slow route must not stop the other two and must not stop
the stream. Shedding is the newest rather than the oldest.

A stage that dies takes the process down. There is no supervisor inside the
process that quietly restarts a stage, because a program that is running and
doing three quarters of its job is one nobody notices is broken. The container
is expected to restart the process, which means the compose file this project
ships sets a restart policy and does not rely on the operator noticing. Restart
is cheap because the stream position in
[0005](0005-what-is-kept-on-disk.md) says where to continue, so the cost of
dying is a gap of seconds rather than a replayed night.

The two defaults are chosen to fit a small machine and they are chosen rather
than measured. 256 messages at the upper bound of roughly eighty kilobytes a
packet, which is the figure [0003](0003-upstream-and-adapters.md) carries with
its source, is about twenty megabytes held at rest in the worst case, and the
worst case needs every packet to carry its image stamps, which by default they
do not. A rendered notification is a few hundred bytes of text, so all the
delivery queues together are not the memory that decides anything. Nothing in
this repository has measured either figure. Issue #77 measures the footprint on
a named machine and publishes the numbers, and that is where these defaults are
confirmed or moved.

## Why

The kickoff asks for one container an operator brings up. What runs inside it,
and where work waits when one stage is slower than another, decides how the
program behaves on the night something goes wrong, which is the only night its
behaviour matters.

One process rather than several is sized to the work. On a normal night this
program handles a few hundred small messages a second, which is not an amount of
work that needs a deployment diagram.

Bounded queues are the whole of the memory story. The program's memory at rest is
the state directory's bounds plus these two capacities, and both are numbers an
operator can read and change. Nothing else in the program grows without a bound
somebody chose.

Dying rather than degrading is the same argument as fail-closed validation at
start. A visible stop is recoverable by a restart policy that already exists. A
silent partial failure is recoverable only by somebody noticing, and the whole
point of this program is that the person is asleep.

## Alternatives rejected, and why

- A process per stage, or a container per stage. It multiplies the deployment,
  the configuration and the failure modes for a program whose entire workload on
  a normal night fits in one process.
- Unbounded queues. They convert a slow route into an out-of-memory kill an hour
  later, on a machine with a small amount of memory, at which point the cause is
  no longer visible anywhere. This is the failure that both capacities exist to
  prevent.
- One queue policy for the whole program. Backpressure on a route queue stops
  the stream because one notification service is slow. Shedding on the evaluation
  queue throws away alerts the upstream would happily have held. Each policy is
  wrong in the other position.
- Dropping the oldest when a route queue is full. Old and new are equally
  valuable here, and the oldest is the one closest to being delivered. Shedding
  the newest is the honest version and it is the one that is counted.
- A supervisor inside the process that restarts a dead stage. It converts a
  visible failure into an invisible one, and the container runtime already does
  restarts properly and says that it did.

## What it costs

Backpressure to the stream means that if evaluation is slow, the client falls
behind. That is a real cost and it is deliberately pushed into a separate
decision rather than solved here by making the queue bigger.

Shedding on a route means an operator can lose notifications from a badly
configured route without the route ever failing. The shed count is therefore a
counter an operator can see and a log entry with the route named, and an
operator who does not look at either will not learn about it. That is the
residual risk this policy leaves.

Dying on a stage failure means one defect in one route's code takes the whole
program down, including the two routes that were working. The alternative was to
keep running with one route dead and not say so, and between a loud stop and a
quiet gap this project takes the stop.

The two capacities are settings, which means an operator can set them to
something unwise. A capacity large enough to hold a night of alerts reintroduces
the out-of-memory kill this decision rejected, and nothing here refuses that. The
start-time refusal for an obviously undersized configuration, which issue #46
asks for on the full-feed adapter, is the shape of the answer to the opposite
mistake, and no equivalent refusal exists for a capacity that is too large.
