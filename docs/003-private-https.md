# 003: Own domain with private HTTPS

## Context

Vaultwarden's web vault refuses to work over plain HTTP. Browsers only allow the crypto it needs on HTTPS pages (or `localhost`), so HTTPS was required.

My first attempt used Tailscale's built-in certificates for the machine's `.ts.net` name. It worked, but every service was on the same hostname with a different port (`https://server.tailnet.ts.net:10443`, and so on), and I had to upload the certificate to the proxy by hand.

## Decision

Buy a domain, manage its DNS in Cloudflare, and point each subdomain at a **Tailscale IP**:

- `vault.mydomain.com`, `photos.mydomain.com` and so on resolve to the server's `100.x.y.z` address.
- `wake.mydomain.com` and `pihole.mydomain.com` resolve to the Pi's.
- Records are set to "DNS only", so Cloudflare doesn't proxy anything.

Certificates come from Let's Encrypt using the **DNS-01 challenge**: the proxy proves I own the domain by creating a TXT record through the Cloudflare API. Let's Encrypt never needs to connect to my machines.

## Why

- Clean names instead of ports.
- Real certificates that every device trusts. With self-signed certs I'd have to install my own CA on phones and the TV.
- Renewal is automatic.
- Anyone can look up the DNS names, but the addresses only work inside my tailnet.

## Trade-offs

- A domain costs about €10–15 a year.
- My subdomain names are publicly visible in DNS. That reveals which services I run, though not how to reach them.
- The Cloudflare API token is a real secret. I scoped it to "Edit DNS" on this one zone only, and it's kept out of config files (see the Caddy setup).

## Revisit if

I stop using the domain, or Tailscale's own naming becomes good enough to replace it.
