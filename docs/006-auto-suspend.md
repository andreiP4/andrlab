# 006: Writing my own auto-suspend script

Status: in progress.

## Context

Something has to decide when the server is idle. The established tool is [autosuspend](https://github.com/languitar/autosuspend), which runs a set of checks (CPU load, logged-in users, network traffic, and so on) and suspends when all of them say "idle".

It's a Python program that needs D-Bus and GObject libraries. ZimaOS doesn't have them and has no normal package manager. Adding them would have meant installing a second package manager on top of an OS that isn't designed for it.

## Decision

Write a small POSIX shell script that copies autosuspend's design, with no dependencies, run from cron every 5 minutes.

- Each check is its own function and can be switched on or off.
- If **any** check reports activity, the idle timer resets.
- Only when **all** checks have been idle for an hour does it run `systemctl suspend`.
- Every decision is logged, so I can see why it did or didn't sleep.

## Checks

- **Load:** 1-minute load average above a threshold.
- **Users:** anyone logged in or connected over SSH.
- **Network:** traffic on the network card above a threshold.
- **Processes:** off. Explained below.
- **Ping:** off. Not needed for now.

## Two things I had to get right

**The network threshold.** An "idle" server isn't silent: Tailscale keepalives, container health checks and DNS all create background traffic. I measured it from the network card's counters and got roughly 2.4 kB/s in and 9.6 kB/s out. The threshold sits at about five times that. It's high enough to ignore background noise and low enough to notice someone scrolling through photos.

**Not watching service processes.** My first version kept the server awake while `immich-server` was running. But Immich is always running, whether anyone uses it or not, so the server would never sleep. Real use of a service already shows up as load and traffic. The process check is only meant for jobs that start and finish, like a backup.

## Trade-offs

- I'm maintaining my own script instead of a tested tool.
- Thresholds are a guess backed by one set of measurements. They'll need adjusting once I see real logs.

## Revisit if

ZimaOS gains a supported way to run autosuspend, or the script's false positives and negatives become annoying.
