+++
title = "Transparent migrations"
date = "2025-09-13T10:00:00-05:00"
description = "On migrating Prefect’s tag-based concurrency to global concurrency limits by changing the implementation, but not the contract."
tags = ["migration", "concurrency", "dev-ex"]

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

Everybody loves a transparent migration. Nothing feels better than upgrading a package and things start working better without any action on your part. I've come to appreciate the skill that it takes on a maintainer’s part to make that happen.

First, a little bit of background. In `prefect`, you can apply tags to your tasks and then [configure a concurrency limit](https://docs.prefect.io/v3/how-to-guides/workflows/tag-based-concurrency-limits) to control how many tasks with that tag can run at once. One of the most frequent issues that we see with `prefect` is when tasks aren't running because of zombie concurrency slots. A mild-mannered concurrency slot becomes a zombie concurrency slot when a task takes a slot, then crashes without giving the slot back.

For more generalized concurrency, `prefect` also has [global concurrency limits](https://docs.prefect.io/v3/how-to-guides/workflows/global-concurrency-limits) that can be used outside of tasks as a context manager and have additional features like time-based slot decay. Global concurrency limits can also be used with a leasing system where the actor that takes a slot needs to report in periodically or the repo man will come and take it away.

If you're thinking, "Wow, two different concurrency limit implementations? That's a bit... much," you'd be right. We introduced global concurrency limits to address some of the inadequacies of tag-based concurrency limits, but having two different ways of doing things isn't good for users or our sanity as maintainers.

So this week we've been doing our best to pull a transparent migration off with tag-based concurrency in `prefect`. We're pulling it off by keeping the same API but backing it with the global concurrency limit implementation so users can get the benefits with no code changes. Each tag-based concurrency limit will be converted to a global concurrency limit; simple as that. The UI, CLI, and API will all work as they did before. If you use tag-based concurrency limits, you might not even notice the change. It'll be one of those changes where, months from now, you'll notice that it's been a while since you last saw a zombie slot.

Work like this is a good reminder that boring upgrades compound trust, and trust keeps software healthy long after the novelty wears off.
