# 004: Sleep when idle, wake on demand

## Context

Most of the time nobody is using the server. Running it 24/7 would draw about 22 W on average, roughly €55 a year at my electricity price, mostly while idle.

The obvious fix is letting it sleep. The problem is getting it back. Wake-on-LAN works by sending a "magic packet" that the network card listens for while the machine is asleep. That packet is a LAN broadcast, and Tailscale can't deliver it to a machine that is offline. Something already awake on my home network has to send it.

## Decision

- The server **suspends to RAM** (`systemctl suspend`) after an hour with no activity.
- A Raspberry Pi stays on permanently and runs a small **wake service** I wrote. From any device on my tailnet I open `https://wake.mydomain.com`, and the Pi sends the magic packet.

## Why suspend instead of shutdown

I tested both. Waking from suspend takes seconds, while a cold boot takes much longer, and suspend still uses very little power. Wake-on-LAN worked from both states on this hardware.

## Why a web page instead of an SSH command

The first version was "SSH into the Pi and run `wakeonlan`". That works, but it's clumsy on a phone. A bookmarked page is one tap.

The service is written in Go using only the standard library. It compiles to a single binary that I cross-compile on my laptop for the Pi's ARM64 CPU, so nothing needs to be installed on the Pi except `wakeonlan` itself. It runs as a systemd service under a normal user.

## Trade-offs

- Opening an app while the server sleeps fails until I wake it. It's one extra step and a few seconds' wait.
- One more device to maintain.
- The wake page sends the packet on every visit, which is harmless if the server is already on.

## Revisit if

The extra step gets annoying enough to justify something that wakes the server automatically on the first request. That's possible, but much more complex.
