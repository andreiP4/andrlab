# 001: ZimaOS instead of Proxmox

## Context

I compared two options for the server's OS. Proxmox is the standard homelab choice: a hypervisor where everything runs in VMs or containers. ZimaOS is a NAS-style OS built around Docker, with an app store and a web dashboard.

Everything I actually needed (Immich, Vaultwarden, file shares, note sync, later Jellyfin) runs as a Docker container. VMs were only a "maybe someday" idea.

## Decision

ZimaOS, installed on the NVMe drive.

## Why

- It was the fastest way to get the services I cared about running. Most were a one-click install.
- RAID, SMB shares and user management are built into the dashboard.
- It still accepts plain Docker Compose files for anything not in the store.

## Trade-offs

- Less control. ZimaOS is a trimmed-down system with no `apt`, so installing extra tools on the host is awkward. This is the reason I wrote my own suspend script (see [006](006-auto-suspend.md)).
- App store installs come with a default container configuration. I can edit it as YAML afterwards, but the starting point is ZimaOS's choice, not mine, so I have to check what it set up (ports, volume paths) instead of assuming.
- If I ever need serious VM work, moving to Proxmox means rebuilding the machine. ZimaOS has since added a basic VM module, which softens this.

## Revisit if

I need VMs regularly, or the app store gets in the way more than it helps.
