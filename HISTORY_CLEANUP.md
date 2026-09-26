# Public history cleanup — 26 September 2026

With maintainer approval, both published branches (`CKG_development` and `master`)
were rewritten to remove deployment details from earlier commits. A recovery
bundle and the old-to-new commit map are held outside the public repository.
Upstream authorship and license notices are retained.

The rewrite removes local scheduler/container scripts, old deployment notes,
compiled Python and generated documentation caches. It clears notebook outputs
and execution metadata, replaces machine-specific paths and legacy private share
links, removes automatic email destinations, blanks bundled database passwords,
and replaces the historical deployment password wherever its literal occurs in
text. Malformed historical notebooks that cannot be cleaned reliably are omitted.

The pre-publication audit read every reachable object on both rewritten branches:
977 retained commits, 3,990 unique file blobs and 92 notebook versions. No matches
remained for the audited machine-path, deployment-marker, private-share-link,
known-password or recognizable key/token patterns; notebook checks found no saved
code-cell outputs. Commits made empty by removing generated/private material were
pruned. These are scoped checks, not a guarantee about arbitrary binary content.

**Use a fresh clone after this rewrite.** Do not merge or push the old branch
history back into this repository. Preserve uncommitted work separately and
reapply only reviewed changes to a fresh clone.

Rewriting branch references cannot erase someone else's clone, upstream forks,
or GitHub's cached objects. GitHub may still resolve old commit URLs; full removal
of cached sensitive objects requires the provider's support process. If an old
published password was reused in a live deployment, replace it there separately;
rewriting Git history does not change running database credentials.

See [GitHub's history-removal guidance](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository).
