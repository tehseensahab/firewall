+++
title = "Broken Access Control: Real-World Examples and How to Prevent It"
date = 2026-10-15T09:00:00Z
tags = ["appsec", "process"]
summary = "Broken access control has topped the OWASP Top 10 since 2021 for a reason: it's not one vulnerability type, it's an entire category of ways authorization checks get skipped."
description = "Broken access control tops the OWASP Top 10. Real-world patterns — IDOR, missing function-level checks, privilege escalation — and how to prevent them."
author = "FirewallSync Editorial"
+++

Broken access control has held the top position in the OWASP Top 10 since the 2021 edition, and it's the category with the most reported occurrences in OWASP's own contributed testing data — over 318,000 recorded instances across the applications analyzed. That volume isn't because it's one specific bug pattern; it's because "broken access control" covers several distinct ways authorization checks fail, each common enough on its own to matter.

## Insecure direct object references (IDOR)

The most familiar pattern: an application exposes a reference to an internal object — an order ID, a document ID, a user ID — directly in a URL or request parameter, and fails to verify that the requesting user is actually authorized to access that specific object. Changing `/invoices/1024` to `/invoices/1025` and getting another customer's invoice back is the canonical example. This happens because authentication (confirming who's logged in) gets implemented and tested thoroughly, while object-level authorization (confirming that specific logged-in user is allowed to see that specific object) gets assumed rather than explicitly checked on every request.

## Missing function-level access control

Distinct from IDOR: this is when an application correctly restricts what's shown in the UI for a given role, but doesn't enforce the same restriction on the backend endpoint itself. A standard user who can't see an admin panel in the interface can often still call the admin API endpoint directly if the endpoint itself doesn't independently verify the caller's role — the UI hid the button, but nothing stopped the request. Any access control decision made only in frontend code is not actually an access control decision.

## Privilege escalation, vertical and horizontal

Vertical escalation is a standard user gaining admin-level capability — often through the function-level gap above, or through a parameter that controls role or permission level and isn't validated server-side (a request body that includes `"role": "admin"` and gets trusted rather than ignored). Horizontal escalation is accessing another user's data at the same privilege level — which is effectively IDOR viewed through a different lens, since both involve one user reaching resources that belong to another.

## CORS misconfiguration as an access control failure

A permissive CORS policy — particularly one that reflects an arbitrary request origin back as trusted, combined with credentialed requests — effectively extends your access control boundary to any site that can get a victim to load it, since the browser will now let that third-party origin make authenticated requests on the victim's behalf. This is access control failing at the browser trust boundary rather than the server logic, but it belongs in the same category because the end result is the same: someone accessing something they shouldn't.

## Why this keeps happening

Authentication has mature, well-tested standard patterns that most frameworks handle reasonably well by default. Object and function-level authorization is inherently application-specific — the framework can't know on its own whether the currently authenticated user should be allowed to see order #1025, because that depends entirely on your data model and business logic. This means authorization checks have to be deliberately written for each resource type and each endpoint, and any one that's missed is a gap, not a framework misconfiguration you can patch centrally.

## How to actually prevent it

**Deny by default, allow explicitly.** Every endpoint and every resource access should require an explicit authorization check to succeed, rather than being open unless something blocks it. This flips the failure mode from "silently overexposed" to "loudly broken," which is far easier to catch in testing.

**Enforce authorization server-side, every time, regardless of what the client already checked.** Never trust a client-supplied value (a role field, a permission flag) without independently verifying it against the actual authenticated identity's real permissions on the server.

**Test authorization explicitly, not just authentication.** A test suite that confirms "unauthenticated users are rejected" but never confirms "user A cannot access user B's resources" is testing less than half of what actually matters here. Include this as its own category of test, per resource type, not an afterthought bundled into general functional testing.

**Centralize authorization logic where possible.** Scattering ad hoc permission checks across individual route handlers makes it easy for one to be forgotten. A centralized authorization layer or middleware that every request passes through, with each route declaring what it requires, reduces how many places the check has to be independently remembered and correctly implemented.

Broken access control isn't a single vulnerability to patch. It's a category that requires deliberate, per-resource enforcement — which is exactly why it remains the most common category in real-world findings even after years at the top of the list.
