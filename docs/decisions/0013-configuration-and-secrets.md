# 0013. Where configuration ends and secrets begin

## What was decided

Three separate places, and nothing crosses between them.

| Place | What it holds | Meant to be |
| --- | --- | --- |
| The daemon configuration file | the site, the upstream and its channels, the state directory from [0005](0005-what-is-kept-on-disk.md), the queue capacities from [0011](0011-process-shape-and-queues.md), and the routes | pasteable into a support request |
| The filter directory | one filter per file, nothing else | versioned and shared between operators |
| Secrets | credentials for the upstream and for the routes | never in either of the other two |

A secret is read from an environment variable, or from a file whose path is
named in the configuration. It is read from nowhere else, and in particular it is
never read out of the configuration file or out of a filter file.

The configuration accepts a reference to a secret and never the secret itself.
Two spellings, and only two:

    upstream.credential: env:NACHTWACHE_UPSTREAM_TOKEN
    routes.ntfy.token:   file:/run/secrets/ntfy-token

A value in a secret position that is neither spelling is refused at validation
rather than being taken literally. Taking it literally is how a configuration
file ends up holding a token that its author believed was a placeholder.

A filter file that carries a value shaped like a credential is refused at
validation too, and refused rather than warned about. A filter directory is the
thing this project most encourages an operator to put in version control and
hand to somebody else, so it is the place where a credential does the most
damage and the place where an operator is least expecting to have put one.

Every secret is redacted wherever it could be printed: the log, the text of an
error, the labels on a counter, and the output of the command that prints the
effective configuration. The redaction lives at the type that holds the secret,
which renders as a fixed placeholder in every formatting path, rather than at
each place something is printed. A print site added later cannot forget to
redact, because it never had the option.

Validation is fail-closed at start. The daemon reads the configuration and the
whole filter directory, validates both, and refuses to start if any part of
either is invalid. It does not start with the broken route disabled and it does
not start with the invalid filter skipped, which matches the die-rather-than-
degrade rule in [0011](0011-process-shape-and-queues.md) and is the same
argument: a program that starts successfully and does three quarters of its job
is one nobody notices is broken.

The same validation is available to an operator before a restart, as a verb that
takes the same configuration file and the same filter directory as the daemon,
prints the effective configuration with every secret redacted, and exits
non-zero on the first refusal:

    nachtwache config check

Where that verb sits in the whole command surface, and what it is finally
called, is issue #15 rather than this file. What this file fixes is that the
check exists, that it is the same code path the daemon runs at start, and that a
configuration an operator can validate without restarting is part of the design
rather than a convenience added later.

None of this is built or refused yet. Issue #34 carries the rule that refuses a
secret-typed value reaching a formatting or logging call, and issue #53 is where
the filter format and its refusals are built. Issue #14 is what both are held
to.

## Why

Filters are meant to be shared, kept in version control and copied between
operators. Credentials are meant to be none of those things. Two kinds of file
with opposite handling rules are safe only while nothing puts one inside the
other, and the way that stops being true is gradual: a route that needs a token,
a filter that needs a route, a token that ends up next to the filter because that
is where it was needed.

Separating them now is one decision. Separating them after an operator has
published a filter directory is a credential rotation and an apology.

The reference mechanism is what makes the separation survive contact with
support. The single most common way a token leaks in this class of program is a
person pasting a configuration file into an issue to ask why their setup does not
work. If the configuration file physically cannot contain a secret, that paste is
safe, and it is safe without the person having to remember anything at the moment
they are frustrated.

Redaction at the type rather than at the print site is the same argument in a
smaller place. Redaction applied per print site is correct until somebody adds a
print site, and the person adding the seventeenth log line is not thinking about
this file.

Fail-closed at start rather than a warning is decided by who reads the output.
Nobody watches this program start. A warning printed at startup is read the
following week, if the log is still there.

## Alternatives rejected, and why

- Credentials in the configuration file, which is what most programs of this
  kind do. It is why support requests in this field leak tokens, and it is why a
  configuration file cannot be committed even when everything else about it is
  worth sharing.
- Credentials as command line arguments. They appear in the process list of the
  machine and in the shell history of the person who typed them, and both are
  readable by things the operator was not thinking about.
- One file holding configuration, filters and secrets. It is the shortest thing
  to explain in a quickstart, and it makes the one file an operator most wants to
  share the one file they must never share.
- Warning rather than refusing an invalid configuration, or starting with the
  broken part disabled. Covered above. It produces a program that is running,
  reports itself healthy, and is not doing the thing it was installed for.
- Detecting a leaked credential after the fact by scanning the log for it. The
  secret is already on disk by the time the scan runs, and the scan has to hold a
  copy of the secret to look for it.
- A secrets manager as a dependency. It is the right answer at a scale this
  program does not operate at, and it adds a service to a deployment whose whole
  premise is one container on a small machine. An environment variable and a file
  path are what the container runtime this project targets already provides.

## What it costs

Three places to look instead of one, which is more to explain to the person the
quickstart is written for. The quickstart pays it by showing the whole thing as a
compose file with an environment file beside it, which is the shape that operator
has already seen.

The refusal of a credential-shaped value in a filter file is a heuristic, and it
is wrong in both directions. It will occasionally refuse a value that was not a
credential, and the escape from that is to move the value rather than to switch
the check off. More importantly it will pass a credential it does not recognise,
because the shapes it knows are the shapes somebody thought of. It is a floor and
not a guarantee, and an operator who publishes a filter directory is still the
person responsible for what is in it.

Redaction at the type protects only values that were given the type. A secret
read into an ordinary string somewhere in the program is redacted by nothing,
and the type discipline that would prevent that is a rule about how the code is
written rather than a property of it. Issue #34's rule refuses the print, not the
choice of type, so the gap between them stays open and is worth stating rather
than assuming away.

Fail-closed at start means one typo in one route stops the whole program,
including the two routes that were fine and the stream that was reading
correctly. That is the trade taken deliberately, and the validation verb above is
what makes it survivable: the cost falls on somebody who is awake and looking at
the output rather than at four in the morning.

Reading a secret from a file named in the configuration means the configuration
still points at something sensitive, so a configuration file discloses where the
credentials are kept even though it never holds one. That is a smaller leak than
the credential and it is not nothing, and it is the price of a mechanism that
works with the file-based secrets a container runtime already supplies.
