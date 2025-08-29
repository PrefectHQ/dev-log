+++
title = "Y.A.R.D. (Yet Another Retry Decorator)"
date = "2025-08-29T13:00:45-05:00"
description = "In which I attempt to justify introducing a dedicated retry decorator to Prefect"

tags = ["orchestration",]
+++

Retries are a staple of `prefect`. The roads towards building reliable workflows inevitably go through trying things again when they fail. Retries are baked into our `@flow` and `@task` decorators, so why on earth did I submit a [PR](https://github.com/PrefectHQ/prefect/pull/18814) to add a standalone `@retry` decorator?

Recently, we've been seeing an increase in requests for a lighter-weight orchestration client. People like some aspects of `prefect` (such as retries or caching), but other parts are overkill for their use case (like the need to start a server for observability). The issue is that using `@task` or `@flow` is like grabbing a banana, but you get a gorilla and the entire jungle with it[^1]. To be a flexible framework, it'd be nice if `prefect` offered a way to craft your own orchestration primitives with only the features you want.

Additionally, the client-side orchestration engine has long been one of the most complex pieces of `prefect`. About a year ago, we performed a large refactor of the engine as part of the 3.0 release, which significantly reduced complexity. However, software is not immune to entropy and tends towards disorder. One of the most effective ways (that we know of) to combat complexity in software is through decomposition. If we can identify and separate the engine's sections into distinct parts, then we can assemble those parts to create a complete orchestration engine.

Decomposition is particularly crucial for orchestration frameworks like `prefect` because we have to consider many concerns when designing functionality (like reliability, observability, performance, and developer experience). Each of these concerns pulls us in different directions. Historically, the approach has been to bundle everything together, creating an "orchestration monolith". These are frameworks that handle every possible use case but require buying into the entire ecosystem. We want to steer away from that approach with `prefect` because we see the value in making a framework incrementally adoptable and hackable, as we can't possibly understand every use case that our users will have.

At this point, we're in the realm of theory, but introducing standalone retry functionality is the first step in testing this theory. If you squint at the engine code ([here](https://github.com/PrefectHQ/prefect/blob/main/src/prefect/task_engine.py) if you want to squint along), then you can see the outline of some layers wrapped around user-defined code like state handling, observability, caching, and retries. Retries are the layer closest to the user code with the fewest dependencies on other layers, so it seemed like a good place to start testing the decomposed engine theory.

The structure of the retry functionality follows a similar pattern to the `@task` and `@flow` decorators, where there's a decorator (`@retry`) that produces a callable class (`Retriable`) when used to decorate a function. Within the callable class, there's a context manager that handles the core functionality (which is roughly equivalent to the task and flow run engine for `@task` and `@flow`). What I like about this structure is that it can be broken apart and remixed if needed. You can use just the context manager by itself if you want to use it with a portion of code without creating a separate function. Having a callable class gives you a natural place to add extensions for customization.

With the `Retriable` class, we can expose the registration of lifecycle hooks and enable integrations between different layers in the orchestration stack. This can range from simply logging when a function retries to performing complex checks before attempting a retry. Using hooks to communicate between layers is inspired by frontend frameworks like React that use props and callbacks to communicate between components. I'm not sure if we'll be able to have unidirectional data flow like React, but I'm a big fan of that paradigm.

I know that our `@retry` decorator will be but one star in a sky full of `@retry` decorators, but I'm hoping that this small step will lead us towards truly compositional orchestration. I'll probably write about this more as I work my way up the stacks, so stay tuned to see if we make it.

[^1]: Paraphrased from Armstrong, in Seibel, [Coders at Work](https://codersatwork.com/).
