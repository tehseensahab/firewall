+++
title = "MCP Authentication and Authorization: What a Secure Deployment Should Check"
date = 2026-11-15T09:00:00Z
tags = ["ai security", "authentication"]
summary = "MCP's authorization spec is built on OAuth 2.1 for a specific reason: most MCP clients are desktop apps and CLI tools that can't securely hold a client secret, and OAuth 2.1's mandatory PKCE was designed for exactly that constraint."
description = "How MCP authentication and authorization actually work under OAuth 2.1: audience binding, the confused deputy problem, and what a secure remote MCP deployment must validate."
author = "FirewallSync Editorial"
+++

The MCP specification's authorization framework, revised in 2025, is built on OAuth 2.1 rather than a bespoke authentication scheme — a deliberate choice, since most MCP clients (desktop AI applications, CLI-based agents, browser-based interfaces) are public clients that can't securely store a client secret, and OAuth 2.1's mandatory PKCE requirement exists specifically to secure authorization flows for exactly that class of client, without needing one.

## The roles map onto standard OAuth 2.1

An MCP server, when exposed over HTTP transport, acts as an OAuth resource server. The MCP client (the AI application) is the OAuth client. A separate authorization server — which can be a dedicated identity provider, or co-hosted with the resource server in simpler deployments — issues access tokens. This is a clean, standard separation of concerns: the authorization server handles authenticating users and issuing tokens, and the MCP server's only job is validating tokens presented to it and enforcing the permissions they encode.

## How the flow actually works

A client connecting to an MCP server without a token receives a 401 response, with a `WWW-Authenticate` header pointing to a Protected Resource Metadata document (per RFC 9728) that tells the client where to find the appropriate authorization server. The client then runs a standard OAuth 2.1 authorization code flow with PKCE against that authorization server, obtaining an access token that's specifically bound to that MCP server as its intended audience (per RFC 8707's resource indicators). Every subsequent request to the MCP server includes that token as a bearer credential, and the server validates its signature, issuer, expiration, and — critically — its audience before processing any tool call.

## Audience validation is the control that prevents token misuse

This is the detail that separates a correct MCP authorization implementation from a superficial one: the server must verify that a presented token was actually issued for it specifically, not for some other service. Without this check, a token obtained for a different, unrelated API could potentially be presented to and accepted by an MCP server that doesn't verify audience — and conversely, a token issued for the MCP server should never be forwarded on to some other upstream API as if it were valid there, since that upstream service never intended to trust this particular token in the first place. Skipping audience validation is what collapses two independent trust boundaries into one, which is the essence of the confused deputy failure pattern discussed elsewhere in MCP security.

## STDIO servers are a deliberately different case

For local, STDIO-transport MCP servers — running as a subprocess on the same machine as the client, communicating over standard input/output — the specification explicitly says OAuth should not be used. The transport itself provides the relevant isolation (the operating system's own process and permission boundaries), and credentials for these servers should instead come from the local environment directly, the same way any local CLI tool typically handles its own configuration. Applying full OAuth flows to a local subprocess server would add complexity without a corresponding security benefit, since the trust boundary being protected doesn't cross a network at all in that scenario.

## What a secure deployment actually needs to check

**Separate the authorization server from the resource server in production**, rather than having the MCP server issue its own tokens directly — this separation is what allows proper audience binding and centralized identity management, rather than each MCP server implementing its own ad hoc authentication.

**Validate token audience on every request**, not just signature and expiration — a token that's otherwise valid but wasn't issued for this specific server should be rejected, full stop, regardless of how legitimate its origin looks.

**Never pass through a received token to an upstream API** unless that upstream API explicitly issued or trusts tokens of that specific type and audience — accepting a client's token and simply forwarding it onward is the token-passthrough pattern the specification's audience-binding requirements exist specifically to prevent.

**Enforce fine-grained scopes at the tool-call level, not just at the connection level.** A valid, correctly audience-bound token establishes that this client is allowed to talk to this server — it doesn't by itself answer whether this specific tool call, with these specific parameters, should be permitted for this specific user or agent. That's a separate authorization decision, enforced per tool call, that OAuth scopes can inform but don't automatically resolve on their own.

**Use dynamic client registration and discovery as designed**, rather than hardcoding assumptions about a single authorization server — the specification's discovery mechanisms exist to let this configuration be automated and consistent across different MCP servers and clients, and bypassing them tends to reintroduce the kind of ad hoc, per-integration authentication logic OAuth 2.1 adoption was meant to replace.

## Why getting this right matters more for MCP than for a typical API

A typical API breach exposes data. An MCP server with a broken authorization boundary exposes a channel through which an AI agent — potentially manipulated through prompt injection or tool poisoning — can take real actions using whatever the server's underlying credentials allow. Getting authentication and authorization right at this layer isn't just about preventing unauthorized access to the MCP server itself; it's a load-bearing part of containing what a manipulated or misused agent can actually accomplish once it's connected.
