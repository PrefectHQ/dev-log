+++
title = "Mea Culpa"
date = "2026-02-16T21:25:06-06:00"
tags = ["meta","roast"]
description = "The prodigal author returns"

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"

+++

I'm sorry. I've let you down. 

Not only have I not written a dev log entry in many fortnights, but [roast-bot](/llm-assisted-accountability/) hasn't been keeping me honest.

Today, I'm recommitting to writing a dev log entry every week. I'm also refactoring roast-bot to be more dependable. From now on, roast-bot will update the footer of this page each time it runs, so you, the reader, can verify that I'm keeping my promise.

As penance, here's an AI-generated roast fresh from the oven.

---
# The Five Stages of Grief, Committed to Git

If you've ever wanted to watch someone discover concurrency the hard way — in real time, in public, across 15 commits — then [PR #20608](https://github.com/PrefectHQ/prefect/pull/20608) is your new favorite bedtime story.
The goal is perfectly reasonable: add a PER_NODE execution mode to Prefect's dbt orchestrator so each dbt node runs as its own Prefect task with retries and concurrency control. A real feature solving a real problem. The execution, however, is a 15-commit safari through every wrong way to run things in parallel before stumbling into the one that works.

## The Commit History: A Concurrency Grief Spiral

The commit messages on this PR read less like a development log and more like the five stages of grief, expressed in `git commit -m`:
1. **"Add PER_NODE execution mode"** — the dream.
2. **"Fix dbt adapter registry race condition"** — the wakeup call.
3. **"Use no-op for reset_adapters to avoid closing active connections"** — bargaining with dbt's internals.
4. **"Replace adapter_management with no-op to fix concurrent dbt execution"** — full monkeypatch. If you can't fix the road, remove the speed bumps.
5. **"Move dbt adapter_management patch from test fixture into production orchestrator"** — promoting a test hack to production code. A rite of passage, really.
6. **"Cache dbt manifest to avoid concurrent parse_manifest() calls"** — patching the patches.
7. **"Replace thread-based PER_NODE execution with ProcessPoolTaskRunner"** — the full pivot. Threads were a mistake. Start over.
8. **"Replace monkeypatched ProcessPoolTaskRunner with constructor-injected task_runner_type"** — monkeypatching the thing you switched to *after* monkeypatching the last thing.

The whole story is right there in the commit log: threads fought dbt's singleton adapter registry (`FACTORY`), lost, got monkeypatched as a consolation prize, then got thrown out entirely for process pools. But process pools needed picklable exceptions, and dbt exceptions aren't picklable, so we get this line in [`_orchestrator.py`](https://github.com/PrefectHQ/prefect/pull/20608/files#diff-6fcab1f0f0dc0d3e090f0ee20a32c9e3da6e48e8a12eaaf4e58e05c81ca12f08):
```python
safe_error = RuntimeError(str(result.error))
```
"I cannot serialize your error, so I will destroy it and replace it with a string." This is the `str()` of a developer who has been *hurt*.

## The Plan Document: 1,246 Lines of Retroactive Justification

This PR ships updates to a plan document that clocks in at **1,246 lines**. Among the additions is a new "Implementation notes" section for Phase 5 that is less "here's what we plan to do" and more "here's an essay about what we tried and why it didn't work":
> "The original implementation used threads with `threading.Semaphore` and a monkey-patch of `adapter_management` to prevent `reset_adapters()` from racing across threads. The process approach trades some startup overhead... for correctness without patching dbt internals."

When your plan document needs a postmortem section to explain why the plan changed three times during execution, it's not a plan anymore. It's a changelog wearing a trenchcoat.

## "Curious Why This Isn't an Enum?"

Fifteen commits into this PR, the reviewer [notices](https://github.com/PrefectHQ/prefect/pull/20608#discussion_r2794447437) that `ExecutionMode` — the central abstraction that determines how the entire orchestrator behaves — was shipped as a bare class with string constants instead of an `Enum`. The response: ["It's an enum now!"](https://github.com/PrefectHQ/prefect/pull/20608#discussion_r2795020542) You went through five architectural pivots on how to run dbt nodes concurrently, but the two-value type that selects between them didn't warrant `from enum import Enum` until someone asked nicely.

## The Compliment (Grudgingly Given)

I'll say this: the final test suite is genuinely impressive. 748 lines of PER_NODE unit tests, DuckDB integration tests, a full Postgres concurrency suite — this thing is tested within an inch of its life. It's like watching someone total four rental cars and then nail their F1 qualifying lap. The driving is clearly there. The first four cars just had to die for it.

---

**Final Verdict:**
**Ballmer's Peaker** — fought every concurrency primitive Python has and mass-committed the receipts
