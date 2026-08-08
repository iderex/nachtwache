# Upstream terms and attribution

The data this program reads is produced by somebody else, at great expense, and
published under terms and with acknowledgement obligations. Carrying those
correctly is part of being a good client, and getting them wrong is the sort of
mistake that closes a door for everybody.

Every statement below carries the source it came from and the date that source
was read. Where a question was asked and the answer was not found, the entry
says that instead of guessing, because a paraphrase of a licence is not a
licence and this is the document least able to afford one.

## The terms that govern the alerts themselves

The alerts come from the NSF-DOE Vera C. Rubin Observatory, whatever route they
reach this program by. A broker adds enrichment and a channel scheme on top, and
the packet underneath stays the observatory's.

The authority is the Rubin Data Policy, RDO-13, version 1.2.5, latest revision
2025-11-05, at <https://ls.st/RDO-013>, read on 2026-08-08. Four of its policy
statements decide what this project may do.

DPOL-301 fixes what the word public means there:

> The term public means that a data product can be shared with anyone, anywhere,
> worldwide. The term public does not mean that a data product is served publicly
> through any specific Rubin Observatory interface at any particular level of
> service.

DPOL-503 places the alert stream inside that:

> Alert Stream: The real-time alert stream is public. The contents of the alerts
> archive that records and stores all issued alerts is public; however, access to
> the LSST alert archive at the Rubin Observatory DACs will be restricted to LSST
> Users.

DPOL-505 is the one that decides the image stamps, which are the largest thing in
a packet and the thing an operator is most tempted to keep:

> All Prompt image data products are proprietary. This includes, raw images,
> processed single visit images, difference images, and template images. Only the
> image cutouts distributed in the alert stream and recorded in the alert archive
> are public.

So the cutouts inside a packet are public and carry the same permission as the
rest of it. The images they were cut from are not, and nothing in this program
may go and fetch one. That is a second reason for the position issue #11 is asked
to record, and it holds whichever way that decision goes, because it is about
where the bytes may come from rather than about whether they are carried.

The observatory says the same thing in its own words on the page that lists the
brokers, <https://rubinobservatory.org/for-scientists/data-products/alerts-and-brokers>,
read on 2026-08-08: the alert packets "are world public and have no proprietary
period".

Read together, those permit what this project does. An operator may receive
alerts, an operator may keep them, and an operator may pass one to somebody else,
because public in DPOL-301 is a permission to share with anyone worldwide rather
than a statement about which interface serves them.

### One thing the policy says that this repository has not reconciled

RDO-13 also carries this, in the discussion under DPOL-503:

> The complete alert stream will not be distributed directly to individual
> investigators, but rather will be delivered to a selected set of community
> brokers.

`README.md` in this repository says the stream is a public feed any registered
user can subscribe to directly, and
[0003](decisions/0003-upstream-and-adapters.md) already marks that route as
unverified here and assigns it to issue #51. The policy text and the readme
sentence are not obviously the same claim, and this document does not settle
which is current: the policy revision is dated before the stream began issuing
alerts, and a policy that has moved since would not show that from inside this
tree. Issue #51 is where the unsplit route is exercised, and it is where this
paragraph is either removed or turned into a correction of the readme. Nobody
should read the readme sentence as established until then.

## What a publication acknowledges

DPOL-306 asks for an acknowledgement, and says in its own discussion that the
minimum for a paper including proprietary or public LSST data acknowledges NSF
and DOE funding of Rubin Observatory and LSST science.

The observatory publishes the wording at
<https://citations.lsst.io/acknowledgements/>, read on 2026-08-08. An operator
who publishes something they found this way copies this and nothing more
inventive:

> This material is based upon work supported in part by the National Science
> Foundation through Cooperative Agreements AST-1258333 and AST-2241526 and
> Cooperative Support Agreements AST-1202910 and 2211468 managed by the
> Association of Universities for Research in Astronomy (AURA), and the
> Department of Energy under Contract No. DE-AC02-76SF00515 with the SLAC
> National Accelerator Laboratory managed by Stanford University. Additional
> Rubin Observatory funding comes from private donations, grants to universities,
> and in-kind support from LSST-DA Institutional Members.

The second statement on that page, the one beginning "This publication is based
in part on proprietary Rubin Observatory Legacy Survey of Space and Time (LSST)
data", is for proprietary data and is not what an alert is. It is named here so
that nobody copies it by mistake on the grounds that it mentions Rubin.

Whichever upstream delivered the alert is acknowledged as well, in its own
words, and each entry below carries them where they were found.

This project asks for no acknowledgement of its own and none is owed to it. It
adds nothing to an alert that anybody would cite.

## What this project redistributes

Nothing, by default. An operator's installation receives alerts and sends
notifications, and no path in it publishes anything to anybody.

The one exception is a recording committed to this repository so the suite can
replay it, which is what issue #20 is for. A recording is a redistribution of
alert data by the person who commits it, and it is bound by three rules:

- It names the upstream it came from and the entry in this document that permits
  it.
- A recording from an upstream whose terms do not permit it is not committed, and
  the suite uses a synthetic recording for that adapter instead.
- It is small, and it exists to prove a decode or an evaluation rather than to be
  an archive.

No recording is committed today:

    $ git ls-tree -r --name-only origin/main -- testdata test ; echo "exit=$?"
    exit=0

The listing is empty and the status is zero, which is git reporting that it
matched nothing rather than that it failed. So the second rule above has nothing
to check yet, and it is written now because the moment it is needed is the moment
somebody is already holding the file.

## What an alert is not

This belongs beside the terms rather than in a separate document, because the
two get quoted together and misquoting the second is how the first stops being
extended to anybody.

A detection is not a discovery. An alert says that something at this position
changed with respect to a template, which is a measurement and not a claim that
anybody has found a new object.

A classification flag is somebody else's model output and not a fact. Where an
upstream attaches one, it is that upstream's opinion, produced by a model with a
false positive rate that this repository has not measured and does not state.
[0003](decisions/0003-upstream-and-adapters.md) keeps enrichment inside the
adapter that received it for this reason, so that a flag stays attributable to
the party that produced it.

A notification from this program is a reason to look at something rather than a
result to cite. What it carries is fixed by
[0009](decisions/0009-the-notification-contract.md), and every field in it is
either copied from the alert or computed from the operator's own site.
[what-this-is-not.md](what-this-is-not.md) is where the same position is stated
at length.

## The upstreams

The candidates are the seven community brokers the observatory lists, plus the
unsplit feed, and which of them this project ships an adapter for is not settled.
[0003](decisions/0003-upstream-and-adapters.md) fixes the shape rather than the
name and records that the choice is entry 4 of issue #2. The entries below cover
every candidate rather than a shipped set, so that whichever way that entry is
answered the terms were read before an adapter was written and not after.

Every one of the seven requires an account. None is anonymous, and the
registration procedure and the credential shape differ between them.

### Babamul

Published by the California Institute of Technology and the University of
Minnesota. Read on 2026-08-08 at <https://github.com/boom-astro/babamul> and
<https://babamul.caltech.edu/>.

Registration is an account obtained at <https://babamul.caltech.edu/signup>. A
subscriber holds a Kafka username, a Kafka password and an API token, which the
published client reads from `BABAMUL_KAFKA_USERNAME`, `BABAMUL_KAFKA_PASSWORD`
and `BABAMUL_API_TOKEN`.

The acknowledgement asked for:

> The Babamul alerts broker and BOOM software infrastructure (du Laz et al. 2026)
> is co-developed by the California Institute of Technology and the University of
> Minnesota. This work acknowledges support from the National Science Foundation
> through AST Award No. 2432476 (PI Kasliwal; co-PI Coughlin) and leverages
> experience from the Zwicky Transient Facility (co-PIs Graham and Kasliwal).

The client library is published under the MIT licence. That is the licence of the
software and it says nothing about the alerts, which stay under the Rubin terms
above.

Redistribution of alerts received through Babamul is not addressed by any
document found on this route. A recording taken from it is therefore committed
only after that has been established, which has not been done here.

### Fink

Published by the Fink collaboration, funded by LSST-France and CNRS/IN2P3. Read
on 2026-08-08 at <https://fink-broker.org/> and <https://fink-broker.org/cite>.

The citation asked for is the white paper, Möller et al., "FINK, a new generation
of broker for the LSST community", MNRAS 501, 3272 (2021),
doi:10.1093/mnras/staa3602.

The acknowledgement asked for, for any work using Fink data or services:

> This work was developed within the Fink community and made use of the Fink
> resources. Fink is supported by LSST-France and CNRS/IN2P3.

Registration and redistribution are not addressed by either page above.

### Lasair

A collaboration between the University of Edinburgh and Queen's University
Belfast, supported by the UKRI Science and Technology Facilities Council as part
of the LSST:UK Science Centre. Read on 2026-08-08 at
<https://lasair.lsst.ac.uk/> and
<https://lasair-lsst.readthedocs.io/en/main/more_info/acknowledgements.html>.

The citation asked for is R. D. Williams et al., "Enabling science from the Rubin
alert stream with Lasair", RAS Techniques and Instruments 3, 362 (2024),
doi:10.1093/rasti/rzae024.

The acknowledgement asked for:

> Lasair is supported by the UKRI Science and Technology Facilities Council as
> part of the LSST:UK Science Centre and is a collaboration between the
> University of Edinburgh and Queen's University Belfast, funded by grants
> ST/X001334/1 and ST/X001253/1.

The documentation carries a section on a Lasair account and a section on alert
streams, and neither was read on this route. Registration and redistribution are
therefore not established here.

### ALeRCE

Read on 2026-08-08 at <https://alerce.science/>, which redirects to
<https://science.alerce.online/>, and on the same date at
<https://alerce.readthedocs.io/en/latest/>.

Neither carries terms. The site navigation read on that date lists an about page,
a services page with a submenu of the individual services, a publications page
and a news page, and no terms page and no citation page. The client documentation
read on the same date has installation, tutorial, migration, API reference and
support sections and no licence, terms, citation or account statement in any of
them.

So two routes were reached rather than none, and both are silent. Nothing about
terms, acknowledgement, registration or redistribution is established here, and
that is now a reading of two pages rather than a failure to open one.

### AMPEL

Read on 2026-08-08 at <https://ampelproject.github.io/> and, for the citation, at
<https://ascl.net/2005.015>.

The project site asks for one citation:

> Transient processing and analysis using AMPEL: alert management, photometry,
> and evaluation of light curves

J. Nordin et al., Astronomy and Astrophysics 631, A147 (2019). The Astrophysics
Source Code Library entry read on the same date names the same paper as the
preferred citation, by the bibcode `2019A&A...631A.147N`, which is why the paper
is recorded here from two sources rather than one.

Nothing else. No licence, no terms of use, no registration procedure and no
statement on redistributing what a subscriber receives appears on either page,
and [0003](decisions/0003-upstream-and-adapters.md) already records that the
observatory's own page carries no description of what AMPEL offers a subscriber.

### ANTARES

Operated at NOIRLab. Read on 2026-08-08 at <https://antares.noirlab.edu/>, which
is a browser application that served no readable text on that route, and at
<https://nsf-noirlab.gitlab.io/csdc/antares/client/acknowledgements.html>, which
did.

The acknowledgement asked for:

> The ANTARES project has been supported by the U.S. National Science Foundation
> through a cooperative agreement with the Association of Universities for
> Research in Astronomy (AURA) for the operation of NSF NOIRLab, through an NSF
> INSPIRE grant to the University of Arizona (CISE AST-1344024, PI: R.
> Snodgrass), and through a grant from the Heising-Simons Foundation.

The same page carries a second block for the survey ANTARES currently
distributes, which is ZTF rather than this observatory, so it is not copied here.
Whether it applies to a given publication depends on which stream the alerts came
from.

No citation requirement, no terms of use, no registration procedure and no
statement on redistribution appears on that page.
<https://noirlab.edu/science/about/scientific-acknowledgments> was requested on
the same date and returned nothing readable on this route, so what NOIRLab asks
for at the institutional level, above the client's own page, is not established
here.

### Pitt-Google

Read on 2026-08-08 at <https://mwvgroup.github.io/pittgoogle-client/> and
<https://github.com/mwvgroup/pittgoogle-client>. A third page,
<https://pitt-broker.readthedocs.io/en/latest/>, was read on the same date in the
earlier pass over these entries and carried nothing on this subject; it is named
here because it is what the entry pointed at before and is not re-read.

The client library is published under the BSD 3-Clause licence, declared in the
repository. That is the licence of the software and it says nothing about the
alerts, which stay under the Rubin terms above. The documentation carries a
copyright line and no more:

> Copyright 2021, The Pitt-Google Alert Broker Team

No citation requirement, no acknowledgement text, no terms of use, no
registration procedure and no statement on redistribution was found on any of the
three. It is the one candidate that is a library over a commercial cloud
platform, so a subscriber is likely to be creating an account with that platform
as well as with the broker, and that is a reading of the description rather than
something established here.

### The unsplit feed

Taken directly rather than through a broker. The terms are the Rubin terms at the
top of this document and there is no second party to acknowledge.

The access route is the open question rather than the terms. It is the
reconciliation named above, and issue #51 holds it.

## What stands behind this document today

A reader. Nothing in this repository refuses a change that contradicts an entry
here, nothing re-reads a source to see whether it moved, and nothing compares a
committed recording against the entry that is supposed to permit it.

Every date above is the date a page was read and not the date its terms were
last changed, and the second is not visible from here. A source that moved the
day after would leave this document saying exactly what it says now. Whoever
takes issue #51 re-reads all of them, because that is the issue where each
candidate is exercised against the interface and it is the cheapest moment to
find that an entry has gone stale.

One of the eight entries above establishes nothing at all, which is ALeRCE, and
that is now the result of reading two of its pages rather than of reaching
neither. Three more carry a citation or an acknowledgement and nothing else:
AMPEL, ANTARES and Pitt-Google each have a gap where the terms of use, the
registration procedure and the position on redistribution would be.

Not one of the seven brokers says what a subscriber may do with the alerts after
receiving them, and the eighth entry is the unsplit feed, where the answer is the
Rubin policy directly because there is no second party. That policy is at the top
of this document and it holds whichever broker delivers a packet, so what is
missing above is each broker's position on its own enrichment and its own
redistribution rather than the permission to have the alert. That gap is
the state of what was read and not a placeholder for work somebody is doing, and
it is written out so that an adapter is not built against an assumption that the
terms were checked.
