# wol-server

Tiny Wake-on-LAN trigger service. One button, one target MAC, runs on a Raspberry Pi.

## Local dev

No build step, no dependencies. Just:

```
go run main.go
```

Then open http://localhost:8067

## Deploying to a Raspberry Pi 3B (64-bit Raspberry Pi OS Lite)

The Pi has no Go toolchain — cross-compile on your dev machine instead.

1. Build a linux/arm64 binary:

   ```
   GOOS=linux GOARCH=arm64 go build -o wol-server main.go
   ```

2. Copy both the binary and the `assets/` folder to the Pi, keeping them alongside each other in the same directory. The server serves files via `http.Dir("assets/")`, a relative path, so `assets/` must sit next to `wol-server` wherever it runs.

   ```
   scp wol-server pi@<pi-host>:~/wol-server/
   scp -r assets pi@<pi-host>:~/wol-server/
   ```

3. Install `wakeonlan` on the Pi — the binary just shells out to it, it isn't bundled:

   ```
   sudo apt install wakeonlan
   ```

4. Run it on the Pi, no Go installation required there:

   ```
   ./wol-server
   ```

   The server listens on `:8067`.
