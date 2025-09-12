+++
title = "Just do the thing"
date = "2025-09-12T10:43:06-05:00"
tags = ['dev workflow', ]
description = "Extinguishing bespoke dev workflows, one just recipe at a time"

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

### tribal knowledge

Every team has some bespoke operating procedures. [Alex](https://github.com/desertaxle) and I have a LOT of them! We're trying to have less.

One way we're doing this is by using [just](https://github.com/casey/just) to codify common development workflows in `justfile`s:
- [start a process to serve the docs locally](https://github.com/PrefectHQ/prefect/blob/main/docs/justfile#L2-L3)
- [preparing a release](https://github.com/PrefectHQ/prefect/blob/main/justfile#L98-L124)
- [make sure you have `uv`](https://github.com/PrefectHQ/prefect/blob/main/justfile#L4-L23) as a prerequisite for running other dev workflows


You'll notice that you can place `justfile`s in any directory (like our `docs` directory), and then [expose them in the root `justfile` via `mod docs`](https://github.com/PrefectHQ/prefect/blob/main/justfile#L1). This is a great way to keep recipes semantically organized in the codebase. Do we do this perfectly today? No! Will we continue to improve over time? Absolutely!



### there are dozens of us!
Here are some more projects that have nice `justfile`s:
- [`just` itself](https://github.com/casey/just/blob/master/justfile)
- [`fastmcp`](https://github.com/jlowin/fastmcp/blob/main/justfile)
- [the Rust SDK for MCP](https://github.com/modelcontextprotocol/rust-sdk/blob/main/justfile)



### final thoughts
Not only is this super useful for broadcasting norms to other developers, but in this age it can also short-circuit a lot of Claude-splaining by pointing at your `justfile` from your `CLAUDE.md` / `AGENTS.md` files.


As is a common theme for us, a big part of the value here is the interface that `just` provides. Maybe tomorrow we decide to use a different tool (besides [`mdxify`](https://github.com/zzstoatzz/mdxify)) to generate our api reference docs, but humans and LLMs can still `just api-ref` to get the job done.

