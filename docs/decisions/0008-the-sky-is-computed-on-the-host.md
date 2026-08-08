# 0008. The sky is computed on the host, with a stated accuracy

## What was decided

The conversion from a catalogue position to an altitude and an azimuth for the
operator's site happens on the operator's machine, inside this program, with no
network call and no ephemeris downloaded at runtime. Everything the computation
needs is compiled into the binary or is in the configuration.

The site is three numbers in the configuration: latitude, longitude and
elevation. Horizon obstructions, where an operator has given them, are
configuration as well and are not part of this model; they are a mask applied to
the altitude this computation produces. The evaluation context in
[0007](0007-what-a-filter-can-see.md) carries the site and one instant, and
those two with the alert position are the whole input.

The accuracy target is one arcminute in altitude and in azimuth, over the range
of dates this program will plausibly run. It is far below what the question
needs, because nobody points a telescope at something two degrees above a
treeline and a filter written against a horizon limit is not sensitive to an
arcminute. It is high enough that the implementation cannot be sloppy in a way
that hides a real error, which is the reason for choosing a target well past
what is needed rather than one that matches it.

The target is on the geometric altitude. Refraction is applied on top of it and
carries its own uncertainty, which is stated below and is larger than the
target near the horizon.

### What the model includes

Each of these is included because leaving it out would move the answer by more
than the target.

- Diurnal rotation, through sidereal time at the site's longitude. This is the
  whole computation and omitting it is not an option. It also fixes an
  assumption about the host: the Earth turns roughly 15 arcseconds of arc per
  second of time, so a host clock four seconds out is already at the target and
  the program's accuracy claim rests on the operator's clock being
  approximately right.
- Precession of the equinoxes, which moves the reference frame by roughly 50
  arcseconds a year. It passes the target within about a month and is the
  largest omitted effect if it is omitted.
- Nutation, at up to roughly 17 arcseconds in longitude. It sits below the
  target on its own and it is cheap once precession is being computed, and the
  two together are the difference between a mean and a true frame, which is a
  distinction worth not getting subtly wrong.
- The elevation of the site, through the dip of the geometric horizon. At any
  elevation worth writing down the dip is minutes of arc rather than seconds,
  and an operator on a hill has a lower horizon than one in a valley.
- Topocentric parallax for the Moon, which is the one body where it is large.
  The Moon's horizontal parallax is close to a degree, roughly sixty times the
  target, so a geocentric Moon would be wrong by more than the whole error
  budget in exactly the conditions the moon distance question is asked in.

### What the model omits

Each of these is omitted because it is below the target, with the line that says
so.

- Annual aberration, at up to roughly 20 arcseconds, which is a third of the
  target.
- Diurnal aberration, at well under an arcsecond.
- Topocentric parallax of the Sun, at roughly 9 arcseconds, so the Sun's
  altitude for the twilight question is computed geocentrically.
- Topocentric parallax of an alert position. An alert position is treated as a
  direction at infinity. That is correct to far below the target for everything
  outside the solar system, which is what this program is for, and it is the
  case the implementation covers. For an alert on a solar system object it is
  wrong by the object's diurnal parallax, which is seconds of arc at main-belt
  distances and can pass the target for something close to the Earth. That is a
  stated limit rather than a hidden one, and it is not corrected because a
  correction needs a distance the alert does not reliably carry.
- Polar motion, the difference between UT1 and UTC, gravitational light
  deflection, and the proper motion of the object. Each is well under the target
  for this purpose, and the last one has no meaning for a transient.

### Refraction

Refraction is applied with a standard model and the documentation says which
one and at what assumed temperature and pressure. It is applied because at two
degrees above the horizon it is worth roughly a third of a degree and at the
horizon itself roughly half a degree, both far larger than the target, so an
unrefracted altitude near the horizon is the wrong number for the question being
asked.

It is also the one place where the target cannot be met and the file says so
rather than implying otherwise. Real refraction near the horizon depends on the
temperature profile of the air above the operator, which this program does not
know and will not ask for. The model is therefore correct to a few arcminutes
low down, not to one, and an operator whose filter turns on the difference
between two and three degrees of altitude is relying on something this program
cannot promise. Above roughly ten degrees the model's own uncertainty falls
below the target and the stated accuracy holds again.

### Where it is held to that

Issue #56 is the validation. It checks the implementation against published
reference values across a spread of dates, sites and declinations, with the
tolerance stated and the reference set committed to the tree, and it is what
turns the target above into something that has been measured rather than
intended. Issue #57 is where darkness, the moon and the operator's hours are
built on top of it. Until #56 exists, every number in this file is a target and
none of them is a measurement.

### The site never leaves the host

The three numbers that describe where the operator stands are read from their
configuration, used in this computation, and sent nowhere. No position is
resolved by a service, no rise or set time is fetched, and no ephemeris request
carries a location. That is a consequence of computing on the host rather than a
separate promise, which is why the two are in one file.

The same sentence is carried for a different reason by the data protection
section, where it is a statement about personal data rather than about a
dependency: a home observer's coordinates are their home address to within a few
metres. That section does not exist yet. Issue #80 writes it and issue #79
carries the enforcement of the wider rule that nothing about the operator leaves
the host unless they configure it to, including the command in issue #83 that
prints every address a configuration will contact.

## Why

The question this project exists to answer is whether something interesting is
overhead right now. Overhead is a property of the observer and not of the alert,
so somewhere a catalogue position has to become an altitude above a particular
horizon. There are only two places that can happen, this machine or somebody
else's, and everything else in this decision follows from which one is chosen.

Computing it here removes a network call from the path at the hour the program
is least able to tolerate one. It removes a third party from the operator's
sleep, and it removes a third party who would otherwise learn the operator's
coordinates, their observing hours and which objects they care about, which is
a profile nobody needs to hold.

The accuracy target is set by what makes an error visible rather than by what
the question needs. A target of one degree would be met by an implementation
with a sign error in nutation, a wrong epoch or an hour angle computed from the
wrong meridian, and none of those would show up until somebody was standing
outside pointing at nothing. One arcminute is tight enough that the usual
mistakes fail the validation immediately, and loose enough that the
implementation stays a bounded piece of arithmetic instead of a project.

Stating what is omitted matters as much as stating the target. An accuracy claim
with no error budget behind it is a number somebody wrote down, and the list
above is what makes it checkable: a reader can add up what was left out and see
that the sum is inside the claim.

## Alternatives rejected, and why

- Asking a web service for rise and set times or for an altitude. It is a
  network call at the hour it is least available, it is a third party learning
  the operator's coordinates and interests, and it makes the program's core
  question depend on somebody else's uptime and terms. It fails exactly when it
  is needed.
- Downloading an ephemeris at runtime. Smaller than a service call and the same
  shape: a dependency that has to be reachable, that has to be trusted, and that
  turns a computation into an outage.
- Precomputing a table per site and shipping it. It moves a small computation
  into a large artefact that goes stale, it has to be regenerated whenever a site
  changes, and a table is much harder to check against a reference set than a
  function is.
- Importing a full astronomical library. There is no such thing in this
  toolchain without adding a dependency for one bounded computation, which
  [0002](0002-language-and-toolchain.md) records as a known cost of the language
  choice rather than a surprise. A library would also arrive with an accuracy
  nobody in this project had stated.
- Skipping the horizon entirely and notifying on everything a filter matched.
  This is the alternative that is actually tempting, because it is no work. It
  is what makes a notification useless at eleven at night, when a good part of
  what matched is below the ground.
- A higher target, say one arcsecond. It costs a much more careful
  implementation and a much larger reference set, to answer a question that
  cannot tell the difference, and it would be a claim about refraction that the
  section above shows cannot be kept.

## What it costs

This is the one piece of astronomy in the project written by hand rather than
imported, and it is a direct consequence of the language decision in
[0002](0002-language-and-toolchain.md). It is paid for with issue #56, which is
a real piece of work: a committed reference set, a spread of dates and sites,
and a stated tolerance.

The accuracy claim rests on the operator's clock, and nothing in this program
checks it. A host that has drifted by a minute produces answers that are wrong
by a quarter of a degree with no indication that anything is wrong. That
assumption is stated here and the ordinary mitigation, a time synchronisation
daemon, is the container host's business rather than this program's.

Refraction near the horizon is outside the target and no configuration will fix
that. An operator can raise their horizon limit to a few degrees and be entirely
unaffected, and one who insists on the lowest possible limit is relying on a
model with weather in it.

A solar system alert has an uncorrected parallax. It is small for almost
everything the stream carries and it is not zero, and the honest version is the
one written above rather than a promise the implementation does not keep.

None of this is built and nothing refuses it. There is no code in this tree, so
the model described here is a specification issue #56 will hold something to,
and today it holds nothing.
