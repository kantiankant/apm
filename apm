#!/bin/sh
# apm - aur package manager
# because apparently this is how I spend my time now
# licence: GPL-3.0

APM_VERSION="1.0.1"
AUR="https://aur.archlinux.org"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/apm"
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/apm/apm.log"

die()     { printf 'error: %s\n'   "$1" >&2; exit 1; }
info()    { printf ':: %s\n'       "$1"; }
success() { printf '==> %s\n'      "$1"; }
warn()    { printf 'warning: %s\n' "$1" >&2; }
log()     { mkdir -p "$(dirname "$LOG")"; printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG"; }

spinner() {
    i=0
    while true; do
        i=$(( (i + 1) % 4 ))
        c=$(printf '%s' '|/-\\' | cut -c$(( i + 1 )))
        printf '\r%s %s...' "$c" "$1" >&2
        sleep 0.1
    done
}

spin_start() { spinner "$1" & SPIN=$!; trap 'spin_stop' EXIT INT TERM; }
spin_stop()  { kill "$SPIN" 2>/dev/null; printf '\r\033[K' >&2; }

confirm() {
    printf '%s [y/N] ' "$1"
    read -r ans
    [ "$ans" = "y" ] || [ "$ans" = "Y" ]
}

aur_fetch_info() { curl -s "$AUR/rpc/v5/info?arg[]=$1"; }

# present a numbered list and return the chosen entry
apm_select() {
    # feed: one result per line, format "name (ver) — desc"
    # prints chosen name to stdout, empty if user bails
    results="$1"
    count=$(printf '%s\n' "$results" | grep -c .)
    [ "$count" -eq 0 ] && return 1
    [ "$count" -eq 1 ] && { printf '%s\n' "$results" | cut -d' ' -f1; return 0; }

    printf '\n'
    i=1
    printf '%s\n' "$results" | while IFS= read -r line; do
        printf '  %2d) %s\n' "$i" "$line"
        i=$(( i + 1 ))
    done
    printf '   0) cancel — like most of my plans\n\n'
    printf 'select a package [0-%d]: ' "$count"
    read -r choice

    # validate
    case "$choice" in
        ''|0|*[!0-9]*) printf '' ; return 1 ;;
    esac
    [ "$choice" -gt "$count" ] && { warn "that number doesn't exist, much like my career prospects"; return 1; }

    printf '%s\n' "$results" | sed -n "${choice}p" | cut -d' ' -f1
}

apm_install() {
    [ -z "$1" ] && die "no package specified. try: apm install <package>"

    # check if it exists at all before we get our hopes up
    spin_start "looking up $1"
    exact=$(aur_fetch_info "$1")
    spin_stop

    found=$(printf '%s\n' "$exact" | grep -o '"resultcount":[0-9]*' | cut -d: -f2)
    if [ "${found:-0}" -eq 0 ]; then
        # no exact match — search instead and offer selection
        info "no exact match for '$1', searching..."
        spin_start "searching"
        results=$(curl -s "$AUR/rpc/v5/search/$1" | \
            sed 's/},{/\n/g' | \
            while IFS= read -r pkg; do
                name=$(printf '%s' "$pkg" | grep -o '"Name":"[^"]*"'        | cut -d'"' -f4)
                ver=$( printf '%s' "$pkg" | grep -o '"Version":"[^"]*"'     | cut -d'"' -f4)
                desc=$(printf '%s' "$pkg" | grep -o '"Description":"[^"]*"' | cut -d'"' -f4)
                [ -n "$name" ] && printf '%s (%s) — %s\n' "$name" "$ver" "$desc"
            done)
        spin_stop
        [ -z "$results" ] && die "nothing found for '$1'. story of my life."
        chosen=$(apm_select "$results")
        [ -z "$chosen" ] && { info "cancelled. probably for the best."; exit 0; }
        set -- "$chosen"
    fi

    pacman -Q "$1" >/dev/null 2>&1 && \
        ! confirm "$1 is already installed. Reinstall?" && exit 0

    mkdir -p "$CACHE"
    cd "$CACHE" || die "cannot cd to cache"
    spin_start "fetching $1"
    if [ -d "$1/.git" ]; then
        git -C "$1" pull -q
    else
        git clone -q "$AUR/$1.git" "$1" || { spin_stop; die "clone failed. much like my last interview."; }
    fi
    spin_stop

    cd "$1" || die "cd failed"
    less PKGBUILD
    confirm "Proceed with installation?" || exit 0
    makepkg -si && {
        log "installed $1"
        success "installed $1"
    }
}

apm_search() {
    [ -z "$1" ] && die "no search term specified"
    spin_start "searching"
    results=$(curl -s "$AUR/rpc/v5/search/$1" | \
        sed 's/},{/\n/g' | \
        while IFS= read -r pkg; do
            name=$(printf '%s' "$pkg" | grep -o '"Name":"[^"]*"'        | cut -d'"' -f4)
            ver=$( printf '%s' "$pkg" | grep -o '"Version":"[^"]*"'     | cut -d'"' -f4)
            desc=$(printf '%s' "$pkg" | grep -o '"Description":"[^"]*"' | cut -d'"' -f4)
            [ -n "$name" ] && printf '%s (%s) — %s\n' "$name" "$ver" "$desc"
        done)
    spin_stop
    [ -z "$results" ] && { info "no results for '$1'. much like my job search." >&2; exit 0; }

    chosen=$(apm_select "$results")
    [ -z "$chosen" ] && exit 0
    confirm "Install $chosen?" && apm_install "$chosen"
}

apm_update() {
    spin_start "searching for updates"
    updates=$(pacman -Qm | while read -r pkg ver; do
        case "$pkg" in *-git) continue ;; esac
        remote=$(aur_fetch_info "$pkg" | grep -o '"Version":"[^"]*"' | cut -d'"' -f4)
        [ -n "$remote" ] && [ "$remote" != "$ver" ] && \
            printf '%s: %s -> %s\n' "$pkg" "$ver" "$remote"
    done)
    spin_stop
    [ -n "$updates" ] && printf '%s\n' "$updates" || info "everything up to date. unlike my CV." >&2
}

apm_upgrade() {
    spin_start "searching for updates"
    updates=$(pacman -Qm | while read -r pkg ver; do
        case "$pkg" in *-git) continue ;; esac
        remote=$(aur_fetch_info "$pkg" | grep -o '"Version":"[^"]*"' | cut -d'"' -f4)
        [ -n "$remote" ] && [ "$remote" != "$ver" ] && \
            printf '%s: %s -> %s\n' "$pkg" "$ver" "$remote"
    done)
    spin_stop
    [ -z "$updates" ] && { info "everything up to date. unlike my CV." >&2; exit 0; }
    printf '%s\n' "$updates"
    printf '\n'
    if confirm "Upgrade all?"; then
        printf '%s\n' "$updates" | cut -d: -f1 | while read -r pkg; do
            apm_install "$pkg"
        done
    else
        printf '%s\n' "$updates" | cut -d: -f1 | while read -r pkg; do
            confirm "Upgrade $pkg?" && apm_install "$pkg"
        done
    fi
}

apm_remove() {
    [ -z "$1" ] && die "no package specified"
    pacman -Q "$1" >/dev/null 2>&1 || die "$1 is not installed. can't remove what isn't there."
    confirm "Remove $1?" && pacman -Rns "$1" && {
        log "removed $1"
        success "removed $1"
    }
}

apm_info() {
    [ -z "$1" ] && die "no package specified"
    spin_start "fetching info"
    result=$(aur_fetch_info "$1")
    spin_stop
    printf '%s\n' "$result" | grep -o '"[A-Za-z]*":"[^"]*"' | \
        grep -E '"(Name|Version|Description|URL|Maintainer|NumVotes|Popularity|License)":"[^"]*"' | \
        cut -d'"' -f2,4 | sed 's/"/: /'
}

apm_deps() {
    [ -z "$1" ] && die "no package specified"
    spin_start "fetching dependencies"
    result=$(aur_fetch_info "$1")
    spin_stop
    printf 'depends:\n'
    printf '%s\n' "$result" | grep -o '"Depends":\[[^]]*\]' | \
        grep -o '"[^"]*"' | grep -v Depends | tr -d '"' | sed 's/^/  /'
    printf 'makedepends:\n'
    printf '%s\n' "$result" | grep -o '"MakeDepends":\[[^]]*\]' | \
        grep -o '"[^"]*"' | grep -v MakeDepends | tr -d '"' | sed 's/^/  /'
}

apm_clean() {
    info "cache lives at $CACHE"
    du -sh "$CACHE" 2>/dev/null || info "cache is empty, like my fridge"
    confirm "Clean build cache?" && rm -rf "$CACHE" && {
        info "cache cleared"
        log "cache cleared"
    }
}

apm_list() {
    count=$(pacman -Qm | wc -l)
    info "installed AUR packages ($count):"
    pacman -Qm
}

apm_log() {
    [ -f "$LOG" ] && cat "$LOG" || \
        info "no log found. either nothing's happened or everything has, and either way it's gone."
}

apm_fetch() {
    pkg_count=$(pacman -Qm | wc -l)
    printf ' .--.                  apm - a shitty suckless aur package manager\n'
    printf '/ _.-'"'"' .-.  .-.  .-.   version  : %s\n'  "$APM_VERSION"
    printf '\  '"'"'-. '"'"'-'"'"'  '"'"'-'"'"'  '"'"'-'"'"'   licence  : GPL-3.0\n'
    printf ' '"'"'--'"'"'                  shell    : %s\n'  "${SHELL##*/}"
    printf '                       cache    : %s\n'        "$CACHE"
    printf '                       packages : %s (aur)\n'  "$pkg_count"
    printf '                       log      : %s\n'        "$LOG"
}
apm_version() {
    printf 'apm %s — a suckless aur package manager\n' "$APM_VERSION"
    printf 'licence: GPL-3.0\n'
    printf 'written on a saturday from inside a chroot on the wrong operating system\n'
    printf 'by someone who absolutely should have been doing something else\n'
}

case "$1" in
    install|  -S)    apm_install "$2" ;;
    search|   -Ss)   apm_search  "$2" ;;
    update|   -Su)   apm_update       ;;
    upgrade|  -Syu)  apm_upgrade      ;;
    remove|   -R)    apm_remove  "$2" ;;
    info|     -Si)   apm_info    "$2" ;;
    deps|     -Sd)   apm_deps    "$2" ;;
    list|     -Q)    apm_list         ;;
    clean)           apm_clean        ;;
    log)             apm_log          ;;
    fetch)           apm_fetch        ;;
    version|  -V)    apm_version      ;;
    *)
        printf 'apm - shitty suckless aur package manager\n\n'
        printf 'usage: apm <command> [package]\n\n'
        printf 'commands:\n'
        printf '  install,  -S     install a package (with selection if ambiguous)\n'
        printf '  search,   -Ss    search and select a package interactively\n'
        printf '  update,   -Su    check for updates\n'
        printf '  upgrade,  -Syu   upgrade outdated packages\n'
        printf '  remove,   -R     remove a package\n'
        printf '  info,     -Si    show package information\n'
        printf '  deps,     -Sd    show package dependencies\n'
        printf '  list,     -Q     list installed aur packages\n'
        printf '  clean            clear build cache\n'
        printf '  log              show install/remove history\n'
        printf '  fetch            system information\n'
        printf '  version,  -V     show version\n'
        ;;
esac
