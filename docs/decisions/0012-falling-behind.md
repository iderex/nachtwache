# 0012. What happens when the client falls behind the stream

## What was decided

The default is to keep up.

Lag is measured continuously and in two forms, because the two answer different
questions. The time lag is the host clock minus the timestamp of the message
being handled. The position lag is how many messages sit between the client's
position and the newest available one on that channel. Both are per subscribed
channel, both are exposed whichever mode is in force, and the threshold below is
on the time lag, because a duration is comparable between a channel that carries
a hundred messages a second and one that carries two.

When the time lag on a channel passes `stream.lag.threshold`, default 15
minutes, the client skips that channel forward to the newest available position.
It then counts exactly how many messages it passed over and logs one line naming
the channel, the count, and the timestamps at both ends of the gap. The count is
a number, not an estimate: it is the distance between the position it left and
the position it resumed at.

The alternative is a setting, `stream.lag.policy`, with two values and no
others. `skip` is the default and is the behaviour above. `follow` stays behind
and processes everything, arriving late. `follow` is the right answer for
somebody archiving matches and the wrong answer for somebody who wants to know
what is overhead now, and the default follows the person this project is written
for rather than the person with the more interesting use.

The threshold is a duration chosen rather than measured. Nothing in this
repository has measured what lag a small machine on a domestic connection
actually accumulates, and issue #50 is where the measurement happens and where
this default is confirmed or moved.

### The skip counter, and where it lives

The counter is per channel and it is not reset by a restart, because a client
that skipped a night, restarted, and reported zero is the failure this whole
decision exists to prevent.

It is carried inside the stream position record rather than in a place of its
own. [0005](0005-what-is-kept-on-disk.md) fixes what the state directory holds
and says that it holds those kinds and nothing else, and the position record is
already one small record per subscribed channel, bounded by construction and
overwritten rather than appended to. A counter and the timestamp of the last
skip are two more fields on a record that is written on exactly the occasions
this counter changes, so the bound in that file is unaffected and no fifth kind
of state appears.

### Where a client with no position starts

Two other decisions point here for this and it is answered in one place. A
channel with no position record, which is a first start or a start after an
operator deleted `position/`, begins at the newest available position rather
than the oldest. The program's promise is about what is overhead now, and a
first start that replays whatever the upstream still holds delivers a night of
notifications about objects that have set, which is the worst possible
introduction to it.

A position record that is older than what the upstream still retains is not an
error. The upstream resumes the client at the oldest position it has, the client
measures the resulting lag like any other, and the policy above decides what
happens next. That path is how a machine that was switched off for a week comes
back, and under the default it skips forward once, counts what it passed, and
says so.

### What the metrics surface owes

The M8 status and counters work, issue #74, has to expose these by name, and
they are named here so that the obligation is written down before the surface is
designed:

- the time lag per channel, as a duration,
- the position lag per channel, as a count,
- the skipped-message counter per channel, cumulative and surviving restarts,
- the timestamp of the most recent skip per channel.

The first two are the ones an operator watches to find out they are behind
before they wonder why nothing arrived. The last two are the ones that answer
what was missed, afterwards, in a number.

None of this is built. Issue #49 implements the stream position, issue #50
implements the lag measurement, the policy and the counting, and both are held
to this file.

## Why

A small machine on a domestic connection will sometimes fall behind: a slow
night for the network, a restart during a busy hour, a filter set that got
expensive, a week switched off. What the program does then is a decision, and
the wrong version of it is the one that is made by accident, by whichever
timeout or buffer size happened to be in the way.

Skipping rather than catching up follows from what a notification is for. A
notification about something that set two hours ago is worse than no
notification, because it is a false claim about the present that costs the
reader the time it takes to work out it is stale. The backlog after a long
outage can be an entire night, and delivering it is a program insisting on
telling somebody about last Tuesday.

Counting exactly is the part that is not negotiable. A client that quietly
discards a night and looks healthy leads an operator to conclude their filter is
too narrow when it is not, and they will then widen it, receive more, and never
learn what happened. The count and the time span are what turn a silent loss
into something an operator can state.

Measuring lag in both modes rather than only in the one that acts on it is the
same argument from the other side. An operator running `follow` who is six hours
behind has a program that is working perfectly and is useless to them, and the
only thing that can tell them is a number they can look at.

## Alternatives rejected, and why

- Never skipping, and always processing everything. It is the simplest rule and
  it turns every outage into a delayed replay of a night, at the wrong hour,
  about objects that have set. It is available as `follow` because it is right
  for somebody, and it is not the default.
- Skipping without counting. This is the failure the decision exists to prevent,
  and it is worth naming as a rejected alternative rather than leaving as an
  omission, because it is what a client does by default if nobody decides
  anything: the consumer simply resumes at the newest offset and nothing
  anywhere records that a gap happened.
- Counting but not persisting the count. A restart is the single most likely
  event to follow a long lag, so a counter that lives in memory is a counter
  that is reset by exactly the thing that most often produced it.
- Estimating the skipped count from the time span and an assumed rate. It is
  available where the positions are not comparable and it is a guess presented
  as a measurement, which is the one thing this project's own rules refuse
  everywhere else.
- Deciding automatically per filter, for example skipping for filters that
  depend on the horizon and not for others. It is a genuinely good idea and it
  makes the behaviour of a filter depend on a rule its author does not know
  about, so two filters in one directory would treat a backlog differently for
  reasons nobody remembers. If it comes back, it comes back as an explicit
  per-filter setting with its own decision superseding this one.
- Making the threshold a message count rather than a duration. A count means
  something different on every channel and changes meaning when the upstream
  splits or merges one, and an operator cannot convert it into the thing they
  care about, which is how old the notification will be.
- Starting a fresh client at the oldest available position. It is the friendlier
  default in a program that processes a queue of work and the wrong one in a
  program that reports on the sky, and it makes the first run the loudest one.

## What it costs

Skipping loses alerts that were never examined, and one of them will eventually
have been the interesting one. There is no version of this decision that avoids
that; there is only a version that admits it. The cost is paid honestly in the
count, the time span and the log line, so an operator can say what they missed
rather than guessing, and can switch to `follow` if their answer is that they
would rather have it late.

The counter lives in the position record, so deleting `position/` deletes the
skip history along with the resume point.
[0005](0005-what-is-kept-on-disk.md) lists what each deletion costs and its
entry for `position/` does not mention this, because the field is added by this
file rather than by that one. The two are read together until a decision
supersedes one of them.

`follow` is a supported mode that this project cannot make good. An operator who
chooses it and then falls a night behind will receive a night of stale
notifications, and the only thing standing between them and that is the lag they
were told to watch. Supporting a mode that is wrong for most people is a real
cost and it is preferred to refusing a use somebody legitimately has.

The threshold is a setting, so an operator can set it to something unwise. A
threshold of a week is `follow` with extra steps, and nothing refuses it. That
is the same residual [0011](0011-process-shape-and-queues.md) records for the
queue capacities, and it has the same answer, which is that the resulting lag is
visible.

Nothing here is refused or proven today. Issue #13's own definition of done asks
for the behaviour to be provable in the suite from a recording with no live
stream involved, and there is no suite in this tree and no recording in it. The
in-process upstream that misbehaves on demand, which is what such a proof runs
against, is issue #52. Until that exists this file states an intention and
nothing measures whether the program has it.
