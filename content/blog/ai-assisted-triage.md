+++
title = "AI-Assisted Triage Needs Receipts"
date = "2026-04-05T12:00:00-05:00"
tags = ["ai", "oss", "developer experience"]
description = "AI can chew through hundreds of issues but you can only trust it when every verdict comes with evidence."

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

I recently did a batch triage pass on the `prefect` issue tracker because we had over 900 open issues and I was sure that many of them were old and stale. The problem was that I was also sure that some of them were still plausible, and a whole lot were sitting in that annoying middle ground where you're not sure whether the bug still exists or whether everyone just got tired of talking about it.

That ambiguity is bad enough for maintainers, but it's worse now that contributors are showing up with AI agents in the loop. Stale issues don't just clutter the tracker. They poison the context those agents pull in, convince them to reason about dead code paths, and send people on wild goose chases through bugs that stopped existing six releases ago.

One of those issues looked straightforward. A worker was crashing after a container exited. The code already caught the obvious exception. Looks fixed, right? Not quite. The reporter was using Podman, not Docker, and Podman's Docker-compatible API was returning the wrong error for the same condition. Source-level reasoning said "handled correctly." Runtime said otherwise.

That ended up being the whole lesson in miniature: AI makes triage fast, but if you let it hand out verdicts without evidence, it will produce plausible nonsense at scale.

So here are the principles I ended up using to make AI-assisted triage more trustworthy.

## Let the Machine Do the Legwork

AI is excellent at the mechanical parts of triage. It can read code paths, trace git history, cross-reference issues, and check whether a fix landed faster than any human. Root cause analysis, verifying code paths, checking if a module was rewritten: these are tasks where the machine genuinely earns its keep.

What the machine can't do is apply judgment. Is this worth fixing given where the project is headed? Will closing this issue frustrate a user who's been waiting six months? Is the "correct" response here also the *right* one? That's the human's job.[^1]

The working model is simple: AI proposes, human reviews every verdict and every public comment. No exceptions. An AI-generated "this was fixed in the v3 rewrite" comment that turns out to be wrong is worse than no comment at all, because it erodes trust with the exact people you're trying to retain.

## No Mushy Verdicts

Every issue needs exactly one outcome. "Maybe" is not a verdict. I settled on three:

**Close.** The bug is verifiably fixed, the feature was intentionally removed, or the environment that caused it no longer exists. The key word is *verifiably*. You need to show the evidence: the commit that fixed it, the code path that no longer exists, the change that removed the behavior, or a script that shows the bug is no longer reproducible.

**Address.** The bug is confirmed and unfixed. This means you've traced the root cause, identified the affected code, and can describe concretely what a fix looks like. "This is still broken" without a path forward isn't a verdict; it's a shrug.

**Timed follow-up.** You can't verify either way. Maybe the issue requires an environment you don't have, or the reproduction steps are too vague to act on. Label it explicitly — `stale`, `needs-reproduction`, whatever fits — and give it a clear expiration. "If no one can reproduce this by [date], we close it." Don't let issues sit in limbo accumulating dust and guilt.

## Show Your Work

This is where most AI-assisted triage falls apart.

You never want your agent to say "likely fixed" or "probably addressed." You want it to either trace the fix (here's the commit, here's the old code, here's the new code, here's why that addresses the reported behavior) or say you can't confirm it. There is no middle ground.

When claiming that a rewrite fixed something, your agent should show the mechanism. The old code did X, the new code does Y, the reported symptom was caused by X, therefore the fix addresses it. If it can't articulate that chain, it doesn't actually know it's fixed. It's just guessing with style.

Hedging wastes everyone's time. A wrong-but-confident verdict gets corrected quickly because someone will push back. A vague one ("this may have been addressed in recent changes") just defers the work and leaves the issue in exactly the same ambiguous state it was in before you touched it.

## Source Is Not Runtime

Here's a principle that cost me some time to learn: reasoning about code is not the same as observing it run.

An AI reading source code can tell you what the code *says*. It can trace logic, check types, follow imports. But there's a class of bugs where the code looks correct and the behavior is wrong, and you can't distinguish between "fixed" and "still broken" without running it.

A way to actually run the code — execute tests, hit a real environment, reproduce the issue — turns "I think this is fixed" into "I confirmed this is fixed." Without that, triage degrades to reading source and guessing. With it, agents can close the loop.

This means designing your triage environment so agents can run reproduction scripts, not just read files. If your agent can spin up a test server, execute the reproduction steps from the issue, and observe the result, you've cut out a whole class of confidently wrong verdicts. If it can only read the source, you're trusting static analysis for runtime problems, which is exactly the kind of thing that produces confidently wrong verdicts.

## Chase Causes, Not Surfaces

Issues describe symptoms in one layer but often have causes in another.

A frontend rewrite doesn't fix a backend bug. A new scheduler doesn't fix a UI race condition. When triaging, you have to trace each cause independently through the stack. It's tempting to see that a component was rewritten and conclude that everything reported against it is resolved. That's sloppy, and it's exactly the kind of reasoning AI is prone to if you don't push back.

When a component has been removed or replaced, investigate whether the bug lives in the shared code underneath. The shiny new module might be sitting on top of the same problematic foundation.

Compound issues are another trap. Long-lived threads accumulate multiple distinct bugs as users pile on with related-but-different symptoms. Decompose them: identify each cause, check which are fixed, and split the rest into focused issues. One issue, one bug, one verdict.

## Sometimes the Bug Belongs to Somebody Else

Here's an example that illustrates why static analysis alone doesn't cut it.

[The report](https://github.com/PrefectHQ/prefect/issues/8421): a Docker worker crashes intermittently when containers finish running with `auto_remove=True`. The error is an unhandled `APIError` when the worker tries to call `container.wait()` on a container that's already been auto-removed.

Reading the code, the error handler catches `docker.errors.NotFound` for containers that have been auto-removed. It looks correct. The catch clause matches the documented Docker API behavior. An agent doing source-level analysis would reasonably conclude "this is handled correctly" and move on.

The twist: the reporter is using Podman, not Docker. Podman advertises a Docker-compatible API, but its compatibility layer [returns HTTP 500 instead of 404](https://github.com/containers/podman/issues/7184) for resources that don't exist. The code correctly catches `NotFound` (HTTP 404), but Podman throws a generic `APIError` (HTTP 500) for the same condition. The code is correct against the Docker API spec, but the runtime violates the spec.

You only discover this by running against Podman, or by tracing the upstream bug tracker. Source code alone, the catch clause looks airtight. Runtime verification reveals the gap.

The lesson is that bugs can live in the gap between your code and someone else's contract. "The code handles this correctly" and "this works in all environments users actually use" are two different statements, and only one of them matters.

## Fast Is Not the Same as Trustworthy

Good triage is a force multiplier. It turns a wall of open issues into a prioritized queue where every item has a clear next action. Bad triage, where issues get a "looks like this might be resolved" comment and nothing else, is worse than no triage because it creates the illusion of progress.

The principles are straightforward: verify concretely, trace root causes, decompose compound problems, and give agents real environments to test against. None of this is novel. It's just the standard you'd expect from a thorough human triager, applied consistently with the help of a robot that doesn't get tired or bored after the 200th issue.

AI makes triage fast. These standards make it trustworthy.

[^1]: This is not a John Henry situation where the human proves their worth by out-swinging the machine. Let the machine do the repetitive work. Your job is to make sure it doesn't confidently drive the railroad through a swamp.
