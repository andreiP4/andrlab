# 005: What runs on the Pi, and why

## Context

My original plan was to run Pi-hole on the server. Then I realized that a DNS server has to be on all the time, and I wanted the server to sleep. So I decided to get a Raspberry Pi just for Pi-hole.

Once I had an always-on device planned, I realized it could also solve the Wake-on-LAN problem: something on the home network has to send the wake packet while the server is asleep (see [004](004-sleep-and-wake.md)).

That turned into a simple rule: **anything that has to work while the server is asleep goes on the Pi.**

## What's on it

- **Pi-hole.** The reason the Pi exists. If DNS ran on the server, every device in the house would lose name resolution each time the server went to sleep. It's also set as the DNS server for my whole tailnet, so ad blocking works away from home.
- **Wake service.** Can't live on the machine it wakes.
- **Caddy, as its own reverse proxy.** The server already runs Nginx Proxy Manager, but routing the Pi's services through it would make the wake page depend on the sleeping server. So the Pi gets its own proxy.

## Why Caddy here and NPM on the server

- On the server, NPM was already available in the ZimaOS app store and has Cloudflare DNS-01 support built in. I manage it through its web UI, which fits how ZimaOS works.
- The Pi runs Raspberry Pi OS Lite with no desktop. Caddy is one binary and one short text file, which suits a headless box. The catch is that the standard Caddy package has no Cloudflare support, so I installed a build that includes the `caddy-dns/cloudflare` module.
- The Cloudflare token is stored in a root-only environment file loaded by systemd, not in the Caddyfile.

## Why a Pi 3B

It's more than enough. Pi-hole, a tiny Go service and Caddy barely use its CPU, and it draws a few watts. It's wired to the router, not on Wi-Fi, because a DNS server that drops off the network is worse than none.

## Trade-offs

- Two reverse proxies to understand instead of one.
- The Pi runs from an SD card, which wears out with constant writes. Worth keeping a backup of its config.

## Revisit if

The Pi becomes a single point of failure for things that matter more than DNS. Then it may be worth a second Pi-hole or better hardware.
