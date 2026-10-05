#!/bin/sh
# ============================================================
# ZimaOS Auto-Suspend-on-Inactivity Script
# ============================================================
# A lightweight, dependency-free reimplementation of the
# check-based architecture from languitar/autosuspend
# (https://github.com/languitar/autosuspend), adapted for
# ZimaOS's minimal shell environment (no dbus-python/PyGObject
# available). Uses `systemctl suspend` instead of shutdown,
# since suspend-to-RAM + Wake-on-LAN is already confirmed
# working on this hardware.
#
# ARCHITECTURE (borrowed from autosuspend):
#   - Each check is a self-contained function: check_<name>
#   - Each check returns 0 (active) or 1 (idle) via exit code,
#     and can be independently enabled/disabled in CONFIG
#   - ANY active check resets the idle timer
#   - Only when ALL enabled checks report idle, for the
#     configured duration, does the system suspend
#
# Run periodically via cron (e.g. every 5 minutes).
# ============================================================

# ============================================================
# CONFIG — [general] equivalent
# ============================================================
IDLE_THRESHOLD_SECONDS=3600   # 1 hour of continuous idle before suspending
STATE_FILE="/var/lib/auto-suspend/state"
LOG_FILE="/var/log/auto-suspend.log"
SUSPEND_CMD="systemctl suspend"

# ============================================================
# CONFIG — [check.Load] equivalent
# ============================================================
CHECK_LOAD_ENABLED=1
LOAD_THRESHOLD="1.0"          # 1-minute load average max while "idle" (float)

# ============================================================
# CONFIG — [check.Users] equivalent (SSH / logged-in sessions)
# ============================================================
CHECK_USERS_ENABLED=1

# ============================================================
# CONFIG — [check.NetworkBandwidth] equivalent
# ============================================================
CHECK_NETWORK_ENABLED=1
NET_IFACE="eth0"
NET_THRESHOLD_BYTES_PER_SEC=30000   # tune after observing your idle baseline

# ============================================================
# CONFIG — [check.Processes] equivalent
# ============================================================
# Current services: Immich, Vaultwarden, Nginx Proxy Manager,
# CouchDB (Obsidian LiveSync), HandBrake (manual, started/stopped
# by hand — deliberately NOT watched here), Tailscale.
#
# Immich/Vaultwarden/NPM/CouchDB are always-on services, not
# finite "jobs" — watching their process names would make this
# check permanently report "active" and defeat the purpose.
# Load + NetworkBandwidth are the right signals for those.
#
# This list is for finite, must-not-interrupt jobs only.
# Empty for now — add entries back if a real case shows up
# (e.g. a scheduled backup script, restic/borg, rsync).
CHECK_PROCESSES_ENABLED=0
WATCHED_PROCESSES=""

# ============================================================
# CONFIG — [check.Ping] equivalent (optional, disabled by default)
# ============================================================
CHECK_PING_ENABLED=0
PING_HOSTS=""   # space-separated hosts/IPs; presence of a response blocks suspend

# ============================================================
# Internal setup
# ============================================================
mkdir -p "$(dirname "$STATE_FILE")"
touch "$LOG_FILE"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOG_FILE"
}

# ============================================================
# CHECK: Load — mirrors autosuspend's "Load" check
# ============================================================
check_load() {
    # /proc/loadavg: "0.15 0.22 0.30 1/523 12345"
    load1=$(awk '{print $1}' /proc/loadavg)

    is_active=$(awk -v load="$load1" -v max="$LOAD_THRESHOLD" \
        'BEGIN { print (load > max) ? "1" : "0" }')

    log "[Load] 1-min load average: ${load1} (threshold: ${LOAD_THRESHOLD})"

    [ "$is_active" = "1" ]
}

# ============================================================
# CHECK: Users — mirrors autosuspend's "Users" check
# (SSH / logged-in sessions via pseudo-terminals)
# ============================================================
check_users() {
    session_count=$(who | grep -c pts)
    log "[Users] Active pts sessions: ${session_count}"
    [ "$session_count" -gt 0 ]
}

# ============================================================
# CHECK: NetworkBandwidth — mirrors autosuspend's "NetworkBandwidth" check
# ============================================================
check_network() {
    rx1=$(cat /sys/class/net/"$NET_IFACE"/statistics/rx_bytes 2>/dev/null)
    tx1=$(cat /sys/class/net/"$NET_IFACE"/statistics/tx_bytes 2>/dev/null)

    if [ -z "$rx1" ] || [ -z "$tx1" ]; then
        log "[NetworkBandwidth] WARNING: could not read stats for $NET_IFACE — treating as active (fail-safe)"
        return 0
    fi

    sleep 2
    rx2=$(cat /sys/class/net/"$NET_IFACE"/statistics/rx_bytes)
    tx2=$(cat /sys/class/net/"$NET_IFACE"/statistics/tx_bytes)

    bytes_per_sec=$(( (rx2 - rx1 + tx2 - tx1) / 2 ))
    log "[NetworkBandwidth] ${bytes_per_sec} B/s on ${NET_IFACE} (threshold: ${NET_THRESHOLD_BYTES_PER_SEC})"

    [ "$bytes_per_sec" -gt "$NET_THRESHOLD_BYTES_PER_SEC" ]
}

# ============================================================
# CHECK: Processes — mirrors autosuspend's "Processes" check
# ============================================================
check_processes() {
    if [ -z "$WATCHED_PROCESSES" ]; then
        log "[Processes] No processes configured to watch."
        return 1
    fi

    old_ifs="$IFS"
    IFS=','
    for proc in $WATCHED_PROCESSES; do
        IFS="$old_ifs"
        if pgrep -f "$proc" >/dev/null 2>&1; then
            log "[Processes] Matched running process: ${proc}"
            return 0
        fi
        IFS=','
    done
    IFS="$old_ifs"
    log "[Processes] None of the watched processes are running."
    return 1
}

# ============================================================
# CHECK: Ping — mirrors autosuspend's "Ping" check
# ============================================================
check_ping() {
    for host in $PING_HOSTS; do
        if ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
            log "[Ping] Host responded: ${host}"
            return 0
        fi
    done
    log "[Ping] No configured hosts responded."
    return 1
}

# ============================================================
# Run all enabled checks
# ============================================================
activity_detected=0

if [ "$CHECK_LOAD_ENABLED" = "1" ] && check_load; then
    activity_detected=1
fi

if [ "$CHECK_USERS_ENABLED" = "1" ] && check_users; then
    activity_detected=1
fi

if [ "$CHECK_NETWORK_ENABLED" = "1" ] && check_network; then
    activity_detected=1
fi

if [ "$CHECK_PROCESSES_ENABLED" = "1" ] && check_processes; then
    activity_detected=1
fi

if [ "$CHECK_PING_ENABLED" = "1" ] && check_ping; then
    activity_detected=1
fi

# ============================================================
# Idle timer logic
# ============================================================
now=$(date +%s)

if [ "$activity_detected" -eq 1 ]; then
    echo "$now" > "$STATE_FILE"
    log "Activity detected by at least one check. Idle timer reset."
    exit 0
fi

if [ ! -f "$STATE_FILE" ]; then
    echo "$now" > "$STATE_FILE"
    log "First idle check. Starting idle timer."
    exit 0
fi

idle_since=$(cat "$STATE_FILE")
idle_duration=$(( now - idle_since ))

log "All checks idle. Idle for ${idle_duration}s (threshold: ${IDLE_THRESHOLD_SECONDS}s)."

if [ "$idle_duration" -ge "$IDLE_THRESHOLD_SECONDS" ]; then
    log "Idle threshold reached. Suspending via: ${SUSPEND_CMD}"
    rm -f "$STATE_FILE"
    $SUSPEND_CMD
fi
