+++
title = "How to Train Your AI Assistant"
date = "2025-09-05T16:18:33-05:00"

description = "My experience (so far) replatforming our open source frontend from Vue to React with Claude Code."

tags = ["ai", "ui", "react", "claude code"]

[params]
    author = "Alex Streed"
    authorGitHubHandle = "desertaxle"
+++

We're in the messy middle of [replatforming our open source frontend from Vue to React](https://github.com/PrefectHQ/prefect/issues/15512). Honestly, it's quite a slog so far, not because of the technical complexity, but because of the persistence needed to keep the project moving forward. I've recently been increasing my use of Claude Code to help me navigate the more tedious parts of the migration. As I've iterated, I've learned how to work with Claude Code in a way that makes working through the replatform more enjoyable and productive.

One of the first issues I encountered was providing Claude Code with the necessary context to understand the project. Our original Vue setup was spread across three separate packages: the main UI code in `@prefect/ui`, a component library in `@prefect/ui-library`, and atomic design components in `@prefect/design`. Understanding any single feature meant jumping between repositories, tracking dependencies, and mentally reconstructing how everything fits together. When you're porting a Vue component to React, you need context from all three places. The cognitive overhead was killing productivity.

I restructured everything as a single workspace that consolidates all the relevant repositories. Claude Code can hop between the projects as needed and generate code that more closely matches the behavior of the existing code.

The next issue was that Claude Code didn't really match my style, and I found it kept making choices that I didn't like. So I started curating a [`CLAUDE.md` file](https://www.anthropic.com/engineering/claude-code-best-practices). It acts as a style guide and instruction manual for Claude Code, capturing all the accumulated taste and decisions that would otherwise live in my head or get lost in Slack conversations. Things like preferring `useSuspenseQuery` over `useQuery` for more declarative code, never using `as unknown` for type assertions, organizing query keys with a specific factory pattern, and even mundane details like branch naming conventions and commit message style. If I've had to correct Claude's choices more than once, it goes in the file.

The CLAUDE.md file has become a forcing function for consistency across the entire codebase. To better optimize context usage (and make the codebase easier for humans to navigate), I'm thinking of distributing the `CLAUDE.md` file into smaller `README.md` files in relevant directories, and linking to them from the `CLAUDE.md` file. We'll see how that goes.

Another challenge I've been working through is how to prioritize tasks so that work can build upon itself. Because Claude has a limited context window, chunks of work must be small enough to be completed before compaction. Like most developers nowadays, an impending compaction spikes my blood pressure.[^1]

At first, I chunked the work myself, choosing which component to assign to Claude based on how much work I thought was needed to complete it. But then I realized I have a magical thinking computer at my disposal. Why not let it do the work of chunking? So, I started having Claude Code generate plans and persist them in Markdown files, allowing me to review and adjust them before starting work. Persisting the plans to markdown also makes it easy to share with others and pick up where I left off.

Now I'm swimming in markdown files, and I sometimes forget which have been completed and which are still pending. We use Linear for project management, and Linear has an MCP server, so I think it's time to graduate.

Speaking of MCP servers, I have also found using a [browser MCP](https://browsermcp.io/) to control my browser to be very useful, as it gives Claude Code a way to explore and validate code automatically. Previously, I was the one clicking around and taking screenshots to give to Claude when things didn't look quite right, like a chump! With a browser MCP, I can provide Claude Code with a URL for the new app and a URL for the old app, and it can make the necessary adjustments itself.

So far, the combination of workspace structure, taste curation through the CLAUDE.md file, persistent planning, and browser MCP is working better than I expected. Each coding session feels productive because:
- Context is immediately available
- Decisions stay consistent with previous work  
- Progress is trackable and resumable
- The AI understands project constraints rather than suggesting generic solutions

Don't get me wrong, I still have to bully Claude a fair bit, but it's less as time goes on. Fortunately, the process is sustainable. I can pick up the work whenever I have time and make meaningful progress without spending the first hour remembering where I left off, and I won't tear my hair when I've copied and pasted my 20th query key factory.

The combination of AI assistance with structure is more potent than either alone. Claude Code is better at writing code when it has the proper context and constraints to work within. Kinda like human software engineers, but without the pesky things like needing to sleep, eat, or time off.

Now back to converting form components, which are somehow both the most tedious and most error-prone part of this entire migration.

[^1]: I do not like it when Claude gets lost, no matter what the computational cost. I do not like compaction, Sam-I-Am.
