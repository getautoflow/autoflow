#!/usr/bin/env bash
# Translate Podman-specific CLI flags to Docker equivalents.
# AWX hardcodes "podman" and passes Podman-only flags that Docker rejects.
#
# Translations applied:
#   --network slirp4netns:*  → --network bridge  (Podman rootless networking)
#   --network=slirp4netns:*  → --network=bridge
#   --authfile /path         → --config /tmpdir  (Docker uses a dir with config.json)
#   --annotation key=val     → (dropped, Podman-only OCI annotation)
#   --userns=*               → (dropped, Podman user-namespace flag)

subcmd_args=()   # flags/values after the subcommand
global_args=()   # Docker global flags (before the subcommand)
subcommand=""    # the subcommand itself (run, pull, images, ...)
authfile_tmpdir=""

argv=("$@")
count=$#
i=0

while [ $i -lt $count ]; do
    arg="${argv[$i]}"
    case "$arg" in
        --network)
            i=$((i + 1))
            net="${argv[$i]}"
            if [[ "$net" == slirp4netns* ]]; then
                subcmd_args+=(--network bridge)
            else
                subcmd_args+=(--network "$net")
            fi
            ;;
        --network=slirp4netns*)
            subcmd_args+=(--network=bridge)
            ;;
        --authfile)
            # Podman: --authfile /path/to/auth.json
            # Docker: --config /dir/  (dir must contain config.json)
            i=$((i + 1))
            authfile="${argv[$i]}"
            authfile_tmpdir=$(mktemp -d)
            cp "$authfile" "${authfile_tmpdir}/config.json"
            global_args+=(--config "$authfile_tmpdir")
            ;;
        --authfile=*)
            authfile="${arg#--authfile=}"
            authfile_tmpdir=$(mktemp -d)
            cp "$authfile" "${authfile_tmpdir}/config.json"
            global_args+=(--config "$authfile_tmpdir")
            ;;
        --userns=*)
            # Podman user-namespace — no Docker equivalent, drop it
            ;;
        --annotation)
            # Podman OCI annotation — skip key=value pair
            i=$((i + 1))
            ;;
        --annotation=*)
            # Inline form — drop
            ;;
        *)
            # First non-flag arg is the subcommand; everything after goes to subcmd_args
            if [[ -z "$subcommand" && "$arg" != -* ]]; then
                subcommand="$arg"
            else
                subcmd_args+=("$arg")
            fi
            ;;
    esac
    i=$((i + 1))
done

# Compose final args: global flags, subcommand, subcommand flags
final_args=("${global_args[@]}")
[[ -n "$subcommand" ]] && final_args+=("$subcommand")
final_args+=("${subcmd_args[@]}")

if [[ -n "$authfile_tmpdir" ]]; then
    /usr/local/bin/docker "${final_args[@]}"
    exit_code=$?
    rm -rf "$authfile_tmpdir"
    exit $exit_code
else
    exec /usr/local/bin/docker "${final_args[@]}"
fi
