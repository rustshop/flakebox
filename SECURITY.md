# Flakebox shared-state trust model

Flakebox generates executable development policy and can install Git hooks into
repository-owned shared state. Treat the Flakebox configuration, immutable Nix
candidate, generated worktree files, and people allowed to change them as
trusted at the same level as repository code. Review changes to these inputs
before entering the development shell or installing hooks.


## Git hook ownership and worktrees

Linked worktrees share one Git common directory and hook directory. Flakebox
reserves these common-directory paths:

```text
flakebox-install-hooks.lock
hooks/flakebox/pre-commit
hooks/flakebox/commit-msg
hooks/pre-commit -> flakebox/pre-commit
hooks/commit-msg -> flakebox/commit-msg
```

The files under `hooks/flakebox/` are dispatchers, not project policy. A
dispatcher resolves the worktree where Git invoked it and executes that
worktree's `misc/git-hooks/<name>` file only when an enablement marker exists in
that worktree's Git directory. The immutable candidate updates this marker, so a
disabled worktree no-ops even if generated files remain stale. It does not
remove shared state another worktree needs. Flakebox does not remove shared
dispatchers automatically; repository-wide cleanup requires the owner to inspect
`git worktree list` and verify that every linked worktree has disabled the
integration.

`flakebox install-hooks` installs only the two reserved top-level symlinks when
its immutable candidate enables them. It replaces an existing entry only when
the link already has the reserved dispatcher target or the invoking worktree's
exact legacy generated-hook target. It refuses regular files and foreign links.
A disabled candidate does not replace or remove shared hooks owned by another
tool. During migration, it removes an old direct link only when that same exact
legacy ownership proof holds. A similar target elsewhere may belong to another
worktree or tool, so Flakebox preserves it and stops with explicit inspection
guidance instead of guessing from a path suffix.

Template enablement uses Git's worktree configuration. An enabled template
requires the repository-local extension `extensions.worktreeConfig`; a global
setting is intentionally insufficient. Flakebox removes the standard redundant
local `core.bare=false`, refuses activation when other local `core.bare` or
`core.worktree` settings require manual migration, enables the extension, and
migrates an exact legacy Flakebox template value out of shared local
configuration. Disablement does not enable the extension; it unsets an existing
worktree value only when every byte matches Flakebox's value. Foreign worktree,
local, and global values remain unchanged.

The installer separates validation from mutation. Under its common-directory
lock, it builds a validated plan for every enabled and disabled hook plus all
template and worktree-config ownership safeguards before changing any hook,
dispatcher, marker, or Git configuration. Validation includes dormant
`config.worktree` content that enabling `extensions.worktreeConfig` would
activate. Markers require a regular file with exact Flakebox content and mode.
Dispatchers require either the same byte-and-mode match or a regular file plus
the installed reserved hook link as independent ownership evidence.
Byte-identical symlinks remain foreign. A foreign worktree template is refused
rather than overwritten.
An I/O failure during the later multi-artifact apply phase can still leave a safe
partial installation. Rerunning converges owned destinations. If an error says
that an exclusively created temporary path was preserved, inspect and remove that
named path explicitly; Flakebox never guesses that an occupied temporary path is
safe to delete.

Git's `core.hooksPath` can redirect hook lookup away from the common hook
directory. Flakebox does not override or validate that setting. Repository
owners who configure an external hook path must arrange equivalent enforcement;
CI remains the authoritative policy gate.


## Serialization and atomicity

Explicit installers take an operating-system advisory lock on the persistent
`flakebox-install-hooks.lock` file in the Git common directory. The persistent
file needs no stale-lock recovery: the operating system releases the lock when
the process exits. The lock serializes Flakebox installers only; unrelated
programs do not have to honor it.

After acquiring the lock, the installer re-reads candidate and installed state.
It creates each neighboring temporary path exclusively and never removes an
unexpected occupant. Immediately before a destructive destination operation, it
checks that the destination still has the state captured by the validated plan,
then renames the complete temporary entry into place. A hook reader therefore
sees the complete old entry or the complete new entry. Git protects configuration
replacement with its own `config.lock` transaction.

The Flakebox lock does not exclude unrelated writers. Revalidation prevents
ordinary changes between planning and apply from being silently overwritten, but
portable filesystem APIs cannot make the final check and replacement one
conditional atomic operation. An adversarial writer can still win that narrow
TOCTOU window or change an entry after installation. Git configuration uses
rolling snapshots: the installer revalidates the affected config file immediately
before each Git transaction, then captures the resulting bytes for the next
transaction. Removals also match the exact Flakebox value, so an intervening
foreign value is not selected for deletion. A writer can still race within one
check-and-Git-command interval or make a command fail. These races can leave a
partial Flakebox installation, but the installer does not claim transactionality
against processes that ignore its lock.

Installation updates multiple entries and is not one transaction across every
hook and configuration. A process failure can leave a mix of old and new
entries. Re-run `flakebox install-hooks`; its comparisons skip correct entries
and converge the remaining Flakebox-owned destinations. A failed write or rename
can preserve its named PID-scoped temporary entry to avoid deleting a path an
outside writer may have replaced. Inspect and remove that temporary explicitly.


## Verification and revisit triggers

`checks/git-hooks.nix` verifies read-only shell inspection, byte-exact effective
template precedence, repository-local extension activation, unusual core-setting
refusal, ownership-preserving granular disablement, stale-file-resistant
linked-worktree dispatch and policy isolation, idempotence, atomic replacement,
and concurrent explicit installers. The flake check matrix runs this behavior
on supported hosts, and configured CI checks remain authoritative when local
hooks are missing or redirected.

Revisit this model when Flakebox changes its common-directory layout, hook
ownership rules, dispatcher lookup, locking primitive, configuration scope,
`core.hooksPath` handling, generated-code trust boundary, or supported Git
worktree behavior.
