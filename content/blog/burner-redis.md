+++
title = "Agents Need Rails"
date = "2026-05-10T12:00:00-05:00"
tags = ["ai", "agents", "redis", "rust", "testing"]
description = "I had an agent build a Redis-compatible backend, and the tests, interfaces, and prior art did most of the steering."

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

If you'd asked me a year ago whether I'd ever ship a library without reading every line of its source code, I would have clutched my pearls and spluttered indignantly. Shipping a black box gets engineers paged at 3am, gets companies on the front page of Hacker News (for the wrong reasons), and earns you a reputation as a slop cannon. Reading the source is part of the job, and skipping that step is how you end up putting your name on something with strong opinions about correctness

Dear reader, I did it anyway.

The library is [`burner-redis`](https://github.com/PrefectHQ/burner-redis), an embedded Redis-compatible backend built to replace [`fakeredis`](https://github.com/cunla/fakeredis) in the in-memory mode of [`docket`](https://github.com/chrisguidry/docket), which is an asynchronous background task system built on Redis streams used as a dependency by both [FastMCP](https://github.com/jlowin/fastmcp) and [Prefect](https://github.com/PrefectHQ/prefect). In fairness, `fakeredis` is built as a testing tool, and we were using it for a use case beyond its design; memory leaks in its Lua implementation and a string of breaking changes were the natural cost of stretching it that way. The goal was never "Redis, but better"; the goal was to support the Redis behavior `docket` needs, as a drop-in for `redis.asyncio.Redis`.

An AI coding agent wrote nearly all of it, and I trusted the tests, the interfaces, and the prior art to do the steering. The question of whether an agent can write code has been answered to death by now; the interesting one is *when* agent-written code holds up, with this project as a useful data point because it did.

## The Target Was Already Specified

This project worked because every interface was already pinned down, leaving the agent to implement against contracts that already existed and were enforceable, with three contracts doing almost all the work:

- `docket`'s test suite already described which Redis behaviors `burner-redis` needed to support; a test that passed against real Redis but failed against `burner-redis` was a bug, with no judgment call required.
- [`redis.asyncio.Redis`](https://github.com/redis/redis-py), the async client in `redis-py`, defined the Python-facing API surface (return types, exception classes, method signatures, all of it), and the agent had to match the shape that was already there.
- Redis itself, with fifteen-plus years of mature command semantics, provided the third rail; when a command's behavior was unclear, the answer was always "go run it against real Redis and see what it does."

Put those together and correctness is externally defined at every layer, leaving the agent no room to "decide" the answer, which was already living in a test, a `redis-py` stub, or `redis-cli`. That's a very different shape of work from "build me a thing that does X", where the channel between right and wrong is narrower and falling off either bank is observable.

## Where It Was Still Hard

Redis still has sharp edges, and `redis-py` compatibility is its own little crucible:

- Return types and exceptions have to match `redis-py`; a method that returns `bytes` when the client expects `int` is technically defensible and operationally broken.
- Pipelines and locks are API-shape problems first and storage problems second, and what gets buffered, batched, and atomically applied has to feel identical from the client's perspective.
- Streams, consumer groups, and Lua scripting have subtle behaviors you only catch by running real workloads through them.

Skip the tour. An agent can grind through this category of work for hours on end, patiently and methodically, as long as failures are observable, because a test that fails or a return type that mismatches gives unambiguous feedback, and an agent grinding inside that loop pulls its weight.

## When Agents Earn It

The result is a library that's actually pretty useful, and the AI-agent workflow was genuinely cool, but the sober conclusion matters more than the cool story. Agents are strongest when the interface already exists, the behavior is testable, the prior art is mature, and correctness is externally defined. Drop any one of those rails and you're back to a different kind of problem altogether, one where the agent has to invent something rather than match it.

The agent wrote the code, but the tests, interfaces, and prior art did much of the steering.
