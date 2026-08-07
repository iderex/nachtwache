# nachtwache

Since early 2026 the Rubin alert stream is a public Kafka feed any registered user can subscribe to directly. Seven brokers process it and all seven are web platforms with an account and a browser interface. This is the self-hosted variant: a Docker container, filters as versioned config files, notification by ntfy, Matrix or webhook. The gap is packaging and not science, and the plan says so.

It is not a broker and it is not a discovery pipeline. It processes
nothing the upstream did not already process, adding no classification,
no cross-match and no model of its own, and a notification it sends is a
reason to look at something rather than a claim about what that thing is.
[docs/what-this-is-not.md](docs/what-this-is-not.md) carries those two
alongside the three other things this project does not claim.

Planning happens on the issue tracker first. Every decision that shapes
the architecture is written down there with its reasons before the code
that depends on it exists.

See [NOTICE.md](NOTICE.md) for the intended-use notice.
