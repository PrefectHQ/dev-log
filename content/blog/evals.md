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


#### ok so.. evals for MCP?

> what capabilities do clients have when connected to an MCP server?

is not the same question as:

> what is literally exposed by my MCP server?

clients might have other capabilities, like using a more general interface (e.g. terminal a la Claude Code) where the user might prefer more sensitive operations to happen

so, if we want to evaluate that an MCP client can do a thing on behalf of a user, we just need to set up an initial condition, and let the client loop with its tools/MCP servers until it achieves the desired outcome (perhaps asserting that this happened a particular way)

by extension, if you restrict the set of tools to only your MCP server, you can evaluate that your MCP server enables clients in general to have a particular capability on behalf of a user.


```python
@pytest.fixture
async def failed_flow_run(prefect_client: PrefectClient) -> FlowRun:
    @flow
    def flaky_api_flow() -> None:
        logger = get_run_logger()
        logger.info("Starting upstream API call")
        logger.warning("Received 503 from upstream API")
        raise RuntimeError("Upstream API responded with 503 Service Unavailable")

    state = flaky_api_flow(return_state=True)
    return await prefect_client.read_flow_run(state.state_details.flow_run_id)


async def test_agent_identifies_flow_failure_reason(
    simple_agent: Agent,
    failed_flow_run: FlowRun,
    tool_call_spy: AsyncMock,
    evaluate_response: Callable[[str, str], Awaitable[None]],
) -> None:
    prompt = (
        "The Prefect flow run named "
        f"{failed_flow_run.name!r} failed. Explain the direct cause of the failure "
        "based on runtime information. Keep the answer concise."
    )

    async with simple_agent:
        result = await simple_agent.run(prompt)

    await evaluate_response(
        "Does the agent identify the direct cause of the failure as 'Upstream API responded with 503 Service Unavailable'?",
        result.output,
    )

    # Agent must at least use get_flow_runs to get the actual error details
    tool_call_spy.assert_tool_was_called("get_flow_runs")
```


we will have more to share on this in the coming weeks! but we are thinking about how MCP clients (in general) should be enabled by MCP servers. CLIs are pretty great as agent tools already, so how should they play with MCP servers? where should mutations happen?


