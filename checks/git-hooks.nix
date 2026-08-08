{
  pkgs,
  flakeboxLib,
  mkLib,
}:

let
  timer = pkgs.callPackage ../lib/pkgs/git-hook-check-timer.nix { };

  mkHookFixture =
    hooks:
    (mkLib pkgs {
      config.git = {
        pre-commit = {
          trailing_newline = false;
          trailing_whitespace = false;
          hooks = pkgs.lib.mkForce hooks;
        };
        commit-msg.enable = false;
        commit-template.enable = false;
      };
    }).root;

  timedHooks = mkHookFixture {
    "a-slow" = ''
      printf 'a-slow\n' >> "$FLAKEBOX_TEST_LOG"
      touch "$FLAKEBOX_TEST_LOG.a-ready"
      while [ ! -e "$FLAKEBOX_TEST_LOG.c-ready" ]; do sleep 0.01; done
      printf 'slow stdout\n'
      printf 'slow stderr without newline' >&2
      sleep 2
    '';
    "b-fast" = ''
      printf 'b-fast\n' >> "$FLAKEBOX_TEST_LOG"
      printf 'fast stdout without newline'
      printf 'fast stderr without newline' >&2
    '';
    "c-slow" = ''
      printf 'c-slow\n' >> "$FLAKEBOX_TEST_LOG"
      touch "$FLAKEBOX_TEST_LOG.c-ready"
      while [ ! -e "$FLAKEBOX_TEST_LOG.a-ready" ]; do sleep 0.01; done
      sleep 2
    '';
    "d-slow-nul" = ''
      printf 'd-slow-nul\n' >> "$FLAKEBOX_TEST_LOG"
      printf '\0' >&2
      sleep 2
    '';
  };

  queueHooks = mkHookFixture {
    "a-blocker" = ''
      sleep 1.2
    '';
    "b-fast-after-queue" = ''
      true
    '';
  };

  backgroundHooks = mkHookFixture {
    background = ''
      sleep 30 </dev/null >/dev/null 2>/dev/null &
      printf '%s\n' "$!" > "$FLAKEBOX_BACKGROUND_PID"
    '';
  };

  shellcheckHooks = mkHookFixture {
    inherit (flakeboxLib.config.git.pre-commit.hooks) shellcheck;
  };

  gitDisabledLib = mkLib pkgs {
    config = {
      git.enable = false;
      github.ci.enable = true;
    };
  };

  preCommitDisabledLib = mkLib pkgs {
    config = {
      git.pre-commit.enable = false;
      github.ci.enable = true;
    };
  };

  commitMsgDisabledLib = mkLib pkgs {
    config.git.commit-msg.enable = false;
  };

  commitTemplateDisabledLib = mkLib pkgs {
    config.git.commit-template.enable = false;
  };

  gitEnabledCiLib = mkLib pkgs {
    config.github.ci.enable = true;
  };

  stashHooks = mkHookFixture {
    stash-probe = ''
      grep -qx staged tracked.txt
    '';
  };

  stashFailureHooks = mkHookFixture {
    stash-failure = ''
      grep -qx staged tracked.txt
      return 42
    '';
  };

  jjHooks = mkHookFixture {
    jj-probe = ''
      grep -qx unstaged unstaged.txt
    '';
  };

  interruptHooks = mkHookFixture {
    interrupt = ''
      printf ready > "$FLAKEBOX_INTERRUPT_READY"
      while true; do :; done
    '';
  };

  failureHooks = mkHookFixture {
    fail-one = ''
      printf 'fail-one\n' >> "$FLAKEBOX_TEST_LOG"
      return 1
    '';
    fail-42 = ''
      printf 'fail-42\n' >> "$FLAKEBOX_TEST_LOG"
      return 42
    '';
    success = ''
      printf 'success\n' >> "$FLAKEBOX_TEST_LOG"
    '';
  };

  usabilityHooks =
    (mkLib pkgs {
      config.git = {
        pre-commit = {
          trailing_newline = false;
          trailing_whitespace = false;
          hooks = pkgs.lib.mkForce {
            fail-pre-commit = ''
              printf 'pre-commit ran\n' >> "$FLAKEBOX_TEST_LOG"
              return 41
            '';
          };
        };
        commit-msg.hooks = pkgs.lib.mkForce {
          fail-commit-msg = ''
            printf 'commit-msg ran\n' >> "$FLAKEBOX_TEST_LOG"
            exit 42
          '';
        };
        commit-template.enable = false;
      };
    }).root;

  emptyHooks = mkHookFixture { };
in
assert pkgs.lib.elem timer flakeboxLib.config.env.shellPackages;
assert flakeboxLib.config.git.enable;
assert gitDisabledLib.config.git.pre-commit.enable;
assert gitDisabledLib.config.git.commit-msg.enable;
assert gitDisabledLib.config.git.commit-template.enable;
assert !(pkgs.lib.elem timer gitDisabledLib.config.env.shellPackages);
assert
  !(pkgs.lib.hasInfix "hooks/pre-commit" (
    builtins.concatStringsSep "\n" gitDisabledLib.config.env.shellHooks
  ));
assert
  !(pkgs.lib.hasInfix "hooks/commit-msg" (
    builtins.concatStringsSep "\n" gitDisabledLib.config.env.shellHooks
  ));
assert
  !(pkgs.lib.hasInfix "git config commit.template" (
    builtins.concatStringsSep "\n" gitDisabledLib.config.env.shellHooks
  ));
pkgs.runCommand "git-hooks-tests"
  {
    nativeBuildInputs = [
      pkgs.bash
      pkgs.cargo
      pkgs.coreutils
      pkgs.git
      pkgs.gnugrep
      pkgs.gnused
      pkgs.parallel
      timer
      flakeboxLib.flakeboxBin
    ]
    ++ pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.util-linux ];
  }
  ''
    set -euo pipefail
    export GIT_PAGER=cat

    pre_commit="${flakeboxLib.root}/misc/git-hooks/pre-commit"
    first_line="$(head -n 1 "$pre_commit")"
    if [ "$first_line" != "#!/usr/bin/env bash" ]; then
      echo "pre-commit shebang must be on line 1, got: $first_line" >&2
      exit 1
    fi

    second_line="$(sed -n '2p' "$pre_commit")"
    third_line="$(sed -n '3p' "$pre_commit")"
    if [ "$second_line" != "#" ] || [ "$third_line" != "# NOTE: THIS FILE IS AUTO-GENERATED BY FLAKEBOX" ]; then
      echo "pre-commit generated banner must immediately follow the shebang" >&2
      exit 1
    fi

    bash -n "$pre_commit"
    ! grep -q check_nothing "$pre_commit"
    grep -q '^    flakebox-git-hook-check-timer "\$1"$' "$pre_commit"
    ! grep -q '/nix/store/.*flakebox-git-hook-check-timer' "$pre_commit"
    ! grep -q 'Skipping semgrep check' "$pre_commit"

    commit_msg="${flakeboxLib.root}/misc/git-hooks/commit-msg"
    first_line="$(head -n 1 "$commit_msg")"
    if [ "$first_line" != "#!/usr/bin/env bash" ]; then
      echo "commit-msg shebang must be on line 1, got: $first_line" >&2
      exit 1
    fi
    bash -n "$commit_msg"

    [ -e "${flakeboxLib.root}/misc/git-hooks/commit-template.txt" ]
    shell_hook="${flakeboxLib.root}/.config/flakebox/shellHook.sh"
    grep -q "flakebox install-hooks" "$shell_hook"
    ! grep -q 'git config commit.template' "$shell_hook"
    ! grep -Eq '(^|[[:space:]])(ln|rm|mkdir)([[:space:]]|$)' "$shell_hook"
    grep -q 'hooks/pre-commit' "${flakeboxLib.root}/justfile"
    grep -q 'misc/git-hooks/pre-commit' \
      "${gitEnabledCiLib.root}/.github/workflows/flakebox-ci.yml"

    # The grouped opt-out omits every generated commit integration artifact and
    # every installer/configuration action and generated consumer.
    [ ! -e ${gitDisabledLib.root}/misc/git-hooks/pre-commit ]
    [ ! -e ${gitDisabledLib.root}/misc/git-hooks/commit-msg ]
    [ ! -e ${gitDisabledLib.root}/misc/git-hooks/commit-template.txt ]
    disabled_shell_hook="${gitDisabledLib.root}/.config/flakebox/shellHook.sh"
    ! grep -q 'hooks/pre-commit' "$disabled_shell_hook"
    ! grep -q 'hooks/commit-msg' "$disabled_shell_hook"
    ! grep -q 'git config commit.template' "$disabled_shell_hook"
    ! grep -q 'hooks/pre-commit' "${gitDisabledLib.root}/justfile"
    ! grep -q 'misc/git-hooks/pre-commit' \
      "${gitDisabledLib.root}/.github/workflows/flakebox-ci.yml"

    # Existing granular options still suppress only their own integration, and
    # pre-commit consumers follow the effective pre-commit setting.
    [ ! -e ${preCommitDisabledLib.root}/misc/git-hooks/pre-commit ]
    [ -e ${preCommitDisabledLib.root}/misc/git-hooks/commit-msg ]
    [ -e ${preCommitDisabledLib.root}/misc/git-hooks/commit-template.txt ]
    ! grep -q 'hooks/pre-commit' "${preCommitDisabledLib.root}/justfile"
    ! grep -q 'misc/git-hooks/pre-commit' \
      "${preCommitDisabledLib.root}/.github/workflows/flakebox-ci.yml"

    [ -e ${commitMsgDisabledLib.root}/misc/git-hooks/pre-commit ]
    [ ! -e ${commitMsgDisabledLib.root}/misc/git-hooks/commit-msg ]
    [ -e ${commitMsgDisabledLib.root}/misc/git-hooks/commit-template.txt ]

    [ -e ${commitTemplateDisabledLib.root}/misc/git-hooks/pre-commit ]
    [ -e ${commitTemplateDisabledLib.root}/misc/git-hooks/commit-msg ]
    [ ! -e ${commitTemplateDisabledLib.root}/misc/git-hooks/commit-template.txt ]
    ! grep -q 'git config commit.template' \
      "${commitTemplateDisabledLib.root}/.config/flakebox/shellHook.sh"

    # Shell entry reports all missing integration once and leaves .git untouched.
    mkdir shell-entry
    (
      cd shell-entry
      git init -q
      before="$(find .git -printf '%P %y %l\n' | sort)"
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        bash "$shell_hook" >stdout 2>stderr
      after="$(find .git -printf '%P %y %l\n' | sort)"
      [ "$before" = "$after" ]
      [ ! -s stdout ]
      [ "$(grep -c 'flakebox install-hooks' stderr)" -eq 1 ]
    )

    # Explicit installation is atomic, idempotent, and serialized across
    # concurrent installers.
    mkdir explicit-install
    (
      cd explicit-install
      export HOME="$PWD/home"
      mkdir "$HOME"
      git init -q
      git config --global extensions.worktreeConfig true
      printf '%s\n' \
        '[package]' \
        'name = "git-hooks-fixture"' \
        'version = "0.0.0"' \
        'edition = "2024"' \
        > Cargo.toml
      mkdir src
      touch src/lib.rs flake.nix
      mkdir -p misc/git-hooks .git/hooks
      cp ${flakeboxLib.root}/misc/git-hooks/pre-commit misc/git-hooks/
      cp ${flakeboxLib.root}/misc/git-hooks/commit-msg misc/git-hooks/
      cp ${flakeboxLib.root}/misc/git-hooks/commit-template.txt misc/git-hooks/
      ln -s "$PWD/misc/git-hooks/pre-commit" .git/hooks/pre-commit
      ln -s "$PWD/misc/git-hooks/commit-msg" .git/hooks/commit-msg

      export FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root}
      export FLAKEBOX_PROJECT_ROOT_DIR="$PWD"
      installer_pids=
      for _ in $(seq 1 16); do
        flakebox install-hooks &
        installer_pids="$installer_pids $!"
      done
      for installer_pid in $installer_pids; do
        wait "$installer_pid"
      done

      [ "$(readlink .git/hooks/pre-commit)" = "flakebox/pre-commit" ]
      [ "$(readlink .git/hooks/commit-msg)" = "flakebox/commit-msg" ]
      [ -e .git/flakebox/hooks/pre-commit-enabled ]
      [ -e .git/flakebox/hooks/commit-msg-enabled ]
      [ "$(git config --local --type=bool --get extensions.worktreeConfig)" = true ]
      ! git config --local --get-all core.bare
      cmp ${flakeboxLib.root}/.config/flakebox/git-hooks/pre-commit \
        .git/hooks/flakebox/pre-commit
      cmp ${flakeboxLib.root}/.config/flakebox/git-hooks/commit-msg \
        .git/hooks/flakebox/commit-msg
      git config --null --get commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')
      [ -f .git/flakebox-install-hooks.lock ]
      ! find .git/hooks -name '*.flakebox-new-*' | grep .

      # Common hook state alone is insufficient: each enabled worktree must
      # have its own installed enablement marker.
      rm .git/flakebox/hooks/pre-commit-enabled
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
        bash "$shell_hook" >stdout 2>stderr
      [ "$(grep -c 'flakebox install-hooks' stderr)" -eq 1 ]
      flakebox install-hooks

      # Values with trailing whitespace or newlines are stale; neither shell
      # inspection nor installation loses bytes through command substitution.
      git config --worktree commit.template $'misc/git-hooks/commit-template.txt\n'
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
        bash "$shell_hook" >stdout 2>stderr
      [ "$(grep -c 'flakebox install-hooks' stderr)" -eq 1 ]
      flakebox install-hooks
      git config --null --get commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')

      # Effective lookup selects the correct higher-precedence worktree value
      # without concatenating differing values from global and local scopes.
      git config --global commit.template global-template
      git config --local commit.template local-template
      git config --null --get commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
        bash "$shell_hook" >stdout 2>stderr
      ! grep -q 'flakebox install-hooks' stderr

      # A correct installation succeeds without write access to the hook/config
      # state, proving that the comparisons bypass every mutation.
      chmod -R a-w .git
      flakebox install-hooks
      chmod -R u+w .git

      # The common-dir dispatchers select policy from the worktree where Git
      # invoked the hook rather than from the worktree that installed it.
      git config user.email flakebox@example.invalid
      git config user.name Flakebox
      git add Cargo.toml flake.nix src misc
      git -c core.hooksPath=/nonexistent commit -qm fixture
      git worktree add -qb linked ../explicit-linked
      (
        cd ../explicit-linked
        export FLAKEBOX_PROJECT_ROOT_DIR="$PWD"
        export FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root}
        flakebox install-hooks
      )
      chmod u+w misc/git-hooks/pre-commit misc/git-hooks/commit-msg \
        ../explicit-linked/misc/git-hooks/pre-commit \
        ../explicit-linked/misc/git-hooks/commit-msg
      printf '#!/usr/bin/env bash\nprintf main > "$FLAKEBOX_WORKTREE_LOG"\n' \
        > misc/git-hooks/pre-commit
      printf '#!/usr/bin/env bash\nprintf linked > "$FLAKEBOX_WORKTREE_LOG"\n' \
        > ../explicit-linked/misc/git-hooks/pre-commit
      chmod +x misc/git-hooks/pre-commit \
        ../explicit-linked/misc/git-hooks/pre-commit
      dispatcher="$PWD/.git/hooks/flakebox/pre-commit"
      FLAKEBOX_WORKTREE_LOG="$PWD/main.log" bash "$dispatcher"
      (
        cd ../explicit-linked
        FLAKEBOX_WORKTREE_LOG="$PWD/../explicit-install/linked.log" \
          bash "$dispatcher"
      )
      grep -qx main main.log
      grep -qx linked linked.log

      # A disabled linked worktree neither removes shared dispatchers nor runs
      # a stale generated policy, and its template state is isolated.
      (
        cd ../explicit-linked
        export FLAKEBOX_PROJECT_ROOT_DIR="$PWD"
        export FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root}
        flakebox install-hooks
        git_dir="$(git rev-parse --absolute-git-dir)"
        [ ! -e "$git_dir/flakebox/hooks/pre-commit-enabled" ]
        [ ! -e "$git_dir/flakebox/hooks/commit-msg-enabled" ]
        [ -e misc/git-hooks/pre-commit ]
        ! git config --worktree --get-all commit.template
        FLAKEBOX_WORKTREE_LOG="$PWD/disabled.log" bash "$dispatcher"
        [ ! -e disabled.log ]
      )
      git config --null --get commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')
      [ "$(readlink .git/hooks/pre-commit)" = "flakebox/pre-commit" ]
      [ "$(readlink .git/hooks/commit-msg)" = "flakebox/commit-msg" ]

      # Granular disablement preserves the shared hooks and each still-enabled
      # integration. Template cleanup is worktree-local and ownership-exact.
      export FLAKEBOX_ROOT_DIR_CANDIDATE=${preCommitDisabledLib.root}
      flakebox install-hooks
      [ "$(readlink .git/hooks/pre-commit)" = "flakebox/pre-commit" ]
      [ "$(readlink .git/hooks/commit-msg)" = "flakebox/commit-msg" ]
      [ ! -e .git/flakebox/hooks/pre-commit-enabled ]
      [ -e .git/flakebox/hooks/commit-msg-enabled ]
      git config --null --get commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')

      export FLAKEBOX_ROOT_DIR_CANDIDATE=${commitTemplateDisabledLib.root}
      flakebox install-hooks
      [ "$(readlink .git/hooks/pre-commit)" = "flakebox/pre-commit" ]
      [ "$(readlink .git/hooks/commit-msg)" = "flakebox/commit-msg" ]
      [ -e .git/flakebox/hooks/pre-commit-enabled ]
      [ -e .git/flakebox/hooks/commit-msg-enabled ]
      ! git config --worktree --get-all commit.template

      git config --worktree commit.template foreign-template
      rm .git/hooks/pre-commit
      ln -s "$PWD/../explicit-linked/misc/git-hooks/pre-commit" \
        .git/hooks/pre-commit
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root} \
        flakebox install-hooks >stdout 2>stderr
      linked_legacy_status=$?
      set -e
      [ "$linked_legacy_status" -ne 0 ]
      grep -q 'ambiguous legacy-style target' stderr
      [ "$(readlink .git/hooks/pre-commit)" = \
        "$PWD/../explicit-linked/misc/git-hooks/pre-commit" ]

      rm .git/hooks/pre-commit
      ln -s foreign-pre-commit .git/hooks/pre-commit
      export FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root}
      flakebox install-hooks
      [ "$(readlink .git/hooks/pre-commit)" = "foreign-pre-commit" ]
      [ "$(readlink .git/hooks/commit-msg)" = "flakebox/commit-msg" ]
      [ "$(git config --worktree --get commit.template)" = foreign-template ]
      [ "$(git config --local --get commit.template)" = local-template ]
    )

    # A disabled upgrade neutralizes only legacy direct links whose ownership
    # is proven by an exact target in the invoking worktree.
    mkdir legacy-disabled
    (
      cd legacy-disabled
      git init -q
      printf '%s\n' \
        '[package]' \
        'name = "fresh-disabled"' \
        'version = "0.0.0"' \
        > Cargo.toml
      mkdir src
      touch src/lib.rs flake.nix
      mkdir -p misc/git-hooks .git/hooks
      touch misc/git-hooks/pre-commit misc/git-hooks/commit-msg
      ln -s "$PWD/misc/git-hooks/pre-commit" .git/hooks/pre-commit
      ln -s "$PWD/misc/git-hooks/commit-msg" .git/hooks/commit-msg
      FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks
      ! git config --local --get extensions.worktreeConfig
      [ ! -e .git/hooks/pre-commit ]
      [ ! -e .git/hooks/commit-msg ]
      [ ! -e .git/flakebox/hooks/pre-commit-enabled ]
      [ ! -e .git/flakebox/hooks/commit-msg-enabled ]
      [ -e misc/git-hooks/pre-commit ]
      [ -e misc/git-hooks/commit-msg ]

      ln -s /opt/company/misc/git-hooks/pre-commit .git/hooks/pre-commit
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      foreign_legacy_status=$?
      set -e
      [ "$foreign_legacy_status" -ne 0 ]
      grep -q 'ambiguous legacy-style target' stderr
      [ "$(readlink .git/hooks/pre-commit)" = \
        /opt/company/misc/git-hooks/pre-commit ]

      # Unexpected lookup errors fail closed and preserve the legacy link.
      rm .git/hooks/pre-commit
      ln -s "$PWD/misc/git-hooks/pre-commit" .git/hooks/pre-commit
      chmod 000 .git/hooks
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      lookup_status=$?
      set -e
      chmod 700 .git/hooks
      [ "$lookup_status" -ne 0 ]
      grep -q '.git/hooks/pre-commit' stderr
      [ "$(readlink .git/hooks/pre-commit)" = \
        "$PWD/misc/git-hooks/pre-commit" ]

      # Enabled installation refuses both regular and symlink entries without
      # positive Flakebox ownership evidence.
      rm .git/hooks/pre-commit
      printf 'foreign regular hook\n' > .git/hooks/pre-commit
      cp .git/hooks/pre-commit foreign-regular.expected
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${commitTemplateDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      regular_status=$?
      set -e
      [ "$regular_status" -ne 0 ]
      grep -q 'not a Flakebox-owned symlink' stderr
      cmp foreign-regular.expected .git/hooks/pre-commit

      rm .git/hooks/pre-commit
      ln -s /opt/company/pre-commit .git/hooks/pre-commit
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${commitTemplateDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      foreign_symlink_status=$?
      set -e
      [ "$foreign_symlink_status" -ne 0 ]
      grep -q 'points to non-Flakebox target' stderr
      [ "$(readlink .git/hooks/pre-commit)" = /opt/company/pre-commit ]
    )

    # A wholly disabled fresh repository neither enables worktree config nor
    # creates shared hooks or per-worktree enablement markers.
    mkdir fresh-disabled
    (
      cd fresh-disabled
      git init -q
      printf '%s\n' \
        '[package]' \
        'name = "fresh-disabled"' \
        'version = "0.0.0"' \
        > Cargo.toml
      mkdir src
      touch src/lib.rs flake.nix
      FLAKEBOX_ROOT_DIR_CANDIDATE=${gitDisabledLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks
      ! git config --local --get extensions.worktreeConfig
      [ ! -e .git/hooks/pre-commit ]
      [ ! -e .git/hooks/commit-msg ]
      [ ! -e .git/flakebox/hooks/pre-commit-enabled ]
      [ ! -e .git/flakebox/hooks/commit-msg-enabled ]
    )

    # An enabled upgrade migrates the exact previous shared-local template into
    # the invoking worktree after activating repository-local worktree config.
    mkdir legacy-template
    (
      cd legacy-template
      git init -q
      printf '%s\n' \
        '[package]' \
        'name = "legacy-template"' \
        'version = "0.0.0"' \
        > Cargo.toml
      mkdir src
      touch src/lib.rs flake.nix
      git config --local commit.template misc/git-hooks/commit-template.txt
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks
      [ "$(git config --local --type=bool --get extensions.worktreeConfig)" = true ]
      ! git config --local --get-all commit.template
      git config --worktree --null --get-all commit.template |
        cmp - <(printf 'misc/git-hooks/commit-template.txt\0')
    )

    # Enabling worktree config refuses repositories with unusual local core
    # settings instead of silently changing their interpretation.
    mkdir unusual-core
    (
      cd unusual-core
      git init -q
      printf '%s\n' \
        '[package]' \
        'name = "unusual-core"' \
        'version = "0.0.0"' \
        > Cargo.toml
      mkdir src
      touch src/lib.rs flake.nix
      git config --local core.worktree "$PWD"
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      install_status=$?
      set -e
      [ "$install_status" -ne 0 ]
      grep -q 'migrate core.worktree to worktree config' stderr
      ! git config --local --get extensions.worktreeConfig
      [ ! -e .git/hooks/pre-commit ]
      [ ! -e .git/hooks/commit-msg ]

      # Non-default and multiple local core.bare values are also rejected.
      git config --local --unset-all core.worktree
      git config --local core.bare true
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      bare_status=$?
      set -e
      [ "$bare_status" -ne 0 ]
      grep -q 'non-default local core.bare' stderr
      ! git --git-dir=.git config --local --get extensions.worktreeConfig
      [ ! -e .git/hooks/pre-commit ]
      [ ! -e .git/hooks/commit-msg ]

      git --git-dir=.git config --local --add core.bare false
      set +e
      FLAKEBOX_ROOT_DIR_CANDIDATE=${flakeboxLib.root} \
      FLAKEBOX_PROJECT_ROOT_DIR="$PWD" \
        flakebox install-hooks >stdout 2>stderr
      multiple_bare_status=$?
      set -e
      [ "$multiple_bare_status" -ne 0 ]
      grep -q 'non-default local core.bare' stderr
      ! git --git-dir=.git config --local --get extensions.worktreeConfig
      [ ! -e .git/hooks/pre-commit ]
      [ ! -e .git/hooks/commit-msg ]
    )

    # The timer preserves success, failures, errexit, signals, and byte-exact
    # ordinary output when no warning is emitted.
    function check_output() {
      printf 'stdout line\nstdout-without-newline'
      printf 'stderr line\nstderr-without-newline' >&2
    }
    function check_one() {
      return 1
    }
    function check_42() {
      return 42
    }
    function check_125() {
      return 125
    }
    function check_errexit() {
      set -e
      false
      printf should-not-run
    }
    export -f check_output check_one check_42 check_125 check_errexit

    flakebox-git-hook-check-timer check_output > timer.stdout 2> timer.stderr
    printf 'stdout line\nstdout-without-newline' > expected-timer.stdout
    printf 'stderr line\nstderr-without-newline' > expected-timer.stderr
    cmp expected-timer.stdout timer.stdout
    cmp expected-timer.stderr timer.stderr

    function check_slow_newline() {
      printf 'terminated stderr\n' >&2
      sleep 1.2
    }
    export -f check_slow_newline
    flakebox-git-hook-check-timer check_slow_newline 2> slow-newline.stderr
    sed -E 's/took [0-9]+\.[0-9]{3}s/took DURATION/' \
      slow-newline.stderr > normalized-slow-newline.stderr
    # Standalone timer use conservatively separates warnings because it cannot
    # inspect arbitrary inherited stderr. Generated hooks compact this output.
    printf 'terminated stderr\n\nflakebox: warning: check_slow_newline took DURATION (>1s)\n' \
      > expected-slow-newline.stderr
    cmp expected-slow-newline.stderr normalized-slow-newline.stderr

    function check_slow_output() {
      printf slow-stderr-without-newline >&2
      sleep 1.2
    }
    export -f check_slow_output
    flakebox-git-hook-check-timer check_slow_output 2> slow-timer.stderr
    sed -E 's/took [0-9]+\.[0-9]{3}s/took DURATION/' \
      slow-timer.stderr > normalized-slow-timer.stderr
    printf 'slow-stderr-without-newline\nflakebox: warning: check_slow_output took DURATION (>1s)\n' \
      > expected-slow-timer.stderr
    cmp expected-slow-timer.stderr normalized-slow-timer.stderr

    set +e
    flakebox-git-hook-check-timer check_one
    one_status=$?
    flakebox-git-hook-check-timer check_42
    status_42=$?
    flakebox-git-hook-check-timer check_125
    status_125=$?
    flakebox-git-hook-check-timer check_errexit > errexit.stdout
    errexit_status=$?
    set -e
    [ "$one_status" -eq 1 ]
    [ "$status_42" -eq 42 ]
    [ "$status_125" -eq 125 ]
    [ "$errexit_status" -eq 1 ]
    [ ! -s errexit.stdout ]

    set +e
    flakebox-git-hook-check-timer 2> timer-error.stderr
    timer_error_status=$?
    set -e
    [ "$timer_error_status" -eq 125 ]
    grep -qx 'flakebox: error: git-hook check timer: missing check name' timer-error.stderr

    function check_signal() {
      trap 'printf forwarded > "$FLAKEBOX_SIGNAL_LOG"; exit 0' TERM
      printf '%s\n' "$BASHPID" > "$FLAKEBOX_SIGNAL_READY"
      while true; do :; done
    }
    export -f check_signal
    export FLAKEBOX_SIGNAL_LOG="$PWD/signal.log"
    export FLAKEBOX_SIGNAL_READY="$PWD/signal.ready"
    flakebox-git-hook-check-timer check_signal &
    timer_pid=$!
    for attempt in $(seq 1 100); do
      [ -e "$FLAKEBOX_SIGNAL_READY" ] && break
      sleep 0.01
    done
    [ -e "$FLAKEBOX_SIGNAL_READY" ]
    kill -TERM "$timer_pid"
    set +e
    wait "$timer_pid"
    signal_status=$?
    set -e
    [ "$signal_status" -eq 143 ]
    [ "$(cat "$FLAKEBOX_SIGNAL_LOG")" = forwarded ]

    # Every configured hook still runs concurrently. Slow warnings are exact,
    # complete records even after unterminated check stderr.
    mkdir timed-repo
    cd timed-repo
    git init -q
    touch tracked
    git add tracked
    export FLAKEBOX_TEST_LOG="$PWD/hooks.log"
    NO_STASH=1 bash ${timedHooks}/misc/git-hooks/pre-commit \
      > hook.stdout 2> hook.stderr

    printf 'a-slow\nb-fast\nc-slow\nd-slow-nul\n' | sort > expected-hooks
    sort hooks.log > actual-hooks
    cmp expected-hooks actual-hooks
    [ "$(grep -a -c '^flakebox: warning: check_.* took [0-9]*\.[0-9]\{3\}s (>1s)$' hook.stderr)" -eq 3 ]
    [ "$(grep -a -c '^flakebox: warning: check_a_slow took ' hook.stderr)" -eq 1 ]
    [ "$(grep -a -c '^flakebox: warning: check_c_slow took ' hook.stderr)" -eq 1 ]
    [ "$(grep -a -c '^flakebox: warning: check_d_slow_nul took ' hook.stderr)" -eq 1 ]
    ! grep -a -q 'warning: check_b_fast took' hook.stderr
    grep -a -q 'slow stderr without newline' hook.stderr
    grep -a -q 'fast stderr without newline' hook.stderr
    grep -q 'slow stdout' hook.stdout
    grep -q 'fast stdout without newline' hook.stdout
    ! grep -a -q '^$' hook.stderr
    od -An -t u1 hook.stderr | tr -s ' ' '\n' | grep -A1 -x 0 |
      grep -qx 10

    # GNU Parallel's aggregate status and complete coverage are unchanged when
    # checks return distinct non-zero statuses.
    export FLAKEBOX_TEST_LOG="$PWD/failures.log"
    set +e
    NO_STASH=1 bash ${failureHooks}/misc/git-hooks/pre-commit \
      > failures.stdout 2> failures.stderr
    failure_status=$?
    set -e
    [ "$failure_status" -eq 2 ]
    printf 'fail-42\nfail-one\nsuccess\n' | sort > expected-failures
    sort failures.log > actual-failures
    cmp expected-failures actual-failures

    # A -j1 runner proves time spent queued is not charged to a fast check.
    mkdir fake-bin
    cat > fake-bin/parallel <<'EOF'
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.parallel}/bin/parallel -j1 "$@"
    EOF
    chmod +x fake-bin/parallel
    export PATH="$PWD/fake-bin:$PATH"
    NO_STASH=1 bash ${queueHooks}/misc/git-hooks/pre-commit \
      > queue.stdout 2> queue.stderr
    [ "$(grep -c '^flakebox: warning:' queue.stderr)" -eq 1 ]
    grep -q '^flakebox: warning: check_a_blocker took ' queue.stderr
    ! grep -q 'warning: check_b_fast_after_queue took' queue.stderr
    ! grep -q '^$' queue.stderr
    cd ..

    # The formatter descriptor is closed in checks, so a detached descendant
    # with redirected standard streams cannot keep the hook alive.
    mkdir background-repo
    cd background-repo
    git init -q
    touch tracked
    git add tracked
    export FLAKEBOX_BACKGROUND_PID="$PWD/background.pid"
    timeout 10 env NO_STASH=1 \
      bash ${backgroundHooks}/misc/git-hooks/pre-commit
    background_pid="$(cat "$FLAKEBOX_BACKGROUND_PID")"
    kill "$background_pid" 2>/dev/null || true
    cd ..

    # ShellCheck is skipped for an empty script set, then receives every tracked
    # script in one argument-safe invocation. Its failure still fails the hook.
    mkdir shellcheck-repo
    cd shellcheck-repo
    git init -q
    mkdir fake-shellcheck-bin
    cat > fake-shellcheck-bin/shellcheck <<'EOF'
    #!${pkgs.bash}/bin/bash
    printf 'invocation\n' >> "$FLAKEBOX_SHELLCHECK_LOG"
    printf '%s\n' "$@" > "$FLAKEBOX_SHELLCHECK_ARGS"
    exit "''${FLAKEBOX_SHELLCHECK_STATUS:-0}"
    EOF
    chmod +x fake-shellcheck-bin/shellcheck
    export PATH="$PWD/fake-shellcheck-bin:$PATH"
    export FLAKEBOX_SHELLCHECK_LOG="$PWD/shellcheck.log"
    export FLAKEBOX_SHELLCHECK_ARGS="$PWD/shellcheck.args"

    printf 'not a script\n' > tracked.txt
    git add tracked.txt
    NO_STASH=1 bash ${shellcheckHooks}/misc/git-hooks/pre-commit
    [ ! -e "$FLAKEBOX_SHELLCHECK_LOG" ]

    printf '#!/bin/sh\n' > 'alpha script.sh'
    printf '#!/bin/sh\n' > 'literal[glob].sh'
    # This untracked path makes an unsafe expansion of literal[glob].sh match.
    printf '#!/bin/sh\n' > literalg.sh
    git --literal-pathspecs add 'alpha script.sh' 'literal[glob].sh'
    NO_STASH=1 bash ${shellcheckHooks}/misc/git-hooks/pre-commit
    [ "$(grep -c '^invocation$' "$FLAKEBOX_SHELLCHECK_LOG")" -eq 1 ]
    printf '%s\n' \
      '--severity=warning' \
      'alpha script.sh' \
      'literal[glob].sh' > expected-shellcheck.args
    cmp expected-shellcheck.args "$FLAKEBOX_SHELLCHECK_ARGS"

    set +e
    FLAKEBOX_SHELLCHECK_STATUS=23 NO_STASH=1 \
      bash ${shellcheckHooks}/misc/git-hooks/pre-commit
    shellcheck_failure_status=$?
    set -e
    [ "$shellcheck_failure_status" -ne 0 ]
    [ "$(grep -c '^invocation$' "$FLAKEBOX_SHELLCHECK_LOG")" -eq 2 ]
    cd ..

    # Private patch restoration exposes indexed content to checks and restores
    # tracked worktree changes afterwards without touching the user stash.
    mkdir stash-repo
    cd stash-repo
    git init -q
    git config user.email flakebox@example.invalid
    git config user.name Flakebox
    printf 'base\n' > tracked.txt
    printf 'base\n' > unstaged.txt
    git add tracked.txt unstaged.txt
    git commit -qm base

    # An older user stash must remain untouched by the hook's private patch.
    printf 'older stash\n' > unstaged.txt
    git stash push -q -m older
    older_stash="$(git rev-parse refs/stash)"

    printf 'staged\n' > tracked.txt
    git add tracked.txt
    printf 'unstaged\n' > unstaged.txt
    bash ${stashHooks}/misc/git-hooks/pre-commit \
      > stash.stdout 2> stash.stderr
    [ "$(cat tracked.txt)" = staged ]
    [ "$(cat unstaged.txt)" = unstaged ]
    [ "$(git rev-parse refs/stash)" = "$older_stash" ]
    [ -z "$(git for-each-ref --format='%(refname)' refs/flakebox/pre-commit/)" ]
    [ ! -s stash.stderr ]

    set +e
    bash ${stashFailureHooks}/misc/git-hooks/pre-commit \
      > stash-failure.stdout 2> stash-failure.stderr
    stash_failure_status=$?
    set -e
    [ "$stash_failure_status" -eq 1 ]
    [ "$(cat tracked.txt)" = staged ]
    [ "$(cat unstaged.txt)" = unstaged ]
    [ "$(git rev-parse refs/stash)" = "$older_stash" ]
    [ -z "$(git for-each-ref --format='%(refname)' refs/flakebox/pre-commit/)" ]
    [ ! -s stash-failure.stderr ]

    ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
      # Interrupting the whole generated-hook process group terminates workers
      # and still runs the top-level worktree patch restoration trap.
      export FLAKEBOX_INTERRUPT_READY="$PWD/interrupt.ready"
      setsid bash ${interruptHooks}/misc/git-hooks/pre-commit \
        > interrupt.stdout 2> interrupt.stderr &
      interrupt_pid=$!
      for attempt in $(seq 1 100); do
        [ -e "$FLAKEBOX_INTERRUPT_READY" ] && break
        sleep 0.01
      done
      [ -e "$FLAKEBOX_INTERRUPT_READY" ]
      kill -TERM -- "-$interrupt_pid"
      set +e
      wait "$interrupt_pid"
      interrupt_status=$?
      set -e
      [ "$interrupt_status" -eq 143 ]
      [ "$(cat tracked.txt)" = staged ]
      [ "$(cat unstaged.txt)" = unstaged ]
      [ "$(git rev-parse refs/stash)" = "$older_stash" ]
      [ -z "$(git for-each-ref --format='%(refname)' refs/flakebox/pre-commit/)" ]
      ! grep -q 'could not restore uncommitted changes' interrupt.stderr
      ! kill -0 -- "-$interrupt_pid" 2>/dev/null
    ''}

    # A colocated Jujutsu checkout has no staged/unstaged split. The hook must
    # inspect its current tree without manipulating the Git index or refs.
    mkdir .jj
    NO_STASH= bash ${jjHooks}/misc/git-hooks/pre-commit \
      > jj.stdout 2> jj.stderr
    [ "$(cat unstaged.txt)" = unstaged ]
    [ -z "$(git for-each-ref --format='%(refname)' refs/flakebox/pre-commit/)" ]
    [ ! -s jj.stderr ]
    cd ..

    # Pre-commit failures happen before Git has opened the message editor, so
    # they must not suggest recovering COMMIT_EDITMSG. A commit-msg failure does
    # provide the exact retry command once Git has populated that file.
    mkdir usability-repo
    cd usability-repo
    git init -q
    git config user.email flakebox@example.invalid
    git config user.name Flakebox
    touch tracked
    git add tracked
    mkdir -p .git/hooks
    cp ${usabilityHooks}/misc/git-hooks/pre-commit .git/hooks/pre-commit.flakebox
    cp ${usabilityHooks}/misc/git-hooks/commit-msg .git/hooks/commit-msg.flakebox
    cat > .git/hooks/pre-commit <<'EOF'
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.bash}/bin/bash .git/hooks/pre-commit.flakebox "$@"
    EOF
    cat > .git/hooks/commit-msg <<'EOF'
    #!${pkgs.bash}/bin/bash
    exec ${pkgs.bash}/bin/bash .git/hooks/commit-msg.flakebox "$@"
    EOF
    chmod +x .git/hooks/pre-commit .git/hooks/commit-msg
    export FLAKEBOX_TEST_LOG="$PWD/hooks.log"

    set +e
    git commit -m rejected-by-pre-commit > pre-commit.stdout 2> pre-commit.stderr
    pre_commit_status=$?
    set -e
    [ "$pre_commit_status" -ne 0 ]
    grep -qx 'pre-commit ran' hooks.log
    ! grep -q -- '-eF .git/COMMIT_EDITMSG' pre-commit.stderr

    : > hooks.log
    mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
    set +e
    git commit -m rejected-by-commit-msg > commit-msg.stdout 2> commit-msg.stderr
    commit_msg_status=$?
    set -e
    [ "$commit_msg_status" -ne 0 ]
    grep -qx 'commit-msg ran' hooks.log
    grep -qx 'flakebox: commit message checks failed; your message is saved in .git/COMMIT_EDITMSG' commit-msg.stderr
    grep -qx 'flakebox: rerun your original git commit command, replacing any message options with:' commit-msg.stderr
    grep -qx -- '-eF .git/COMMIT_EDITMSG' commit-msg.stderr
    [ -s .git/COMMIT_EDITMSG ]

    # Alternate commit-msg input paths do not support the advertised recovery
    # command and therefore receive no guidance.
    printf 'message\n' > alternate-message
    set +e
    bash .git/hooks/commit-msg.flakebox alternate-message \
      > alternate.stdout 2> alternate.stderr
    alternate_status=$?
    set -e
    [ "$alternate_status" -eq 42 ]
    ! grep -q -- '-eF .git/COMMIT_EDITMSG' alternate.stderr

    # Only the exact value 1 bypasses each generated hook. Unset and other
    # values preserve normal failure behavior.
    set +e
    NO_STASH=1 bash .git/hooks/pre-commit.flakebox > /dev/null 2> /dev/null
    unset_pre_commit_status=$?
    FLAKEBOX_SKIP_GIT_HOOKS=yes NO_STASH=1 \
      bash .git/hooks/pre-commit.flakebox > /dev/null 2> /dev/null
    other_pre_commit_status=$?
    bash .git/hooks/commit-msg.flakebox alternate-message > /dev/null 2> /dev/null
    unset_commit_msg_status=$?
    FLAKEBOX_SKIP_GIT_HOOKS=yes \
      bash .git/hooks/commit-msg.flakebox alternate-message > /dev/null 2> /dev/null
    other_commit_msg_status=$?
    set -e
    [ "$unset_pre_commit_status" -ne 0 ]
    [ "$other_pre_commit_status" -ne 0 ]
    [ "$unset_commit_msg_status" -eq 42 ]
    [ "$other_commit_msg_status" -eq 42 ]

    : > hooks.log
    FLAKEBOX_SKIP_GIT_HOOKS=1 NO_STASH=1 \
      bash .git/hooks/pre-commit.flakebox
    FLAKEBOX_SKIP_GIT_HOOKS=1 \
      bash .git/hooks/commit-msg.flakebox alternate-message
    [ ! -s hooks.log ]

    mv .git/hooks/pre-commit.disabled .git/hooks/pre-commit
    FLAKEBOX_SKIP_GIT_HOOKS=1 git commit -m bypassed -q
    [ ! -s hooks.log ]
    git rev-parse --verify HEAD

    # Operations whose original options matter must be rerun with those options
    # plus the saved-message flags, rather than as a plain new commit.
    mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled
    printf 'changed\n' > tracked
    set +e
    git commit -a -m rejected-a > commit-a.stdout 2> commit-a.stderr
    commit_a_status=$?
    set -e
    [ "$commit_a_status" -ne 0 ]
    grep -qx -- '-eF .git/COMMIT_EDITMSG' commit-a.stderr
    FLAKEBOX_SKIP_GIT_HOOKS=1 GIT_EDITOR=true \
      git commit -a -eF .git/COMMIT_EDITMSG -q
    [ "$(git rev-list --count HEAD)" -eq 2 ]

    set +e
    git commit --amend -m rejected-amend \
      > commit-amend.stdout 2> commit-amend.stderr
    commit_amend_status=$?
    set -e
    [ "$commit_amend_status" -ne 0 ]
    grep -qx -- '-eF .git/COMMIT_EDITMSG' commit-amend.stderr
    FLAKEBOX_SKIP_GIT_HOOKS=1 GIT_EDITOR=true \
      git commit --amend -eF .git/COMMIT_EDITMSG -q
    [ "$(git rev-list --count HEAD)" -eq 2 ]
    cd ..

    # A configuration with no hooks remains a valid no-op without a sentinel.
    empty_pre_commit="${emptyHooks}/misc/git-hooks/pre-commit"
    bash -n "$empty_pre_commit"
    ! grep -q 'parallel ' "$empty_pre_commit"
    mkdir empty-repo
    cd empty-repo
    git init -q
    NO_STASH=1 bash "$empty_pre_commit"
    cd ..

    touch "$out"
  ''
