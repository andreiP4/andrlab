# 002: Tailscale for remote access

## Context

I want to reach my services from anywhere, on laptops, my phone and a TV, without making them visible to the rest of the internet. The usual options are:

- **Port forwarding** on the router. Every forwarded service is open to anyone who scans my IP.
- **Cloudflare Tunnel.** No open ports, but the services become public websites behind Cloudflare, and all traffic passes through them.
- **A VPN.** Only my own devices can connect.

## Decision

Tailscale on the server and the Pi, plus the Tailscale app on each device I use.

## Why

- Nothing is exposed. The router has no port forwards for any of these services.
- No setup on the router. Tailscale works through NAT without opening ports.
- Every device gets a stable `100.x.y.z` address that works the same at home and away.
- Apps like Immich and Bitwarden on my phone just point at an address, so they work over Tailscale without any special support.

## Trade-offs

- Every device needs the Tailscale client installed and signed in. Guests can't just open a link.
- I depend on Tailscale's coordination service to set up connections.
- Tailscale can't reach a machine that is asleep. That's why the wake service lives on a separate device (see [004](004-sleep-and-wake.md)).

## Revisit if

I want to share something with people outside my tailnet. For a single public service, like a game server, the plan is to forward just that one port rather than change the whole design.
