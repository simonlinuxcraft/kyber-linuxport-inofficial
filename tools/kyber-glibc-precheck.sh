#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
# Copyright (C) 2026 simonlinuxcraft
#
# kyber-glibc-precheck.sh - AppRun gate that stops the launch with a clear
# message when the host glibc is older than 2.39.
#
# librust_lib.so carries a DT_VERNEED entry for GLIBC_2.39 (pidfd_spawnp,
# pidfd_getpid, pulled in by Rust std when built against glibc >= 2.39). The
# two symbols are weak, but the verneed entry carries no VER_FLG_WEAK, and the
# loader aborts on an unsatisfied verneed regardless of symbol binding.
# Verified by patching the entry to a version no system provides: dlopen then
# fails with "version `GLIBC_2.xx' not found" while the unpatched library
# loads. The GTK/sentry stack needs 2.38, so 2.39 is the real floor.
#
# On older systems (SteamOS 3.6 = 2.37, Ubuntu 22.04 = 2.35) the app aborts
# before the first frame with a bare "GLIBC_2.39 not found" on stderr and no
# window, so the user just sees "nothing happens". Detect that up front and
# say why, instead of a silent crash.
#
# Sourced by AppRun first, before the other hooks and the GTK hook. On a
# too-old glibc it shows a dialog and exits non-zero, aborting the AppImage.
# Never blocks when KYBER_NO_GLIBC_GATE is set or the version cannot be
# determined: a failed probe must not block a host that would have worked.

_kyber_glibc_precheck_main() {
    [ -n "${KYBER_NO_GLIBC_GATE:-}" ] && return 0

    local ver=""
    if command -v getconf >/dev/null 2>&1; then
        ver="$(getconf GNU_LIBC_VERSION 2>/dev/null | awk '{print $2}')"
    fi
    if [ -z "$ver" ] && command -v ldd >/dev/null 2>&1; then
        ver="$(ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | tail -1)"
    fi
    # Unknown or malformed version (no dotted number): do not block.
    [ -z "$ver" ] && return 0
    case "$ver" in *.*) ;; *) return 0 ;; esac

    local major="${ver%%.*}"
    local minor="${ver#*.}"
    minor="${minor%%.*}"
    case "$major" in ''|*[!0-9]*) return 0 ;; esac
    case "$minor" in ''|*[!0-9]*) return 0 ;; esac

    # glibc >= 2.39 is fine (and any future major > 2).
    if [ "$major" -gt 2 ] || { [ "$major" -eq 2 ] && [ "$minor" -ge 39 ]; }; then
        return 0
    fi

    local title="Kyber (Linux Port) - unsupported system"
    local body
    body="$(printf 'Kyber Launcher needs glibc 2.39 or newer.\n\nThis system has glibc %s. The app would crash on start with no window (GLIBC_2.39 not found).\n\nKnown too-old systems: SteamOS 3.6, Ubuntu 22.04, Debian 12. Update to a newer OS release (SteamOS 3.7 or newer, Ubuntu 24.04 or newer) to run the launcher.' "$ver")"

    if command -v zenity >/dev/null 2>&1; then
        LC_ALL=C.UTF-8 LANGUAGE=en zenity --error --no-wrap --title="$title" --text="$body" 2>/dev/null || true
    elif command -v kdialog >/dev/null 2>&1; then
        LC_ALL=C.UTF-8 LANGUAGE=en kdialog --title "$title" --error "$body" 2>/dev/null || true
    fi
    printf 'kyber: glibc %s is too old (need >= 2.39), aborting.\n' "$ver" >&2
    return 1
}

if ! _kyber_glibc_precheck_main; then
    unset -f _kyber_glibc_precheck_main
    exit 1
fi
unset -f _kyber_glibc_precheck_main
