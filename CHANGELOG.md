# Changelog

All notable changes to the Kyber Linux Port are recorded in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
Versioning tracks upstream Kyber, with port-specific patches noted separately.

## [0.1.0-beta.6.4.10] - 2026-07-07 - Hosting Hint & Fixes

### Added

- A warning before hosting when the machine hostname resolves to a loopback
  address other than 127.0.0.1 (common on Debian, Ubuntu, and Calamares-based
  installs such as CachyOS). In that state a hosted server connects to itself
  by name and the game crashes shortly after the map loads. The launcher now
  detects this on the Start Server click and shows the exact /etc/hosts fix
  instead of letting the host crash with no hint. Joining servers is unaffected.

### Fixed

- NXM mod downloads: fixed a race condition and several wrong or duplicated
  toast messages when starting a download from the mod browser or an nxm:// link.

### Changed

- Server communication errors now show the real reason (network, TLS, or
  backend message) instead of a generic "An error occurred" toast, so a failed
  server list, preview, or join is easier to diagnose.
- The AppImage self-updater only runs for standalone AppImage installs now.
  AUR and other package-manager installs update through the package manager
  instead of the in-app updater.

## [0.1.0-beta.6.4.9] - 2026-06-28 - Non-Steam Support

Battlefront II no longer has to come from Steam. A copy installed through
Lutris, the Epic Games Store, or the EA app can be launched by pointing Kyber
at a custom game path, and Proton is now found in more places.

### Added

- Non-Steam launch path. When BF2 is not a Steam copy (no Steam compatdata
  prefix exists), setting a custom game path now lets Kyber build its own Wine
  prefix and launch the game instead of failing with "No Proton prefix found".
  The Steam path is unchanged: a normal Steam install keeps using its existing
  prefix, and a Steam user who simply never launched BF2 through Steam still
  gets the "launch once through Steam" hint, so nothing regresses. Proton must
  already be on disk; the launcher fails with a clear message rather than
  starting a large cold download.
- Proton auto-detection now recognises GE-Proton 11.x and proton-cachyos in
  addition to GE-Proton 10.x, and also looks in Heroic and Lutris runner
  directories, not only Steam's compatibilitytools.d. A newer GE-Proton is
  preferred when several builds are present.
- AppImage self-update. The AppImage build now checks GitHub on start and, when
  a newer launcher version is available, offers to download and restart into it
  (classic check / download / restart prompt). Only the launcher container
  updates this way; mods, the Kyber module and live events keep coming from
  Kyber. The self-update is off in the AUR package, which the package manager
  updates.

### Fixed

- Saving a custom Proton path failed with "No such file or directory
  (os error 2)" for users who set it before ever launching BF2. The Wine
  directory is now created before the routing symlink, so the save succeeds.

## [0.1.0-beta.6.4.8] - 2026-06-25 - Steam Deck & Launch Fixes

Launch reliability across the board: the launcher no longer hangs forever on a
stuck Wine helper, no longer crashes windowless on a too-old system, no longer
refocuses over a still-loading game, and no longer panics when the configured
game directory is missing.

### Fixed

- Launch could hang forever on the Steam Deck when a Wine helper call (registry
  setup, inject, or DIP) stalled on a hung wineserver, umu.lock contention, or
  an unfinished umu/SteamLinuxRuntime download. These calls are now bounded
  (default 600s, override with KYBER_WINE_HELPER_TIMEOUT_SECS) and fail with a
  clear error instead of leaving the user on an endless spinner. The bound is
  generous on purpose so a fresh Deck's legitimate first-run runtime download is
  not cut off; the game launch itself is never timed.
- The app crashed on start with no window on systems older than glibc 2.38
  (SteamOS 3.6, Ubuntu 22.04, Debian 12), showing only "GLIBC_2.38 not found" on
  stderr. AppRun now checks glibc first and, on a too-old system, shows a dialog
  explaining the requirement and aborts cleanly instead of crashing silently.
  Bypass with KYBER_NO_GLIBC_GATE.
- Starting the game could crash the launcher (a panicked worker thread reporting
  "Failed to start child") when the resolved game directory did not exist, for
  example a custom game path pointing at a moved folder or an unmounted drive.
  The launch now checks the game directory up front and on a spawn failure
  returns a clear error instead of panicking.

### Changed

- The post-launch grace window before the launcher considers the game stopped is
  raised from 120s to 300s. A slow Steam Deck (cold prefix, BF2 on an SD card,
  first GE-Proton unpack) could take over two minutes to reach its first
  connection, and the launcher refocused over the still-loading game.

## [0.1.0-beta.6.4.7] - 2026-06-20 - libmpv Load Fix

Fixes a first-start crash on the intro video for fresh installs running on a host
that has a system libmpv installed. The intro video is kept on all distributions.

### Fixed

- Crash right after login on the first launch (an mpv m_config_cache_from_shadow
  assertion) on systems that carry an unversioned system libmpv.so, such as the
  symlink shipped by libmpv-dev. The bundled media player resolved libmpv by bare
  name and loaded the host libmpv as a second copy next to the bundled one; mpv's
  option lookup then crossed between the two images and aborted on the intro
  video. AppRun now pins the bundled libmpv through LIBMPV_LIBRARY_PATH, so the
  host libmpv is never loaded and a single libmpv image is used regardless of
  what the host has installed.

## [0.1.0-beta.6.4.6] - 2026-06-18 - Native Wayland Toggle

Adds an in-app toggle to run the launcher on the native Wayland backend instead
of X11/XWayland. X11 stays the default; the toggle only appears on a Wayland
session and takes effect after a restart.

### Added

- Settings -> Mods / Proton / Wayland: "Native Wayland (Experimental)" toggle.
  It records a backend preference that the AppImage applies before GTK starts,
  so the launcher comes up on native Wayland after a restart. Hidden on X11
  sessions, where forcing the Wayland backend would only fail to start. Turn it
  off (or remove ~/.config/kyber-linuxport/backend) to go back to X11.

### Changed

- The AUR package is now `kyber-launcher-unofficial-appimage` (was the older
  `-inofficial-` spelling). The pacman-managed `/opt` install no longer triggers
  the AppImage self-install, so it stops duplicating the image into
  `~/Applications`.

## [0.1.0-beta.6.4.5] - 2026-06-15 - Mod Downloads & Fixes

A batch of upstream launcher fixes backported into the Linux port, plus AppImage
robustness work. Mods packed inside a subfolder of a download now install, a
single unreachable proxy no longer empties the proxy list, and a possible
startup crash on minimal systems without a system librsvg is fixed.

### Fixed

- Mods packed inside a subfolder of a downloaded archive were silently skipped;
  they now install (nested-archive detection).
- A single unreachable proxy left the whole proxy list empty. Failed pings are
  now handled, and joining a server waits for the proxy pings to finish instead
  of erroring with no proxy available.
- The server browser search now clears when switching tabs, so servers no longer
  appear missing because of a stale filter.
- Corrupted mod collections now show a warning, and a working copy is preferred
  over a corrupted one when joining a server.
- The launcher window can be dragged across the full width of the title bar.
- AppImage: fixed a possible startup crash on systems without a system librsvg.
  The bundled SVG pixbuf loader could not reach the bundled librsvg (its RUNPATH
  was only its own directory); usr/lib is now on the loader's RUNPATH. Dropped
  the now orphaned libavif and collapsed duplicate librsvg copies to symlinks.
- Steam Deck: corrected a login hint that still mentioned webkit2gtk.
- Arch/CachyOS: when libnettle.so.8 is missing, the launcher no longer shows a
  second, irrelevant GStreamer dialog after the nettle warning.

### Added

- Support for the bypass player limit entitlement.

## [0.1.0-beta.6.4.4] - 2026-06-12 - Registry Fast Path

Follow-up to the 6.4.3 Deck testing round. A Deck tester log showed the
launch never reaching the game: every registry call before the launch stalled
for about five minutes, and the full setup batch needed over 90 minutes. The
registry state is now verified by reading the prefix files directly, which
needs no Wine call at all, and the launch flow records enough diagnostics to
tell where it stalls if it still does. It also keeps the first launch from
downloading umu's Steam Linux Runtime on the Deck by reusing the copy Steam
already ships there.

### Fixed

- Steam Deck: the launch could sit in the pre-launch registry setup for over
  an hour. The setup verified and wrote registry keys through wine/umu calls
  that each stalled for minutes on the Deck. The launcher now reads
  user.reg/system.reg directly and skips the whole batch when the values are
  already in place, so a warm launch does not touch Wine for the registry
  setup at all. The same applies to the locale re-lock that runs right before
  the game spawns.
- The direct registry file patch only covered the 64-bit view of the Origin
  client keys. 32-bit readers inside the prefix now find them too, matching
  what a real registry write would have produced.
- Steam Deck: the first game launch still had umu download its own copy of the
  Steam Linux Runtime (around 300 MB), which loops on a slow or unstable Deck
  connection and never lets the game start. Before the first launch the launcher
  now mirrors the SteamLinuxRuntime_sniper that Steam already keeps on the Deck
  into umu's runtime directory; umu validates that copy and downloads nothing.
  It falls back to umu's own download when no Steam copy is found, and does
  nothing on systems that are not a Deck.

### Added

- Launch diagnostics: the log now names the wine runner used for registry
  calls, warns when a helper call takes longer than a minute, and reports
  when a leftover umu lock from a previous session is blocking the launch.
  The wine wrapper records its routing decisions (Deck detection inputs,
  resolved wine binary, exit codes and durations) to
  `~/.local/share/maxima/wine/wrapper-diag.log` for bug reports.

## [0.1.0-beta.6.4.3] - 2026-06-10 - Steam Deck Launch & Browser

Steam Deck focused follow-up to beta.6.4.2. Runs the launch-time registry
setup directly through Wine on the Deck so the first launch no longer hangs on
umu's runtime download, opens the NexusMods sign-in in the real browser instead
of the software store, stops the launcher from giving up on a game that is
still loading, and captures the Proton output when a launch ends without the
game appearing. Still a test/pre-release; beta.6.3 stays the safe fallback.

### Fixed

- Steam Deck: the first game launch could get stuck on "downloading umu
  runtime" on slow or unstable connections. The registry setup that runs before
  a launch went through umu, which forced umu to download its own copy of the
  Steam Linux Runtime on the first call. That setup now runs directly through
  Wine on the Deck, so it no longer triggers the runtime download, and umu is
  told not to re-check its runtime.
- Steam Deck: the NexusMods sign-in opened the KDE software store (Discover) on
  the Firefox page instead of launching the browser. It now opens through the
  same sanitized path the EA sign-in already uses, which reaches the real
  default browser. The EA sign-in was unaffected.
- Steam Deck: the launcher could report a game as stopped a few seconds after
  pressing Play while it was still cold-loading. The helper that starts Proton
  exits early by design, and the game process is not visible to the host-side
  check inside the Steam container. A grace window now keeps the launch active
  until the game connects.
- Setup: the NexusMods step could be skipped during first-time setup. After the
  EA sign-in the walkthrough sometimes stayed on the EA step and never moved on,
  so finishing setup skipped NexusMods. The step now follows the actual sign-in
  state and appears as soon as EA is signed in.
- Steam Deck: the sign-in code box flashed on the login screen at every start
  while the saved session was being re-checked, as if the launcher was asking
  for a code. It now appears only after a sign-in has been waiting a few
  seconds, so a normal start no longer shows it.
- The launcher now stops with a clear message when Battlefront II has no Steam
  Proton prefix (the game was never launched through Steam, or a custom game
  path points at a non-Steam copy). Battlefront II runs inside the prefix Steam
  creates for it, and without it the launch could only fail with a cryptic
  Origin error. The message explains what to do instead of failing silently.

### Added

- When a game launch ends without the game appearing, the launcher folds the
  Proton/Wine output into the exported log, so the reason is visible in a log
  export instead of being discarded.

## [0.1.0-beta.6.4.2] - 2026-06-08 - Proton Download & libmpv

Follow-up to beta.6.4.1. Makes the first-launch GE-Proton download survive
slow links and closed windows, opens the EA sign-in in the real browser
instead of the software store on SteamOS, and fixes a startup crash on
distributions that do not ship libmpv. Still a test/pre-release; if it
misbehaves, beta.6.3 stays a safe fallback.

### Fixed

- The launcher crashed on startup on distributions without a system libmpv
  (SteamOS, minimal Fedora) with "libmpv.so.2: cannot open shared object
  file". libmpv is bundled, but the media_kit video plugin could not find it,
  because its library path still pointed at a build-machine directory that does
  not exist on the target. The plugin's RUNPATH now points at the bundled copy.
- The launcher also failed to start on a fresh install with "libjack.so.0:
  cannot open shared object file". media_kit's libmpv is built with JACK output
  support, so it needs libjack, which no consumer distro installs by default
  (the dev machine had it, which hid the gap). libjack and its libdb dependency
  are now bundled.
- The first-launch GE-Proton download (about 516 MB) read the whole archive
  into RAM and only wrote it to disk at the end, with no progress shown. On
  Steam Deck and slow connections the launch flow looked frozen, and closing
  the apparently-stuck window discarded everything, so the next Play press
  re-downloaded from the start every time. The download now streams to disk in
  1 MB chunks and resumes an interrupted file with an HTTP Range request.
- On SteamOS the EA sign-in opened the KDE Discover software store instead of
  the default browser, because the AppImage's bundled GTK environment leaked
  into the browser launch. The sign-in URL now opens with a cleaned environment
  (Flatpak browser export dirs included), so the real default browser opens.

### Added

- The start-game dialog shows a progress bar and byte counter during the
  first-launch Proton download instead of looking frozen.
- A system GE-Proton 10.x in compatibilitytools.d is auto-detected and routed
  to, which skips the 516 MB download on first launch.

### Changed

- On SteamOS the package-install hint is skipped, since pacman is not usable on
  the immutable read-only root and changes would be wiped on the next image
  update.

### Known limitations

- On rolling Arch/CachyOS with nettle 4.0 (libnettle.so.9) the launcher does not
  start until the nettle3 compatibility package (which provides libnettle.so.8)
  is installed: `sudo pacman -S nettle3`. The launcher now shows a dialog
  pointing this out. A self-contained fix is planned for a later build.
- Distributions older than glibc 2.38 (Ubuntu 22.04, Debian 12, SteamOS 3.6)
  cannot run this build. Tested on Ubuntu 24.04+, Fedora, SteamOS 3.7+ and
  Bazzite.

## [0.1.0-beta.6.4.1] - 2026-06-06 - Steam Deck Fixes

Follow-up to beta.6.4. The launcher still failed to start on Steam Deck and
SteamOS after the webkit fix, this time with a crypto library mismatch, and
the manual paste login could silently do nothing. Also fixes two Linux-only
auth paths that broke session recovery. Still a test/pre-release; if it
misbehaves, beta.6.3 stays a safe fallback.

### Fixed

- The launcher still crashed on startup on Steam Deck/SteamOS after beta.6.4,
  now with "undefined symbol: nettle_rsa_oaep_sha384_decrypt". The AppImage
  bundled its own gnutls/nettle/hogweed, but an older hogweed than rolling
  distros ship. The system's newer gnutls then bound against the bundled older
  hogweed and aborted before the UI. These crypto libraries are no longer
  bundled, so the whole TLS stack comes from the system as a consistent set.
- The manual sign-in code field could sit on "Submitting sign-in code..."
  forever. The code is delivered to the login flow's local callback, which only
  runs while a login is in progress; pasting with no active login hit a closed
  port and was silently ignored. The field now tells you to start the login
  first instead of appearing to hang.
- Session recovery did nothing on Linux. The "invalid grant" re-login and the
  "expired session" exit button both deleted the stale auth file at a hardcoded
  Windows path, which on Linux pointed nowhere, so the stale token was never
  cleared and the expired-session restart never ran. Both now use the correct
  per-platform path.
- The login could get stuck on the loading spinner if EA returned an "invalid
  grant" while no stored auth file was present; it now surfaces the error
  instead of hanging.
- EA sign-in errors are now shown in plain language with what to do next, and
  the full error text is selectable and scrollable instead of being cut off in
  the dialog.

### Changed

- The "Mod Configuration" settings tile is now labelled "Mods / Proton", since
  the custom Proton path setting lives there and Proton is Linux-specific.

## [0.1.0-beta.6.4] - 2026-06-04 - Steam Deck Support

Makes the launcher start on Steam Deck and SteamOS by dropping the bundled
webkit2gtk dependency, which was unused on Linux but crashed startup on
systems without a system webkit. Also shrinks the AppImage by about 47 MB
and makes the manual paste login easy to find on the Deck. A test/pre-release
hotfix; if it misbehaves, beta.6.3 stays a safe fallback.

### Fixed

- The launcher failed to start on Steam Deck/SteamOS with a "missing
  libwebkit2gtk" error. webkit2gtk (122 MB) was pulled in only by an unused
  webview plugin; the EA login uses the external browser, so webkit is never
  used on Linux. It also looks for helper processes at a hardcoded path that
  does not exist on immutable systems, so the process crashed before the UI.
  The webview plugin is now stubbed out on Linux and webkit is no longer
  bundled.

### Changed

- On Steam Deck/SteamOS the EA login's manual code field is shown expanded by
  default, with a hint, and can be reopened from the error screen if the first
  attempt times out. The Deck's Flatpak browser does not hand the qrc://
  callback back to the launcher, so pasting the code is the reliable path.
- Settings shows the unofficial Linux-port version next to the upstream Kyber
  client version.
- GTK input-method warnings on minimal systems are quieted.
- GDK_BACKEND can be set to wayland for native Wayland (default stays x11).

### Added

- A one-time hint on first launch on SteamOS/Steam Deck pointing at the paste
  login and the Distrobox alternative.

## [0.1.0-beta.6.3] - 2026-06-03 - Login Reliability

Fixes the EA login hanging forever on sandboxed browsers and Steam Deck,
adds a manual code fallback for when the browser callback never arrives,
and makes a silently-failing game launch finally report why it stopped.
If beta.6.3 misbehaves, beta.6.2 stays a safe fallback.

### Fixed

- EA login could hang forever with no feedback. Sign-in opens the system
  browser and waits for EA to hand the auth code back to a local callback
  server. If that callback never arrived, the launcher waited on the socket
  indefinitely and the login spinner never stopped. The wait now times out
  after 5 minutes with a clear error that names the workaround, and the
  local callback port is released so the next attempt can rebind it.

- The qrc:// login handler went stale after the first launch on installed
  AppImages. The launcher re-registered the handler on every start at the
  AppImage's temporary mount path, which changes each run, overwriting the
  stable handler the installer had set up. From the second launch on, the
  handler pointed at a dead path and the EA login callback silently failed.
  Packaged builds now keep the installer's stable handler instead of
  re-pointing it at the mount.

- A game launch that exited immediately logged only "Game stopped" with no
  reason, which made the recent "launches but nothing happens" reports
  impossible to diagnose. The launcher now logs the launch helper's exit
  status, so the log shows whether umu/Proton failed to start or the game
  itself exited right away.

- Two harmless exceptions were thrown on every Linux start and sent to crash
  tracking: a MissingPluginException from the protocol-handler plugin (which
  has no Linux backend; nxm:// links are handled by a separate watcher) and
  a gRPC "Invalid token" error from a module-version check that ran before
  login. Both are now guarded, so they no longer clutter the log or crash
  reports.

### Added

- Manual code entry for EA login. EA redirects the signed-in browser to a
  qrc:// link that the system is supposed to hand back to the launcher. A
  sandboxed browser (the default Flatpak build of Zen, for example, and most
  Steam Deck setups) routes that link through the desktop portal, which does
  not deliver an unregistered scheme like qrc:// to a host application, so
  the launcher never got the code. When the automatic callback does not
  arrive, the login screen now offers a field to paste the sign-in link or
  code straight from the browser. It is fed to the same local callback, so
  login completes without depending on the browser handing the link back. A
  native (non-sandboxed) default browser, or signing in to the EA app first,
  still works automatically.

## [0.1.0-beta.6.2] - 2026-05-27 - Custom Steam Path Detection

A hotfix on top of beta.6.1 for users whose Steam library lives outside
the default locations. If beta.6.2 misbehaves, beta.6.1 stays a safe
fallback.

### Fixed

- BF2 launches were silently broken on systems where Steam is installed
  in a non-standard path (for example `~/Games/Steam` instead of
  `~/.steam/steam`, `~/.local/share/Steam`, or `/mnt/Games/SteamLibrary`).
  The compatdata symlink setup probed a hardcoded list of library roots
  and missed those installs, even though Steam itself had BF2 registered
  via `libraryfolders.vdf`. Maxima's wine prefix then pointed at an empty
  directory and the launch hung with no UI feedback. Detection now reuses
  the same `libraryfolders.vdf` resolver that already finds the BF2
  install directory, and derives the compatdata path arithmetically from
  there. The hardcoded list stays as a fallback for environments where
  the vdf chain is missing. Users who set `STEAM_LIBRARY_ROOT` as a
  workaround on earlier releases can unset it.

## [0.1.0-beta.6.1] - 2026-05-25 - Wineserver Hotfix

A hotfix on top of beta.6 for one problem around switching Proton
versions, found from CachyOS bug reports on the day of the release.
If beta.6.1 is unstable on your machine, beta.6 stays a safe fallback.

### Fixed

- Switching Proton via Settings > Mod Configuration could silently leave
  BF2 unable to launch when a wineserver from the previous BF2 session
  was still attached to the Maxima prefix. The stale wineserver and the
  newly-routed Wine binary then fought over the prefix and the next
  launch hung with no UI feedback. The dialog now detects this case
  before writing the sidecar, shows a "Wineserver still running"
  confirmation, and offers a "Kill wineserver and retry" action. The
  kill is prefix-scoped, so wineservers belonging to other Wine games
  are never touched. No-op Save with the same Proton path is never
  blocked.

## [0.1.0-beta.6] - 2026-05-25 - Custom Proton Support

Adds an experimental custom Proton path option and automatic shader cache
invalidation when switching Proton versions. If beta.6 is unstable on your
machine, beta.5.1 stays a safe fallback.

### Added

- Custom Proton path setting under Settings > Mod Configuration. Point the
  launcher at any Proton build (GE-Proton, Proton-EM, proton-cachyos, etc.)
  instead of the bundled GE-Proton. Routing goes through a wine/proton symlink
  so save games and EA App login stay shared across Proton versions. The setting
  carries a visible warning that it leaves the tested-stable path. Verified
  working with GE-Proton 10.x, Proton-EM Latest, and proton-cachyos 11.x.
- Shader cache invalidation on Proton switch. BF2's vkd3d-proton.cache is
  cleared automatically when the active Proton version changes, preventing the
  yellow-stripe and shadow-flicker artifacts that appear when an old cache built
  against a different Wine/DXVK pipeline is reused. A manual "Clear shader
  cache" button in the Custom Proton dialog is also available.

## [0.1.0-beta.5.1] - 2026-05-22 - Launch Hotfix

A hotfix on top of beta.5 for three problems around starting BF2,
found from Discord bug reports. If beta.5.1 is unstable on your
machine, beta.5 stays a safe fallback.

### Fixed

- BF2 failed to inject on the first launch after a fresh install. The
  vivoxsdk.dll link into the Wine prefix was created before the prefix
  existed, so the first injection failed with Wine loader error 126.
  The link is now also placed right before injecting, when the prefix
  is guaranteed to exist. The second launch always worked; now the
  first one does too.
- The manual game-path override from beta.5 was ignored at launch.
  Install checks in the launcher and in Maxima still ran and rejected
  a hand-set BF2 path as not installed. Both are now skipped when an
  explicit path is set.
- The EA Desktop language patch never applied on a Maxima-managed Wine
  prefix. It looked under prefix/pfx/drive_c while the real location is
  prefix/drive_c, so on non-English hosts BF2 could still raise the
  Origin language-entitlement error.

## [0.1.0-beta.5] - 2026-05-22 - Stability and Voice

Fixes from the days after beta.4, mostly off CachyOS bug reports on
Discord.

### Fixed

- Starting BF2 could kill the launcher itself. When the game PID
  could not be resolved the launcher ran `killPid(0)`, which signals
  its own process group. Guarded now, and it routes to the recovery
  dialog instead.
- Connection drops. A 2-minute refresh timer checked the wrong thing
  and dropped a live session to Normal every two minutes. Also a
  DLL-connect grace window, stale-instance cleanup when gRPC goes
  unavailable, and a server-select race guard.
- Voice settings crashed in-game. The push-to-talk key could hold a
  value too large for a 32-bit field, which threw on every tick and
  flooded the log. The key is clamped now and unsupported keys are
  rejected in the picker.
- Proximity chat showed "no devices found" on Linux. The device list
  is pulled from the running game now, so input and output devices
  can be picked while in a match.

### Added

- Manual game-path override for BF2 installs that Steam
  auto-detection misses. In Settings and in the game-not-found
  dialog.
- CachyOS startup hint and a Vulkan pre-flight check, bundled as
  AppRun hooks. Warns when the system only has software rendering
  (llvmpipe) before the game launches into a crash.
- The game runs under feral gamemode when `gamemoderun` is on PATH,
  so the CPU governor stays on performance for the match. Wraps only
  the game launch, not the launcher. `KYBER_DISABLE_GAMEMODE=1` opts
  out.

### Changed

- Maxima: `KYBER_DISABLE_WINEGSTREAMER` is opt-in now, and wine
  stderr is captured on failure so bug reports carry more.
- The installer keeps downloaded mods, plugins and mod collections
  across an update now. cli/, locale/ and module/ still get
  refreshed, mods/ and launcher/ are left alone.

## [0.1.0-beta.4] - 2026-05-18 - Inject Path Fixed

Two inject bugs that aderius tracked down on Discord, both fixed now.

### Fixed

- wine-helper now runs through host wine64 directly. The old D-Bus
  container routing in `umu-wrapper.sh` only matched hex AppIDs, but
  BF2 is decimal 1237950, so it never worked. Diagnosed by aderius.
- `vivoxsdk.dll` gets symlinked into Wine's `system32` before each
  launch. Without it, Wine couldn't resolve `Kyber.dll`'s static
  import and the inject failed with OS error 126. Diagnosed by aderius.

### Added

- Recovery dialog when the inject fails. Was a silent notification
  before. Now you get Retry and "Use CLI Launch" buttons, plus the
  raw error to copy for bug reports. BF2 is killed cleanly before
  the retry.
- `--playmode` flag on the AppImage. Skips the launcher and starts
  BF2 directly through Steam. Last resort if nothing else works.

### Changed

- First-start dialog is English everywhere now (German systems were
  getting "Ja/Nein" against an English prompt).
- Self-install no longer re-extracts the AppImage on every launch.
  A marker inside the extract dir plus `cp -p` for mtime preserve
  keeps things in sync.
- `notify-send` fires before and after the extract so the launcher
  doesn't look frozen during that step.
- Icon isn't stretched anymore. The Kyber SVG is 166x144, the build
  script used to force it into a square box.

### Internal

- `umu-wrapper.sh` checks `wine64` exists before exec.
- `kyber-self-install.sh` guards its `--appimage-extract` call against
  recursive triggering on FUSE3-only distros.
- CLI fallback (`startGameViaCli`) is now public, only invoked from
  the recovery dialog. The CLI path doesn't run the full locale lock,
  so BF2's Origin language dialog can still show up there.


## [0.1.0-beta.3] - 2026-05-17 - Fresh-Prefix BF2 Detection Fix

Quick follow-up release because CachyOS testers (and anyone with a
fresh-out-of-the-box Steam-Proton install) were hitting a "GAME NOT
FOUND" dialog even though BF2 was clearly installed and the Proton
prefix was sitting right there.

### Fixed

- Launcher now writes the `Software\EA Games\STAR WARS Battlefront II`
  Wine registry section itself on every game launch, instead of relying
  on the EA installer having run at some point. On Linux, Steam-Proton
  never runs the EA installer, so on a clean prefix that registry key
  simply does not exist, and Maxima's `is_installed()` check fails. The
  install directory is resolved from Steam's library metadata
  (`read_game_path("bf2")`), formatted as a Wine `Z:`-path, and written
  to both the regular and `WoW6432Node` versions of the key. Behaviour
  for users with an already-existing entry is unchanged.
- A few diagnostic loglines that were silently swallowed now actually
  show up at `WARN` level when the Steam-library lookup can't find BF2
  - useful if your setup needs `STEAM_LIBRARY_ROOT` to point at a
  non-default library path.

### Internal

- README rewritten in a less corporate tone, with the install/build
  sections trimmed down to what actually matters. AI-flavoured comments
  in `linux_setup.rs` and the Maxima registry helpers got cleaned up
  in the same pass.
- Spelling pass: "unofficial" instead of the older "inofficial"
  everywhere in the source tree (README, in-app strings, build scripts).

## [0.1.0-beta.2] - 2026-05-09 - Locale Lock, Cold-Start, Bazzite/Fedora Compat

### Added
- **Steam game-path auto-detection** - `read_game_path()` is now
  implemented for Linux in the bundled Maxima patch set. The previous
  `todo!()` stub caused the launcher's `get_game_dir(slug)` FFI call to
  return an empty string on Linux, blocking any feature that needed the
  installed BF2 directory. The new implementation maps known BF2 slugs
  (`bf2`, `swbf2`, `starwarsbattlefront2`, `STAR WARS Battlefront II`,
  …) to Steam app id `1237950`, walks the Steam library candidates in
  the same order as `linux_setup.rs` (with `STEAM_LIBRARY_ROOT` env
  override and Flatpak Steam added), parses `libraryfolders.vdf` and
  the per-game `appmanifest_<id>.acf` with a small inline regex parser
  (no new Cargo dependency), and returns
  `<library>/steamapps/common/<installdir>/`. macOS keeps a separate
  `todo!()` stub. Inline unit tests cover the slug map and both
  parsers.
- **AppImage container self-update (configurable endpoint)** - new
  `AppImageUpdateService` updates the AppImage file itself, not just
  the in-app module bundle. Runs only when launched from an AppImage
  (`$APPIMAGE` env present) and an update endpoint is configured via
  `KYBER_UPDATE_URL` (no default - Source repo is private, so the
  classic `gh-releases-zsync` flow does not apply yet). Manifest format
  is JSON `{version, download_url, sha256}`. The service downloads to
  `${APPIMAGE}.new.<tag>`, verifies SHA-256, `chmod 0755`, atomic
  renames over the running file, and exec's into it. Version comparison
  uses semver via the existing `version` package - bare string equality
  was insufficient because `PackageInfo.buildNumber` is undefined on
  Linux/AppImage builds and would have either masked legitimate updates
  or triggered them on every boot. `$APPIMAGE` is canonicalised through
  `resolveSymbolicLinksSync()` so the rename hits the real file even
  when the user invokes the AppImage via a symlink. Before exec'ing the
  new binary the service verifies it is executable (`test -x`) - on
  `noexec` mounts (`~/Applications/` on a data partition) chmod sets
  the inode bit but `execve()` still fails, so the running launcher
  aborts the restart and survives instead of leaving the user with no
  process. Original `Platform.executableArguments` are forwarded to the
  new instance so `--server` and protocol-handler invocations
  (`kyber qrc://...`) survive the restart. Wired through
  `injection_container.dart` and called from
  `app_initialization_service.dart` ahead of the existing in-app
  module update check, so a freshly downloaded image hands off to the
  new launcher version on first boot. The legacy
  `LinuxSelfUpdateService` keeps handling in-app module updates and is
  not affected by this change.

### Fixed
- **BF2 "language not entitled" entitlement error** - the layered Wine
  registry locale-lock (`maxima-lib/src/unix/wine.rs`) now writes
  `HKCU\Environment\LANG`/`LC_ALL=en_US.UTF-8`, propagates an explicit
  English locale on the `maxima-bootstrap` spawn (`core/launch.rs`),
  and re-applies the four locale-critical keys
  (`HKCU\Control Panel\International\{Locale,LocaleName,sLanguage}`,
  `HKCU\Software\Valve\Steam\language`) just-in-time before the BF2
  spawn. A new `verify_locale_is_english()` probe queries the live
  registry values via `reg query` so a regression now leaves a paper
  trail in the launcher log instead of being a silent prefix-state
  mystery. Critical-failure entries (BF2 catalog, Origin Games,
  Control Panel\International, Valve\Steam) abort the launch hard
  with a typed error rather than `Ok(())` after a swallowed warning.
  Verified live: all four critical keys read back as English at spawn
  time on a German-locale host (`LANG=de_DE.UTF-8`).

### Performance
- **Verify-first locale skip** - `setup_wine_registry()` and the
  pre-spawn JIT lock now run a four-key `reg query` pre-flight via
  `verify_locale_is_english()` and short-circuit both write paths
  when the prefix is already in the desired English state. On warm
  launches (the common case once a previous launch succeeded) this
  avoids 19 sequential `reg add` calls through umu-run +
  pressure-vessel - measured launch overhead drops from ~73s to ~24s
  (-49s, -67%). Cold launches and tampered prefixes fall through to
  the full write path unchanged. Each individual umu-run call is
  ~3s of pressure-vessel container spawn dominated; the optimisation
  works by removing redundant calls, not by changing how each call
  works.
- **Pre-spawn verify removed** - the four-key `reg query` probe in
  `Kyber/ThirdParty/Maxima/maxima-lib/src/core/launch.rs` (between
  `setup_wine_registry()` and the bootstrap spawn) was a strict
  duplicate of the pre-flight verify already performed at the top of
  `setup_wine_registry()`, with license-fetch / cloud-sync between the
  two not touching the Wine registry. Removing it saves ~14s of
  umu-run round-trips on every game launch (warm and cold). If the
  language-entitlement regression ever returns the recovery path is a
  single-key probe of `HKCU\Software\Valve\Steam\language` (the only
  key Steam itself sometimes rewrites between launches) - see the
  comment block at the spawn site for the recipe.
- **Launcher window refocus on game exit** - `IngameViewCubit.unloadServer()`
  in `lib/features/server_browser/providers/ingame_view_cubit.dart`
  now calls `windowManager.restore() + .show() + .focus()` after the
  LSX stream completes. BF2 takes the foreground when it launches and
  on a typical Linux DE the launcher window stays minimised in the
  task bar after the game exits - the user landed on the desktop
  instead of back in the launcher. Refocusing is gated to Linux and
  Windows; macOS retains its own window-management semantics. Errors
  from `windowManager` are swallowed and logged at warning level so a
  flaky Wayland implementation cannot block the cubit's normal
  cleanup path.

- **Cold-start direct-file registry patch** -
  `Kyber/Launcher/rust/src/linux_setup.rs` now ships
  `patch_wine_registry_for_bf2()` which writes the BF2 locale-critical
  keys (`HKCU\Control Panel\International`, `HKCU\Software\Valve\Steam`,
  `HKCU\Environment`, `HKLM\Software\Electronic Arts\EA Desktop`,
  `HKLM\Software\Origin`, `HKLM\Software\Origin Games\1035052`,
  `HKLM\Software\WoW6432Node\Origin Games\1035052`) directly into the
  Wine prefix's `user.reg` / `system.reg` files via in-place text
  edits. Replaces (or appends) keys, replaces (or appends) entire
  sections - runs in &lt;100 ms vs. the ~45s the equivalent 15
  sequential `reg add` calls through umu-run + pressure-vessel cost
  in `setup_wine_registry()`. Combined with the verify-first skip
  above, a cold launch on an existing Wine prefix drops from ~87s
  to ~13s (-74s, -85%). The patch is invoked from `init_app()` and
  again from `start_game()` (covers the case where the prefix was
  freshly created by the bootstrap between the two calls). It
  detects a running `wineserver` via `pgrep -x wineserver` and
  skips itself when active - Wine serialises the registry on
  shutdown and would otherwise clobber our direct writes. On a
  brand-new Wine prefix where the registry files do not exist yet
  the patch is a no-op and the existing `setup_wine_registry()`
  umu-run path runs full as before; the cold-start regression is
  bounded to the very first launch on a fresh install.

### AppImage pipeline
- **Type-2 runtime for Bazzite / Fedora-atomic / Silverblue / Kinoite
  out-of-the-box support** - `tools/build-appimage.sh` now embeds the
  type-2 runtime from `AppImage/type2-runtime` (commit `3d17002`,
  `tools/type2-runtime-x86_64`, ~944 KB, statically PIE-musl-linked) via
  `appimagetool --runtime-file`. The default `appimagetool` runtime is
  FUSE2-only and silently fails to mount on immutable Fedora-based
  distributions where `libfuse2` is not installable. The type-2 runtime
  probes FUSE3 first, falls back to FUSE2, and auto-degrades to
  `--appimage-extract-and-run` when neither is available. Net effect:
  one AppImage that boots out-of-the-box on Ubuntu (incl. 24.04 with
  AppArmor caveats), Fedora (Workstation + Silverblue + Kinoite + Bazzite),
  Arch + derivatives. The runtime is musl-statically linked so glibc
  version is irrelevant - only kernel ≥ 4.x is required.
  - `xxd` of the built AppImage now shows `AI\x02` at byte offset 8
    (Type-2 magic), and `--appimage-version` reports the type-2 commit
    hash.
  - Build falls back to the bundled FUSE2-default runtime with a clear
    warning when `tools/type2-runtime-x86_64` is missing on a fresh
    checkout.
  - Verified on the maintainer's Ubuntu box via the `APPIMAGE_EXTRACT_AND_RUN=1`
    proxy test that simulates the no-FUSE path.
  - Known limitations (documentation only - no code fix possible):
    `tmpfs` on `/tmp` smaller than 2 GB will refuse the extract-mode
    fallback (workaround: `TMPDIR=$HOME/.cache/kyber-tmp ./AppImage`),
    and AppImages on NTFS / exFAT partitions hit `noexec` mounts
    (workaround: keep on the home filesystem).

### Security
- **Self-update hardening: mandatory SHA-256, path-traversal block,
  atomic lock** - three security-relevant fixes in
  `LinuxSelfUpdateService`:
  - The server's SHA-256 hash is now mandatory; tarballs without an
    advertised hash are rejected instead of being accepted with a
    warning. Combined with the previous behaviour this had been an
    unverified-download path that could chain into the issue below.
  - `_extractTarGz` now validates every archive entry before delegating
    to `extractArchiveToDisk`. Entries whose canonicalised target
    escapes the staging directory (`../../etc/...`) are refused, and
    symbolic links inside the archive are refused outright.
  - The flock acquired in `claim()` switched from
    `FileLock.blockingExclusive` to `FileLock.exclusive` (non-blocking).
    Two concurrent self-updates now fail fast on the second instance
    instead of serialising launcher boots behind an in-progress
    multi-minute download.

## [0.1.0-beta.1] - 2026-05-08 - First Private Beta

First tagged build of the unofficial Kyber Linux Port. Distributed as a
self-installing AppImage to a closed group of testers; not for general
release. Source for this tag is GPLv3 - see `LICENSE`.

### Added
- `CHANGELOG.md` (this file) as the central change history for the Linux port.
- **Self-installing AppImage** - first-run desktop integration without a
  separate install script. The AppRun now sources a new
  `apprun-hooks/kyber-self-install.sh` before `linuxdeploy-plugin-gtk.sh`
  (so dialog tools load the system GTK, not the bundled one). On first
  start it asks via zenity/kdialog whether to register Kyber as an
  application and, on confirm, copies the AppImage to `~/Applications/`,
  extracts a stable copy for the qrc:// and nxm:// URL handlers, installs
  the hicolor icon set, writes the three `.desktop` entries, refreshes
  the desktop and icon caches, and registers the MIME handlers - all
  under `$HOME`, no sudo. A marker file at
  `~/.local/share/kyber-linuxport/.installed-version` (size+mtime of the
  AppImage) makes subsequent starts a fast no-op; on version updates the
  hook silently re-installs. A separate `.declined-version` marker
  remembers a "no" choice for the same AppImage so the dialog doesn't
  reappear on every launch. Set `KYBER_NO_AUTO_INSTALL=1` to skip the
  hook (CI / packaging contexts). `tools/install-appimage.sh` is still
  shipped as the manual fallback for headless or restricted setups.

### Changed
- SPDX license identifiers in self-authored files consolidated to
  `GPL-3.0-only` (previously inconsistent: `GPL-3.0-or-later` / `GPL-3.0`).
  Vendored cli_payload scripts retain their upstream `GPL-3.0-or-later`
  headers (the headers reflect the original ACowAdonis tarball license);
  the aggregate work is conveyed under `GPL-3.0-only`, which is a permitted
  choice within an `or-later` upstream.
- `NOTICE.md`: explicit aggregation-license clause and statement of
  the vendored-file header policy.
- Replaced proprietary fonts:
  - **Univers Next Pro Medium Condensed** (Linotype/Monotype, all rights
    reserved) → **Barlow Condensed Medium / MediumItalic** (SIL OFL 1.1,
    https://github.com/jpt/barlow). The `BattlefrontUI` family name in
    `pubspec.yaml` is retained, so no Dart code change was required.
  - **Aurebesh** by Pixel Sagas Foundry (proprietary "all rights reserved")
    → **Aurebesh Rodian** by AurekFonts (MIT,
    https://github.com/AurekFonts/Aurebesh_Rodian).
  - License files (`Barlow-OFL.txt`, `AurebeshRodian-LICENSE.txt`) are
    bundled alongside the font files as required by OFL §1 and MIT.

### Fixed
- Kyber-Module debug-console window ("`KYBER (2.0.0-beta8)`") opening on
  every game launch on Linux. Fix: the launcher now sets
  `KYBER_HIDE_CONSOLE=1` in the env map of the `kyber_cli` subprocess
  (`maxima_helper.dart`). Logs continue to be written to `kyber.log` -
  only the on-screen console is suppressed, matching the Windows GUI
  default.
- Console-window suppression made effective: empirical verification via
  `/proc/<bf2-pid>/environ` showed that the BF2 process inside the
  pressure-vessel container does NOT inherit Linux-side env vars (Dart
  `Process.start` environment, kyber_cli env, umu-wrapper `export` - none
  reach BF2). Workaround: `umu-wrapper.sh` now writes
  `KYBER_HIDE_CONSOLE=1` into the Wine registry under `HKCU\Environment`
  immediately before launching BF2. Wine seeds the Win32 PEB env from
  this registry key at process start, so Kyber.dll's `std::getenv` check
  in `Program.cpp:139` finally sees the variable.
- `wine.rs::run_wine_command` (in both Maxima submodules,
  `Kyber/ThirdParty/Maxima/` and `Kyber/CLI/ThirdParty/Maxima/`):
  detached stdin (`Stdio::null()`) and silenced stderr / stdout for
  silent invocations, so Wine no longer pops up a `wineconsole` for
  console-subsystem helpers like `wine-helper.exe`.
- **Mod download leading-slash bug on Linux** - every mod download
  failed with `PathNotFoundException: Cannot open file, path =
  'home/<user>/.local/share/kyber/mods/<mod>.zip.download'` (note the
  missing leading `/`). `download_orchestrator.dart:219-220` was
  prepending `/` to the absolute base path only on macOS to compensate
  for the `background_downloader` plugin stripping the leading slash
  when `BaseDirectory.root` is used; the same compensation is required
  on Linux. Fix: extend the conditional to
  `Platform.isMacOS || Platform.isLinux`. Windows, which uses drive-letter
  absolute paths (`C:\...`), continues to need no prefix.

### Compliance
- GPLv3 pre-release audit completed (mandatory items A1-A5 plus B1-B7).
- `linux_self_update_service.dart`: SPDX header added.
- `Launcher/rust/Cargo.toml` and `CLI/rust/Cargo.toml`: `license` field
  added.
- About dialog: `applicationLegalese` updated; a Kyber Linux Port entry
  registered via `LicenseRegistry.addLicense()`; source URL linked in
  About.
- `wine-helper.exe`: §6(b) written-offer documented in
  `Kyber/CLI/cli_payload/README.md` (request via GitHub Issues).
- Maxima submodule patches committed on `linux-port-patches` branches in
  both submodule trees, with `CHANGES.md` carrying the §5(a) modification
  notice.

### AppImage pipeline (initial distribution)
- `tools/install-appimage.sh` companion script: removes stale .desktop
  entries / icons from previous source-build and `.deb` installs, copies
  the AppImage to `~/Applications/`, extracts a static copy for stable URL
  handlers, writes three `.desktop` files (main launcher + qrc handler
  for EA login redirects + nxm handler for Nexus Mods downloads), refreshes
  the desktop and icon caches, and registers the qrc/nxm scheme defaults.
  Idempotent. Wine prefix at `~/.local/share/maxima/` is left untouched.
  `tools/uninstall-appimage.sh` reverses everything except the prefix.
- `tools/build-appimage.sh` recipe: assembles the AppDir from the Flutter
  release bundle, embeds the GPL `LICENSE`, `NOTICE.md`, `CHANGELOG.md`
  and a `usr/share/doc/kyber-bf2/source-url.txt` (GPLv3 §6(d)).
- Bundled `libpixbufloader-svg.so` + `librsvg-2.so.2` + `libxml2.so.2`
  manually because `linuxdeploy-plugin-gtk` skips them (they bring in
  large extra deps). Without the SVG loader GTK crashes on first attempt
  to render `image-missing.svg` from the system icon theme. The
  `loaders.cache` is regenerated post-copy with paths relative to
  `AppDir`.
- Post-linuxdeploy `patchelf --set-rpath '$ORIGIN/lib'` step on
  `usr/bin/kyber_launcher`: linuxdeploy rewrites the Flutter binary's
  RUNPATH to `$ORIGIN/../lib`, which breaks dynamic loading of bundle-local
  Flutter plugins (rhttp, media_kit, etc.) that the Dart side opens via
  `DynamicLibrary.open('libfoo.so')` by bare filename. Restoring
  `$ORIGIN/lib` keeps the Flutter convention while still letting the GTK
  system deps in `usr/lib/` resolve via the GTK libs' own NEEDED entries.
- Source tarball (`git archive --recurse-submodules`) attached as a
  release asset alongside the AppImage.

---

[0.1.0-beta.6]: https://github.com/simonlinuxcraft/kyber-linuxport-unofficial/compare/v0.1.0-beta.5.1...v0.1.0-beta.6
[0.1.0-beta.5.1]: https://github.com/simonlinuxcraft/kyber-linuxport-unofficial/compare/v0.1.0-beta.5...v0.1.0-beta.5.1
[0.1.0-beta.5]: https://github.com/simonlinuxcraft/kyber-linuxport-unofficial/compare/v0.1.0-beta.4...v0.1.0-beta.5
