+++
title = "pop, lock, and docket"
date = "2026-01-14T10:00:00-06:00"
tags = ["oss", "prefect", "docket", "redis streams"]
description = "Assimilating `docket`, a new asynchronous background task system built on top of Redis streams."

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

### trouble lurking in the background

most people know `prefect` as a Python library for defining, running, and monitoring workflows. some people, especially those running an open-source Prefect server, know that `prefect` is a client-server application that has a backing database and suite of supporting background services.

these background services have historically been called "loop services" because they each ran as a single process with a polling loop that found work and did work in the same process. this made them easy to reason about and deploy, but it also limited their ability to safely scale horizontally as there was the potential for multiple instances to fight over the same work (i.e. contention).

over the last year or so, [we've been working generally towards HA architectures](https://github.com/PrefectHQ/prefect/discussions/18150) for open-source Prefect server installations, which has included the introduction of Redis implementations for things like concurrency lease storage. the point being, Redis is now a core pillar of a scaled open-source Prefect server installation.


so, when [Chris Guidry](https://github.com/chrisguidry) prototyped a new asynchronous background task system built on top of Redis streams, we immediately starting scheming about how we could use it to replace the loop services. if we could define perpetual tasks that could be scheduled and executed asynchronously, we could remove the need for the loop services and allow scaling the server horizontally without worrying about contention between replicas, as `docket` is purpose-built to coordinate distributed tasks via Redis streams/consumer groups.


### not so fast

there was one problem: **prefect users might not have/want Redis!**

in fact, the **default** Prefect experience does not require Redis!

... and docket needed Redis to coordinate distributed tasks!

it turns out, there's a thing called [`fakeredis`](https://github.com/cunla/fakeredis) that can be used to mock Redis for testing purposes. in order to use it though, an [upstream PR to `fakeredis`](https://github.com/cunla/fakeredis-py/pull/427) was required to fix some Redis stream functionality that was missing from the mock implementation.

but once that was done, we were able to introduce `docket` to the open-source Prefect server without requiring Redis to be present, but allow HA installations to use it for background service coordination.


### docket all the things

all loop services were converted to `docket` perpetual functions:
- [cancellation_cleanup](https://github.com/PrefectHQ/prefect/pull/19715)
- [pause_expirations](https://github.com/PrefectHQ/prefect/pull/19719)
- [late_runs](https://github.com/PrefectHQ/prefect/pull/19722)
- [repossessor](https://github.com/PrefectHQ/prefect/pull/19739)
- [foreman](https://github.com/PrefectHQ/prefect/pull/19741)
- [telemetry](https://github.com/PrefectHQ/prefect/pull/19754)
- [scheduler](https://github.com/PrefectHQ/prefect/pull/19756)
- [proactive triggers](https://github.com/PrefectHQ/prefect/pull/19756)


docket was [even introduced to `fastmcp`](https://github.com/jlowin/fastmcp/pull/2326) to implement [SEP 1686](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/1686) - that is, the way that MCP servers can perform long-running tasks that MCP clients can request the status of.



### put it on the docket

if you're a Celery user, or you're rolling your own task queue on Redis Streams today, you may want to check out [`docket`](https://github.com/chrisguidry/docket) and see if it's a good fit for your needs.