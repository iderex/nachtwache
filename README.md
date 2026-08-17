# nachtwache

Since early 2026 the Rubin alert stream is a public Kafka feed any registered user can subscribe to directly. Seven brokers process it and all seven are web platforms with an account and a browser interface. This is the self-hosted variant: a Docker container, filters as versioned config files, notification by ntfy, Matrix or webhook. The gap is packaging and not science, and the plan says so.

It is not a broker and it is not a discovery pipeline. It processes
nothing the upstream did not already process, adding no classification,
no cross-match and no model of its own, and a notification it sends is a
reason to look at something rather than a claim about what that thing is.
[docs/what-this-is-not.md](docs/what-this-is-not.md) carries those two
alongside the three other things this project does not claim.

Nothing about the operator, their site, their filters, their notification
endpoints or the alerts they received leaves their host, unless the operator
deliberately configures a destination that receives it. There is no telemetry,
no crash reporting, no update check, no analytics and no default endpoint owned
by this project.

[docs/data-boundary.md](docs/data-boundary.md) names the three things that do
leave when they are configured, what each other party learns from them, and what
refuses a fourth once there is code to refuse it in.

The alerts belong to the observatory that publishes them, and an operator who
publishes something they found this way acknowledges it.
[docs/upstream-terms.md](docs/upstream-terms.md) carries the terms per upstream
with the date each was read, the acknowledgement text ready to copy, and what an
alert is not.

Planning happens on the issue tracker first. Every decision that shapes
the architecture is written down there with its reasons before the code
that depends on it exists.

See [NOTICE.md](NOTICE.md) for the intended-use notice.

## License

AGPL-3.0, copyright 2026 Nils Lehnen.

The full text is in [LICENSE](LICENSE).
