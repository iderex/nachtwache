# Governance

This document says who holds access, how a decision gets made, and what happens
to this project if the person holding it stops. For a program people leave
running for years on a machine in a shed, the last of those three is part of the
security position rather than paperwork.

## Who holds access

One person, and nobody else:

    $ gh api repos/iderex/nachtwache/collaborators --jq '.[] | "\(.login) \(.role_name)"'
    iderex admin
    $ gh api repos/iderex/nachtwache --jq '{owner: .owner.login, owner_type: .owner.type, archived, fork, forks_count}'
    {"archived":false,"fork":false,"forks_count":0,"owner":"iderex","owner_type":"User"}

The repository sits under a personal account rather than an organisation, so
there is no second administrator and no organisation owner who could recover it.
Whoever holds that account holds this project completely.

The branch protection holds for that person too. The bypass list on the ruleset
is empty, which is the output quoted in [CONTRIBUTING.md](CONTRIBUTING.md), so
`main` takes a pull request from the maintainer exactly as it takes one from
anybody else. That is a check against a bad afternoon rather than against a bad
actor: somebody with admin can change the ruleset. What it does mean is that
changing it leaves a trace.

## How a decision gets made

Three kinds, and they are decided in three different places.

Something that shapes the architecture becomes a numbered file under
`docs/decisions/`, written before the code that depends on it, saying what was
decided, why, which alternatives were rejected and for what reason, and what the
decision costs. The cost section is where an unexamined decision shows itself. A
decision that turns out wrong is not edited: a new file supersedes it by number
and names the file it replaces, and the old one stays in the tree saying what
replaced it. Issue #1 is where the form of those files lands.

Something that belongs to the maintainer rather than to whoever reaches it first
is collected in issue #2, which states the options and what each one costs and
decides nothing. Work that depends on an unanswered entry there is blocked by it
and says so in its own body. The license is entry 1 and is the one the section
below is about.

Everything else is decided in the issue it belongs to, by argument, with the
evidence in the issue. Anybody can make the argument. In practice the maintainer
decides, because there is currently nobody else, and that is the honest
description rather than the flattering one.

Whether contributions from outside are accepted at all, and what a contributor
has to demonstrate, is entry 7 of issue #2 and is not answered yet. Until it is,
a pull request from outside gets read and argued with on its merits, and nobody
should read that as a promise that it will be merged.

## What happens if the maintainer stops

The uncomfortable answer first. Today, nothing can happen, because nobody else is
allowed to continue it:

    $ gh api repos/iderex/nachtwache --jq '.license'
    null

With no license file, the default is exclusive copyright. Nobody may legally run,
modify or redistribute this, which means a fork is not available as a continuity
plan, and an operator who has it running has no right to keep it working. That is
the largest single risk to anybody depending on this program, it is larger than
any defect in it, and it is fixed by answering entry 1 of issue #2 and applying
the answer in issue #82.

Once a license exists, the plan is the ordinary one for a project this size and
it is deliberately unambitious. The license is what makes a fork possible, and a
fork is the continuity plan. There is no foundation, no succession agreement and
no second person with the keys, and this document does not invent any of them.

What the project does to make a fork worth having, rather than a copy of
somebody's abandoned tree:

Decisions are in the repository rather than in the maintainer's head, which is
what `docs/decisions/` is for. Somebody picking this up should be able to find
out why a thing is the way it is without asking anybody.

Planning is on the issue tracker in public, with the evidence in the issues, so
the state of the work is readable by somebody who was never here.

State on an operator's disk is one directory with a documented layout and stated
bounds, described in
[docs/decisions/0005-what-is-kept-on-disk.md](docs/decisions/0005-what-is-kept-on-disk.md).
An operator whose upstream project disappears still has their own data in a shape
somebody else can read.

If the maintainer stops without saying so, the visible signs are the ordinary
ones: no commits, no answers on the tracker, and no response on the security
route within the seven days [SECURITY.md](SECURITY.md) states. Nobody will send a
notice, because there is nobody to send it.

## Changing this document

Like everything else here, through an issue and a pull request. If the answer to
any of the three questions above changes, in particular if a second person gets
access or an organisation takes ownership, this document changes in the same
change rather than afterwards.
