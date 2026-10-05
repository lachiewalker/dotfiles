# shellcheck shell=bash
# Guided manual step: print instructions, then wait for Enter.
# Usage: pause_for_user "Title" "instruction line" "instruction line" ...
pause_for_user() {
    local title="$1"
    shift
    echo ""
    echo "  ┌─ MANUAL STEP: ${title}"
    local line
    for line in "$@"; do
        echo "  │  ${line}"
    done
    echo "  └─"
    read -rp "  Press Enter when done... " _ </dev/tty
}
