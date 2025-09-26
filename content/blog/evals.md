+++
title = "MCPval"
date = "2025-09-25T09:43:51-05:00"

description = "Using evals to back out a useful Prefect MCP Server"

tags = ["ai", "pydantic","python","evals", "MCP"]

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

We're making a Prefect MCP server. That's great and fun!


### bad MCP clients
You wanna know what isn't great and fun? all the MCP clients **really suck**!

Why?
- no awareness of [resources](https://modelcontextprotocol.io/specification/2025-06-18/server/resources)
- no support for [elicitation](https://modelcontextprotocol.io/specification/2025-06-18/client/elicitation)
- no support for [sampling](https://modelcontextprotocol.io/specification/2025-06-18/client/sampling)

With the exception of the 1 or 2 decent MCP clients (Claude Code and perhaps [Goose](https://github.com/block/goose)), bad MCP clients force MCP server authors to abuse the primitives of MCP to provide tangible value to users of MCP clients (e.g. ChatGPT, Claude Desktop, Cursor, etc.)

### what to do?
well how do you assess the capability of an MCP server when clients are still so bad, ideally in a way we won't need to completely redo once the clients are better?


well.. 

{{< tweet user="gdb" id="1733553161884127435" >}}



we will have more to share on this in the coming weeks! but we are thinking about how MCP clients (in general) should be enabled by MCP servers. CLIs are pretty great as agent tools already, so how should they play with MCP servers? where should mutations happen?
