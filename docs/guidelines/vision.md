# Vision — dual-home-cloudwan-test

## Summary

Organizations rolling out infrastructure changes rarely cut over all at once — there's
usually an old setup, a current one, and a next one on the way, with a transition
period where consecutive generations need to talk to each other. This project tests
whether we can connect those generations on AWS in a way that's fully compartmentalized:
each connection between two generations is its own isolated pathway, so a problem
on one connection can never spill over onto another, and generations that aren't
adjacent (the oldest and the newest) never have a direct line to each other at all.

We simulate this with three environments standing in for successive deployment
generations — `old-deploy`, `current-deploy`, and `future-deploy` — where
`current-deploy` is the bridge: connected to both its predecessor and its successor,
each connection kept fully independent of the other.

## Actor

- **Network Operator** — sets up the infrastructure and verifies that connectivity
  works where it should, and stays isolated where it should.

## Objectives

- Confirm that the old and current generations can reach each other reliably.
- Confirm that the current and future generations can reach each other reliably.
- Prove that the two connections are truly independent: a failure or change on one
  cannot affect the other.
- Keep new connections low-touch — no manual approval step for connecting a new
  environment in.
- Apply a consistent labeling/tagging approach across all resources, so ownership
  and environment are always clear.

## Non-goals

- No real application runs in any environment — this is a connectivity test, not a
  product deployment.
- Single test environment only — no production rollout as part of this effort.
- No direct connection between the oldest and newest generations — that gap is
  intentional and central to what this project is proving out.
- No fallback to older connectivity approaches (e.g. simple network peering) — this
  project is specifically about validating the newer, segment-isolated approach.
