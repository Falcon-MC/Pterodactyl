#!/usr/bin/env bash
set -euo pipefail

egg=$1
tag=$2
case "$egg" in
  egg-falcon.json)
    marker=$(jq -er '.config.startup | fromjson | .done' "$egg")
    version_file=.falcon-version
    ;;
  egg-falcon-broadcaster.json)
    # An empty server directory has no Microsoft credentials.
    marker='Sign in to the broadcasting account at '
    version_file=.broadcaster-version
    ;;
  *) echo "Unknown egg: $egg" >&2; exit 1 ;;
esac

work=$(mktemp -d)
container=
cleanup() {
  if [[ -n "$container" ]]; then
    docker rm -f "$container" >/dev/null 2>&1 || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

mkdir "$work/server"
jq -er '.scripts.installation.script' "$egg" > "$work/install.sh"
bash -n "$work/install.sh"
installer=$(jq -er '.scripts.installation.container' "$egg")
entrypoint=$(jq -er '.scripts.installation.entrypoint' "$egg")
startup=$(jq -er '.startup' "$egg")
images=$(jq -er '.docker_images | values[]' "$egg")

timeout 5m docker run --rm --platform linux/amd64 \
  --mount "type=bind,src=$work/server,dst=/mnt/server" \
  --mount "type=bind,src=$work/install.sh,dst=/install.sh,readonly" \
  --env "RELEASE_VERSION=$tag" --entrypoint "$entrypoint" "$installer" /install.sh \
  | tee "$work/install.log"

grep -Fx 'Checksum verified' "$work/install.log" >/dev/null
[[ "$(cat "$work/server/$version_file")" == "$tag" ]]

while IFS= read -r image; do
  echo "Testing $egg $tag on $image"
  # Each runtime gets a fresh copy of the installed files and starts as the image user.
  runtime=$(mktemp -d "$work/runtime.XXXXXX")
  cp -a "$work/server/." "$runtime/"
  chmod -R a+rwX "$runtime"
  container=$(docker run -dit --platform linux/amd64 \
    --mount "type=bind,src=$runtime,dst=/home/container" \
    --workdir /home/container --entrypoint /bin/bash "$image" -c "exec $startup")

  ready=false
  for ((attempt=0; attempt<90; attempt++)); do
    logs=$(docker logs "$container" 2>&1)
    if [[ "$logs" == *"$marker"* ]]; then
      ready=true
      break
    fi
    [[ "$(docker inspect -f '{{.State.Running}}' "$container")" == true ]] || break
    sleep 2
  done
  if [[ "$ready" != true ]]; then
    echo "$egg $tag did not reach its startup checkpoint on $image" >&2
    docker logs "$container" 2>&1 | sed '/Sign in to the broadcasting account/d' >&2
    exit 1
  fi
  docker rm -f "$container" >/dev/null
  container=
done <<< "$images"
