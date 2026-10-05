# 008: One data drive for now, RAID later

## Context

The plan was two 500 GB HDDs in RAID 1 (mirrored), so one drive could fail without losing data. While setting it up, one of the drives reported 0 bytes of capacity and refused to format. The shell (`lsblk`, SMART data) confirmed it was failing.

I had a spare Kingston SSD that could have stood in as the second half of the mirror.

## Decision

Run a single HDD for data for now, and set up RAID 1 when I get a properly matched second drive.

- **NVMe SSD:** ZimaOS, apps, databases.
- **HDD:** user data (the Immich library, file shares).

## Why not mirror with the SSD

- The mirror would be limited to the smaller drive's size.
- An SSD and a laptop HDD wear out in completely different ways, so I'd be mixing two unknown failure patterns.
- A mismatched mirror felt like the kind of setup I'd want to redo later anyway.

## Trade-offs

Right now there's no redundancy. If the HDD dies, the data on it is gone. That makes backups the most important open item. RAID doesn't replace them anyway: it doesn't protect against deleting something by mistake, a bad update, or anything that hits the whole machine.

## Revisit if

I buy a second drive, or the amount of data outgrows 500 GB.
