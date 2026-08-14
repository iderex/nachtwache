# Security policy

## Reporting a vulnerability

Report privately, through GitHub's private vulnerability reporting on this
repository:

    https://github.com/iderex/nachtwache/security/advisories/new

That route is open. It was checked rather than assumed:

    $ gh api repos/iderex/nachtwache/private-vulnerability-reporting
    {"enabled":true}

Do not open a public issue, a discussion or a pull request for a suspected
vulnerability. A public issue tells everybody, including the people running this
unattended on a home network, before there is anything for them to update to.

If the private route is unavailable to you, write to nils.lehnen@proton.me, which
is the address published on the maintainer's GitHub profile. Encrypt it if you
can. An unencrypted mail is still better than a public issue.

## What a reporter can expect

This project has one maintainer, so the times below are what one person can hold
and not what a team would promise. They are chosen rather than measured, since
nothing has been reported yet and there is no history to derive them from.

An acknowledgement that the report arrived, within seven days. If seven days pass
with no answer, the report has not reached anybody, and the second route above is
the one to use.

An assessment saying whether the report is accepted, and if it is, what the
maintainer thinks it affects, within fourteen days of the acknowledgement.

Where a report is accepted, a fix or a written reason why there will not be one.
Where it is declined, the reason, in enough detail to argue with. A report
declined because the behaviour is intended gets pointed at the decision file that
made it intended, or gets that file written.

Credit in the advisory under whatever name you ask for, or no credit if you
prefer that. Nothing is published about a reporter that the reporter did not
agree to.

Coordinated disclosure, with the timing agreed with the reporter rather than
fixed here. If no agreement is reached and the finding is being exploited, the
maintainer will publish rather than sit on it.

## Which versions get fixes

The default branch, and nothing else. There is no release yet:

    $ gh api repos/iderex/nachtwache/releases --jq 'length'
    0
    $ gh api repos/iderex/nachtwache/tags --jq 'length'
    0

Issue #89 is the first release an operator can run, and issue #84 is where the
versioning policy is decided. Once there is a release, the paragraph here will name which
released versions receive fixes, and it will be a small number of them and never
all of them.

## What is in scope

This program reads an untrusted stream, unattended, on somebody's home network,
and it holds credentials for the services it notifies through. That shapes the
list.

Anything reachable from the alert stream. The decoder and the filter parser are
named here explicitly, because they are the two places where bytes from outside
become structure inside. A malformed message that panics the process, exhausts
memory, or is decoded into a different alert from the one that arrived is a
vulnerability and not a robustness bug.

Anything that lets a secret out. A credential in a log line, in an error message,
in the output of the command that prints the effective configuration, in a
counter label, or in a notification body is in scope. So is a credential written
anywhere inside the state directory.

Anything that lets the operator's own data out. The site coordinates, the quiet
hours, the notification endpoints and the filters describe a person and their
home. A path that sends any of those anywhere the operator did not configure is
in scope, and so is a request to a host that is not on the configured allowlist.

Anything that lets somebody else's traffic in. An unauthenticated endpoint that
this program listens on, a route that accepts a payload it did not ask for, and a
webhook signature that can be forged are all in scope.

Anything about the container as it is published. Running as root, a writable root
filesystem, a shell where none is needed, or an image whose contents do not match
what the build says it built.

Anything that makes a notification lie. A notification that names an object other
than the one that matched is in scope, because the whole point of this program is
that somebody acts on it at two in the morning.

The workflow files in this repository are in scope. They are the supply chain of
anything that is ever published from here.

## What is out of scope

The upstream alert stream and the brokers, which belong to the projects that run
them and have their own reporting routes. A report about their content or their
availability is not a report about this program.

The notification services, which belong to whoever runs them. What this program
sends to them is in scope; what they do with it afterwards is not.

An operator's own configuration. A filter that matches everything, an archive
bound raised past the disk, or an endpoint pointed somewhere the operator did not
intend are all things the operator did, and the answer to them is documentation.
A configuration that cannot be written safely because the program offers no safe
option is a different thing and is in scope.

Findings that need an attacker who already has the operator's machine. If a
report starts from a shell on the host, the host is already lost.

Reports produced entirely by a scanner, with no reasoning about whether the
finding reaches anything here. A dependency advisory against a code path this
program does not call is worth reporting and is a dependency-hygiene matter
rather than a vulnerability report; the section below is what happens to it.

## Known vulnerable dependencies

A dependency with a known advisory is treated on this schedule, counted from the
moment it becomes known here rather than from the moment it was published. These
are the windows the release side of this project is held to, and issue #32 is the
check that finds them on every change rather than weekly.

A finding that is reachable from an alert message or from a credential path gets
a fix or a documented mitigation within seven days.

A finding that is reachable only from a path an operator has to configure
deliberately gets one within thirty days.

A finding that is not reachable from any path this program calls is recorded with
that reasoning and is not a release blocker. The reasoning is written down, so
that it can be wrong in public rather than in somebody's memory.

Where no fix exists upstream, the record says so and says what the mitigation is,
and the finding stays open rather than being closed as unfixable.

## What this policy does not do

It does not certify anything, and it is not a warranty.

It does not carry the warranty and liability position either, and today nothing
in this repository does. [NOTICE.md](NOTICE.md) defers that position to the
license, and there is no license here:

    $ git ls-tree HEAD LICENSE LICENSE.md COPYING ; echo "exit=$?"
    exit=0
    $ gh api repos/iderex/nachtwache --jq '{license: .license}'
    {"license":null}

The listing above is empty and the exit status is zero, which is `git ls-tree`
reporting that it matched nothing rather than that it failed. The field is asked
for inside an object because `--jq '.license'` on a null field prints an empty
line, and an empty line is not readable as an answer. So the chain a reader
follows to find the warranty position runs from here to `NOTICE.md` to a file
that is not in the tree.

What follows from that absence is larger than a warranty disclaimer, and
[GOVERNANCE.md](GOVERNANCE.md) states it: with no license the default is
exclusive copyright, so nobody may legally run, modify or redistribute this.
Entry 1 of issue #2 is where that is answered and issue #82 is where the answer
is applied. Until then this section says what is true rather than pointing at a
document that would say it.

It does not promise that anybody is watching the private route at three in the
morning. One maintainer is one maintainer, and
[GOVERNANCE.md](GOVERNANCE.md) says what that means and what happens if that
person stops.
