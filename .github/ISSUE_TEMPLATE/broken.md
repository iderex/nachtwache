---
name: Something is broken
about: A report that the program did the wrong thing
title: ''
labels: ''
assignees: ''
---

[Nothing about a suspected vulnerability belongs here. Close this and use the
private route in SECURITY.md instead.]

## What happened, and what you expected instead

[Both halves. A report with only the first is a description of the program.]

## The version

    $ nachtwache version

[Paste the output. It carries the version, the build and the schema versions
compiled in, which is usually the whole answer to a decode question. If there is
no release yet, write "no release" and the commit you built from.]

## The upstream in use

[Which upstream, and which channels you subscribed to. Write "none" if the
report does not involve the stream, which is the ordinary case for a report
about a filter file, `explain` or `replay`.]

## The configuration, with the secrets removed

[The relevant part, not the whole file.

Removing them: a configuration file here should never hold a secret in the first
place. `docs/decisions/0013-configuration-and-secrets.md` fixes that a secret is
referenced rather than written, as `env:NAME` or `file:/path`, and a reference is
safe to paste. If you find a literal token sitting in a secret position, that is
the thing to remove before pasting, and it is also a token to rotate, because it
has been on disk in a file you were about to share.]

## What you ran, and what it printed

[The commands, with their output. `nachtwache check` and `nachtwache explain`
are usually the two that say the most, and neither needs the network or a
credential.]
