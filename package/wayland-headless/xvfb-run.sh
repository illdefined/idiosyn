#!@runtimeShell@

set -o errexit
set -o nounset
set -o pipefail

# Discard all options
while [[ "$1" =~ ^- ]]; do
  case "$1" in
    (-e|-f|-n|-p|-s|-w) shift ;&
    (*) shift ;;
  esac
done

exec '@out@/bin/wl-run' "$@"
