#!@runtimeShell@

set -o errexit
set -o nounset
set -o pipefail

WLR_BACKENDS=headless \
WLR_LIBINPUT_NO_DEVICES=1 \
WLR_RENDERER=pixman \
XDG_RUNTIME_DIR="$(mktemp -d)" \
  exec '@cage@/bin/cage' -- "$@"
