# nachtwache

Since early 2026 the Rubin alert stream is a public Kafka feed any registered user can subscribe to directly. Seven brokers process it and all seven are web platforms with an account and a browser interface. This is the self-hosted variant: a Docker container, filters as versioned config files, notification by ntfy, Matrix or webhook. The gap is packaging and not science, and the plan says so.

Planning happens on the issue tracker first. Every decision that shapes
the architecture is written down there with its reasons before the code
that depends on it exists.

See [NOTICE.md](NOTICE.md) for the intended-use notice.
