#!@runtimeShell@

set -o errexit
set -o nounset
set -o pipefail

# Discard all options
while [[ "$1" =~ ^- ]]; do
  shift
done

exec '@out@/bin/wl-run' "$@"
