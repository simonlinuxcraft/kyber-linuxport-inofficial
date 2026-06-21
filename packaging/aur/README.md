# AUR packaging

Mirror of the `kyber-launcher-unofficial-appimage` AUR package so packaging
changes can be reviewed as pull requests. The AUR has no PR mechanism, so this
copy is the review/edit source; the AUR git stays the push target.

Push target: `ssh://aur@aur.archlinux.org/kyber-launcher-unofficial-appimage.git`

## Contributing PKGBUILD changes

Open a PR against this folder. Review focuses on the `package()` logic.
`pkgver` and `sha256sums` here track the last release and will lag between
releases; do not block a PR on them, they are finalized at push time.

## Releasing to AUR

After merging a PR and publishing the matching GitHub release:

1. Clone the live AUR repo fresh (not a stale local copy):
   `git clone ssh://aur@aur.archlinux.org/kyber-launcher-unofficial-appimage.git`
2. Copy the merged `PKGBUILD` and `.install` from here into the clone.
3. `updpkgsums && makepkg --printsrcinfo > .SRCINFO`
4. `makepkg -si` to confirm it builds and installs.
5. Commit `PKGBUILD .SRCINFO` (and `.install` if changed) and push.

Keep this copy and the AUR git in sync. A stale mirror is worse than none.
