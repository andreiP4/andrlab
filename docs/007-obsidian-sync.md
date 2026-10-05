# 007: Obsidian LiveSync for note sync

## Context

I use Obsidian on desktop and mobile and wanted my notes synced through my own server instead of a paid cloud service.

The main options:

- **Syncthing.** Simple file sync, works well between computers. On mobile it's weak: iOS restricts it, and the official Android app was discontinued.
- **Obsidian LiveSync.** An Obsidian plugin that syncs through a CouchDB database, with the same plugin on every platform.

## Decision

Obsidian LiveSync, installed from the ZimaOS app store (it sets up CouchDB as the backend). Each vault gets its own database so vaults never mix.

## Why

- It works the same on desktop, Android and iOS, because sync happens inside Obsidian rather than at the file level.
- Changes show up on other devices almost immediately.
- It supports end-to-end encryption.
- New devices join by scanning a setup QR code from an existing one.

## Trade-offs

- More moving parts than copying files around.
- It isn't built for multiple users. Every device connects with the same admin credentials, which can be seen in the plugin's settings. That's fine for me, but sharing with someone else would need a separate CouchDB instance for them.
- Sync stops while the server is asleep. Notes stay available offline and catch up after a wake.

## Revisit if

Someone else needs their own vault, or the official Obsidian Sync becomes worth paying for.
