# 0005. What the client keeps on disk, and what it never writes down

## What was decided

One state directory, named by one setting, `state.dir`. Everything this program
writes goes inside it, and it holds four things and nothing else.

| Kind | Directory | Default bound | Enforced by |
| --- | --- | --- | --- |
| Stream position | `position/` | one record per subscribed channel | construction |
| Deduplication record | `dedup/` | 14 nights or 32 MB, whichever is reached first | code |
| Delivery record | `outbox/` | 16 MB, and the retry bound from the notification contract | code |
| Matched-alert archive | `archive/` | off; when on, 7 nights or 512 MB | code |

The stream position is one small record per subscribed channel, so a restart
continues instead of replaying a night or skipping one. It is bounded by
construction: the number of records is the number of channels the operator
subscribed to, and a record is overwritten rather than appended to. It has no
configured bound because there is nothing for one to hold back.

The deduplication record is keyed by filter and by object, so one transient does
not produce forty notifications. It is bounded by age and by count. The count
bound is expressed to the operator as a size, because nobody has an intuition
for how many records fit in a shed.

The delivery record holds notifications that have not yet been acknowledged by
their route, so a route that was down does not lose what it owes. An entry
leaves when its route acknowledges it or when the retry bound in the
notification contract is reached, whichever comes first, and the size bound is
the backstop for a route that is down long enough for both to be slow.

The archive of matched alerts is off by default. Switched on it holds alerts
that a filter matched, and nothing else, bounded by both age and total size.

Every bound is enforced in code at the point of write. None of them is a number
in the documentation that an operator is trusted to respect, and none of them is
checked only at start. Where a write would cross a bound, the oldest entries are
removed first and the removal is counted and logged rather than being silent.

The defaults above are chosen to fit a small machine and they are chosen rather
than measured. Nothing in this repository has measured what this program holds
at rest. Issue #77 measures the footprint on a named machine and publishes the
numbers, and that is where these defaults are either confirmed or moved.

The full stream is never written to disk, and nothing that failed to match a
filter is retained at all, with one exception: a bounded sample of the messages
that failed to decode is kept under `decode-failures/` inside the state
directory, bounded at 64 messages or 8 MB and 7 nights, whichever is reached
first, so that a decoder defect can be diagnosed from the thing that actually
arrived. What is eligible for that sample and what is stripped from a message
before it is written there is fixed by the alert decoding decision. The bound is
fixed here because this file is where what sits on the disk is decided.

### Deleting one of them

The four are independent, and an operator can delete any one directory while the
program is stopped without breaking the others. What each deletion costs:

- `position/`. The next start has no place to continue from, and where the
  stream resumes is the falling-behind decision's answer rather than this one.
  Nothing else in the directory refers to these records.
- `dedup/`. Objects that were already notified about can be notified about
  again, once each, until the window refills. No other kind of state refers to
  it.
- `outbox/`. Notifications that were accepted for delivery but not yet
  acknowledged are lost, and lost silently, because the record that would have
  reported them is the one that was deleted. This is the one deletion with a
  cost the program cannot tell the operator about afterwards.
- `archive/`. The archive is gone. Nothing else reads it.

Backing up the state directory is therefore the whole backup procedure, and
restoring it is a copy.

None of this is built yet. Issue #73 is where the directory, the bounds and the
upgrade path are implemented, and this file is what that work is held to.

## Why

A program that watches a stream this size has to be explicit about what it
writes down, because the naive answer fills a disk in one night and the disk
belongs to somebody who was not warned. The decision that fixes the stream shape
puts roughly eight hundred gigabytes a night through the unsplit feed, and even
the pre-split shape is more than a small machine should be asked to keep.

The four kinds are not an arbitrary set. Each one exists because the program
makes a promise that cannot be kept without it: continue after a restart, do not
ring forty times for one object, do not lose what a route has not yet taken, and
let an operator look at last week if they asked for that. Nothing else the
program does needs to survive a restart, so nothing else is written.

Bounds in code rather than in documentation is the same argument in a smaller
place. An unbounded directory in a shed is a failure that arrives silently, in
February, as a full filesystem, and the operator who would have run a retention
policy for a hobby does not exist.

## Alternatives rejected, and why

- A database server as a dependency. It doubles the container count and the
  backup story for a program whose whole state at rest is a few tens of
  megabytes.
- Keeping everything and letting the operator clean up. This is the shed and the
  full filesystem above. It moves a foreseeable failure onto the person least
  placed to see it coming.
- Keeping no state at all and re-deriving from the stream. The stream is not
  replayable that far back, and a program that forgets what it has already told
  you is one you stop trusting.
- Bounding by record count and telling the operator the record count. It is a
  number nobody can convert into a decision about a disk, so it reads as
  precision and functions as noise.

## What it costs

Bounds mean deliberate loss. An operator who wanted the whole night's matches
and did not raise the archive bound will find the oldest ones gone, so the bound
and the deletion are both visible in the counters and in the log rather than
being quiet. That visibility is the cost of the bound being real.

One state directory is only the whole backup procedure while nothing writes
outside it, and nothing in this program stops a later change from doing exactly
that. Holding that line is a check in M2 rather than a promise in this file.

The exception for decode failures is a place where bytes that matched no filter
are kept. It is small and it is bounded, and it is still the one hole in the
sentence above, which is why it is written into the sentence rather than kept
somewhere else.
