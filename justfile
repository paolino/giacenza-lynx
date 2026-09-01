# shellcheck shell=bash
set unstable := true

# List available recipes
default:
    @just --list

# Format all Haskell sources
format:
    #!/usr/bin/env bash
    set -euo pipefail
    for i in {1..3}; do
        fourmolu -i src app test
    done

# Check formatting (gate step; no writes)
format-check:
    #!/usr/bin/env bash
    set -euo pipefail
    fourmolu -m check $(find src app test -name '*.hs')

# Run hlint on domain, app and test code
hlint:
    #!/usr/bin/env bash
    set -euo pipefail
    hlint src app test

# Build native components (library + test suite; the miso app builds only
# under ghcNative, see flake.nix packages)
build:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal build -O0 lib:giacenza-lynx test:unit --enable-tests

# Run unit tests, optionally narrowed by an hspec -m pattern
unit match='':
    #!/usr/bin/env bash
    set -euo pipefail
    if [[ -z '{{ match }}' ]]; then
        cabal test unit -O0 --test-show-details=direct
    else
        cabal test unit -O0 --test-show-details=direct \
            --test-option=--match \
            --test-option='{{ match }}'
    fi

# cabal check (Hackage readiness)
cabal-check:
    #!/usr/bin/env bash
    set -euo pipefail
    cabal check

# Full native CI: build, unit, format-check, hlint, cabal-check
ci:
    #!/usr/bin/env bash
    set -euo pipefail
    just build
    just unit
    just format-check
    just hlint
    just cabal-check

# Build the Lynx bundle (main.lynx.bundle + main.lynx.bundle.sha256)
bundle:
    #!/usr/bin/env bash
    set -euo pipefail
    nix build --quiet .#giacenza-lynx-bundle -o result-bundle
