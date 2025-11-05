+++
title = "making a docs MCP server"
date = "2025-11-04T09:00:00-05:00"

description = "for our MCP server"

tags = ["ai", "MCP"]

[params]
    author = "Nate Nowack"
    authorGitHubHandle = "zzstoatzz"
+++

When building [our own MCP server](https://www.prefect.io/blog/a-prefect-mcp-server), we knew we wanted to expose some ability to search our docs, like:

```python
def search_docs(query: str) -> str:
```

so that MCP clients like ChatGPT and Claude Code can find and read docs while working on user tasks related to Prefect.

We had seen that [@mintlify](https://bsky.app/profile/mintlify.bsky.social) had released [their MCP server](https://bsky.app/profile/mintlify.bsky.social/post/3lvbiyuzu5r2q) so we wanted to check it out, but once we [plugged it into our MCP server](https://github.com/PrefectHQ/prefect-mcp-server/pull/25) (via FastMCP [proxying](https://gofastmcp.com/servers/proxy#proxy-servers)), it became clear that we could not depend on it to reliably serve clients with documentation excerpts (about 1 in 3 tool calls resulted in opaque 500 failures). So despite our love for all the other things Mintlify does, we knew we needed a new docs MCP.

We could have also looked into [context7](https://context7.com/) instead here

## building still includes buying

so how hard could it be to just make something that looks and behaves like this?

https://docs.prefect.io/mcp

that is, one tool called `SearchPrefect` that takes a single `query` and returns excerpts with links to the actual [docs](https://docs.prefect.io) pages.

well, if you have a vectorstore to use, not so hard!

turns out we do have a vectorstore via [turbopuffer](https://turbopuffer.com/), since we've used it for [our community slackbot Marvin](https://github.com/PrefectHQ/marvin/tree/main/examples/slackbot) over the last couple years.

we've historically ran OSS [chromadb](https://www.trychroma.com/) and [lancedb](https://lancedb.com/) (which are great!) and less ideal options like Pinecone/Weaviate, but turbopuffer I've found just seems pretty stable and surprises me the least.

so, right, making that `SearchPrefect` tool:

- [gather, vectorize and upload docs into vectorstore](https://github.com/PrefectHQ/prefect-mcp-server/tree/main/packages/ingestion_pipeline)
- [expose a query tool as `SearchPrefect` in an MCP server](https://github.com/PrefectHQ/prefect-mcp-server/blob/main/packages/docs_mcp_server/docs_mcp_server/_server.py)

[so that's what we did.](https://github.com/PrefectHQ/prefect-mcp-server/tree/main/packages/docs_mcp_server)

the only real question left is, where do we host the MCP server?

if only we knew an easy place to host MCP servers....

[ohhh yea](https://fastmcp.cloud/), we do. so now that that exists:

```python
# uvx --with fastmcp ipython
async with Client("https://prefect-docs.fastmcp.app/mcp") as client:
    response = await client.call_tool(
        "search_prefect", {"query": "how to build prefect flows"}
    )
    print(response)
```

drum roll please...

https://github.com/PrefectHQ/prefect-mcp-server/pull/48

and bada-bing bada-boom we have a docs tool on our Prefect MCP server. not the worst yak shaving exercise (we still 💙 Mintlify)
